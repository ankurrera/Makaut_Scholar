import os
import re
import urllib.request
import subprocess
import difflib
import requests
import json
import fitz  # PyMuPDF
from pathlib import Path

# --- CONFIG ---
BASE_DIR = Path("/Users/ankurbag/Documents/GitHub/Makaut_Scholar/PYQ questions/Departments")
SUPABASE_URL = "https://nikvdsulxvinkvxstxol.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5pa3Zkc3VseHZpbmt2eHN0eG9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyNjI0NzAsImV4cCI6MjA4NjgzODQ3MH0.QCsZ9SwePb5xhnnGIyPJ8ZksBuKJ8I8pYMtydkJuNc0"

HEADERS_SB = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}"
}

DEPARTMENTS = ["ECE", "IT", "ME", "EE", "CE"]
URL_MAP = {
    "ECE": "https://www.makaut.com/btech-ec-question-papers.html",
    "IT": "https://www.makaut.com/btech-it-question-papers.html",
    "ME": "https://www.makaut.com/btech-me-question-papers.html",
    "EE": "https://www.makaut.com/btech-ee-question-papers.html",
    "CE": "https://www.makaut.com/btech-ce-question-papers.html",
}

# Mapping Makaut dept codes to standard DEPT
MAKAUT_CODES = {
    "EC": "ECE", "ECE": "ECE", "IT": "IT", 
    "ME": "ME", "EE": "EE", "CE": "CE", "ALL": "ALL"
}

def get_syllabus_subjects():
    print("Fetching Syllabus Data from Supabase...")
    url = f"{SUPABASE_URL}/rest/v1/syllabus?select=department,semester,subject&limit=10000"
    resp = requests.get(url, headers=HEADERS_SB)
    if resp.status_code != 200:
        print(f"Error fetching syllabus: {resp.status_code}")
        return {}
    
    data = resp.json()
    # Format: { "DEPT": { "1": ["Math 1", "Physics"], "2": [...] } }
    syll_map = {}
    for item in data:
        dept = item.get('department')
        sem = item.get('semester')
        subj = item.get('subject')
        
        if not dept or not sem or not subj: continue
        dept = dept.upper()
        sem = str(sem)
        
        if dept not in syll_map: syll_map[dept] = {}
        if sem not in syll_map[dept]: syll_map[dept][sem] = set()
        
        syll_map[dept][sem].add(subj.strip())
    
    # Precompute lowercase variants for matching
    syll_match_map = {}
    for d, sems in syll_map.items():
        syll_match_map[d] = {}
        for sem, subjs in sems.items():
            syll_match_map[d][sem] = {s.lower().strip(): s for s in subjs}
    
    return syll_match_map

def clean_subject_name(text):
    """Clean scraped link text into a decent subject name guess."""
    # Clean standard Makaut URL structures
    text = text.upper()
    
    # If it's something like "BTECH-EC-1-SEM-MATHEMATICS-1-BSM101-2023"
    sub_name = re.sub(r'^BTECH-[A-Z]+-[1-8]-SEM-', '', text)
    sub_name = re.sub(r'^BTECH-[1-8]-SEM-', '', sub_name) # generic
    
    # Strip year and codes at the end
    sub_name = re.sub(r'-20[0-9]{2}$', '', sub_name)
    sub_name = re.sub(r'-[0-9]{4}$', '', sub_name)
    sub_name = re.sub(r'-[A-Z0-9]{4,}$', '', sub_name) # Strip trailing course codes like BS-M-102
    
    sub_name = sub_name.replace('-', ' ').strip().title()
    return sub_name

def fuzzy_match(query, candidates, cutoff=0.85):
    """Fuzzy match a query against a dictionary of {lower_cleaned: original_name}."""
    if not candidates: return None, 0
    
    query_clean = query.lower().strip()
    
    # Exact match
    if query_clean in candidates:
        return candidates[query_clean], 1.0
        
    # Difflib match
    matches = difflib.get_close_matches(query_clean, list(candidates.keys()), n=1, cutoff=cutoff)
    if matches:
        best_clean = matches[0]
        ratio = difflib.SequenceMatcher(None, query_clean, best_clean).ratio()
        return candidates[best_clean], ratio
        
    return None, 0
    
def extract_subject_from_pdf(content):
    """Perform OCR/text extraction on PDF content in memory."""
    try:
        doc = fitz.open(stream=content, filetype="pdf")
        if doc.page_count == 0: return None
        
        page = doc[0]
        text = page.get_text("text")
        
        # 1. Look for "Subject :"
        m = re.search(r'Subject\s*:\s*([^\n]+)', text, re.I)
        if m: return m.group(1).strip()
        
        # 2. Look for "Name of the Paper:"
        m = re.search(r'Name of the Paper\s*:\s*([^\n]+)', text, re.I)
        if m: return m.group(1).strip()

        # 3. Fallback to heuristic
        lines = text.split('\n')[:15]
        filtered = []
        for l in lines:
            l = l.strip()
            if not l or len(l) < 5: continue
            if any(x in l.upper() for x in ["MAKAUT", "UNIVERSITY", "TIME", "MARKS", "B.TECH", "SEMESTER", "ROLL", "MAXIMUM"]): continue
            if re.match(r'^[0-9/\s-]+$', l): continue
            filtered.append(l)
        
        if filtered: return filtered[0]
        
    except Exception as e:
        return None
    return None

def get_html(url):
    print(f"Scraping {url}...")
    cmd = ['curl', '-sL', '--resolve', 'www.makaut.com:443:104.21.14.240', url]
    res = subprocess.run(cmd, capture_output=True, text=True)
    return res.stdout

def download_and_verify(pdf_url, target_dept, target_sem, year, scraped_name, syll_match_map):
    """Downloads PDF into memory, attempts OCR verification if needed, and saves to correct path."""
    syllabus_subs = syll_match_map.get(target_dept, {}).get(target_sem, {})
    
    # Step 1: Initial Fuzzy Match on scraped name
    matched_sub, ratio = fuzzy_match(scraped_name, syllabus_subs, cutoff=0.85)
    
    if matched_sub:
        # High confidence match from link alone, no OCR strictly required to determine name,
        # but we still need to download it.
        verified_name = matched_sub
        print(f"  [{target_sem}] Mapped link '{scraped_name}' -> '{verified_name}' (Ratio: {ratio:.2f})")
    else:
        verified_name = None
        print(f"  [{target_sem}] Low match for '{scraped_name}' (Ratio: {ratio:.2f}). Starting OCR verification...")
        
    # Download file content into memory to save it (and verify if needed)
    try:
        req = urllib.request.Request(pdf_url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=15) as response:
            pdf_content = response.read()
    except Exception as e:
        print(f"  Failed to download {pdf_url}: {e}")
        return False
        
    # Step 2: OCR Fallback if initial match was poor
    if not verified_name:
        ocr_text = extract_subject_from_pdf(pdf_content)
        if ocr_text:
            ocr_clean = re.sub(r'\s*\([A-Z0-9-]+\)$', '', ocr_text).strip() # clean common trailing codes
            matched_ocr, ocr_ratio = fuzzy_match(ocr_clean, syllabus_subs, cutoff=0.75) # looser cutoff for OCR
            
            if matched_ocr:
                verified_name = matched_ocr
                print(f"  OCR SUCCESS: '{ocr_clean}' -> '{verified_name}' (Ratio: {ocr_ratio:.2f})")
            else:
                print(f"  OCR FAILED to match: '{ocr_clean}' against syllabus.")
        else:
            print("  OCR FAILED to extract any meaningful text.")
            
    # Step 3: Final verification check and saving
    if not verified_name:
        print(f"  DISCARDING {pdf_url}: Could not confidently map to a syllabus subject.")
        return False
        
    # Generate final save path
    target_filename = f"{verified_name.replace(' ', '_')}-{year}.pdf"
    target_path = BASE_DIR / target_dept / f"SEM{target_sem}" / verified_name / target_filename
    
    if target_path.exists():
        # print(f"  File already exists: {target_filename}")
        return True
        
    target_path.parent.mkdir(parents=True, exist_ok=True)
    with open(target_path, 'wb') as f:
        f.write(pdf_content)
    
    print(f"  Saved: {target_dept}/SEM{target_sem}/{verified_name}/{target_filename}")
    return True

def process_department(dept, url, syll_match_map):
    print(f"\n{'='*50}\nProcessing Department: {dept}\n{'='*50}")
    html = get_html(url)
    
    # We also want to scrape the main page for common first year links
    html_root = get_html("https://www.makaut.com/")
    combined_html = html + html_root
    
    links = set(re.findall(r'href="(https://www.makaut.com/papers/[^"]+)"', combined_html, re.IGNORECASE))
    processed_urls = set()
    
    for link in links:
        if link in processed_urls: continue
        processed_urls.add(link)
        
        m = re.search(r'btech-(?:([a-z]+)-)?([1-8])-sem-([^"]+?)(?:-(20\d\d))?\.html', link, re.IGNORECASE)
        if not m: continue
            
        link_dept_code = m.group(1).upper() if m.group(1) else "ALL"
        sem = m.group(2)
        slug = m.group(3)
        year = m.group(4) or "Unknown"
        
        mapped_dept = MAKAUT_CODES.get(link_dept_code)
        
        is_applicable = False
        if mapped_dept == dept:
            is_applicable = True
        elif mapped_dept == "ALL" and sem in ["1", "2"]:
            is_applicable = True
        elif not m.group(1):
            is_applicable = True
            
        if not is_applicable: continue
            
        pdf_url = link.replace('.html', '.pdf')
        scraped_name = clean_subject_name(slug.replace('-', ' '))
        
        if len(scraped_name) < 3 or 'Paper' in scraped_name: continue
        
        download_and_verify(pdf_url, dept, sem, year, scraped_name, syll_match_map)


def main():
    syll_match_map = get_syllabus_subjects()
    if not syll_match_map:
        print("Required syllabus data could not be fetched. Exiting.")
        return
        
    for dept in DEPARTMENTS:
        url = URL_MAP.get(dept)
        if url:
            process_department(dept, url, syll_match_map)
            
if __name__ == "__main__":
    main()
