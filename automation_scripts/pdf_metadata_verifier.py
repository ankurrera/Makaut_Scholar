import io
import fitz  # PyMuPDF
import requests
import json
import re
from collections import defaultdict

# --- CONFIG ---
SUPABASE_URL = "https://nikvdsulxvinkvxstxol.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5pa3Zkc3VseHZpbmt2eHN0eG9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyNjI0NzAsImV4cCI6MjA4NjgzODQ3MH0.QCsZ9SwePb5xhnnGIyPJ8ZksBuKJ8I8pYMtydkJuNc0"

HEADERS_SB = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
}

def get_data(table, columns):
    url = f"{SUPABASE_URL}/rest/v1/{table}?select={columns}"
    resp = requests.get(url, headers=HEADERS_SB)
    if resp.status_code == 200:
        return resp.json()
    return []

def extract_subject_from_pdf(url):
    """Downloads PDF and attempts to extract subject name."""
    try:
        resp = requests.get(url, stream=False, timeout=15)
        if resp.status_code != 200: return None
        
        doc = fitz.open(stream=resp.content, filetype="pdf")
        if doc.page_count == 0: return None
        
        page = doc[0]
        text = page.get_text("text")
        
        # Heuristics for Makaut Papers
        # 1. Look for "Subject :" or similar
        m = re.search(r'Subject\s*:\s*([^\n]+)', text, re.I)
        if m: return m.group(1).strip()
        
        # 2. Look for "Name of the Paper\s*:\s*([^\n]+)"
        m = re.search(r'Name of the Paper\s*:\s*([^\n]+)', text, re.I)
        if m: return m.group(1).strip()

        # 3. Look for bold or uppercase lines that look like a subject (Fallback)
        # Take first 15 lines, filter out common headers
        lines = text.split('\n')[:15]
        filtered = []
        for l in lines:
            l = l.strip()
            if not l or len(l) < 5: continue
            if any(x in l.upper() for x in ["MAKAUT", "UNIVERSITY", "TIME", "MARKS", "B.TECH", "SEMESTER", "ROLL", "MAXIMUM"]): continue
            # If it's all numbers/codes, skip
            if re.match(r'^[0-9/\s-]+$', l): continue
            filtered.append(l)
        
        if filtered: return filtered[0]
        
        return None
    except Exception as e:
        return None

def main():
    print("Fetching table data...")
    pyqs = get_data("pyq", "department,subject,file_url")
    syllabuses = get_data("syllabus", "department,subject,file_url")

    # Sample: Get one unique subject per department for efficiency OR just run on problematic ones
    # For now, let's collect unique (dept, subject) from PYQ
    unique_pyqs = {}
    for p in pyqs:
        key = (p['department'], p['subject'])
        if key not in unique_pyqs:
            unique_pyqs[key] = p['file_url']

    print(f"Verifying {len(unique_pyqs)} unique PYQ subjects via PDF extraction...")
    
    results = []
    
    for (dept, db_subject), url in list(unique_pyqs.items())[:200]: # Limit to 200 for initial run
        # print(f"Testing {dept} - {db_subject}...")
        extracted = extract_subject_from_pdf(url)
        if extracted:
            # Clean extracted name (remove codes)
            clean_extracted = re.sub(r'\s*\([A-Z0-9-]+\)$', '', extracted).strip()
            results.append({
                "dept": dept,
                "db_subject": db_subject,
                "extracted_subject": clean_extracted,
                "url": url
            })

    # Output results to a file
    with open("ocr_verification_results.json", "w") as f:
        json.dump(results, f, indent=2)
    
    # Print summary of discrepancies
    print("\nDISCREPANCIES FOUND (Database vs PDF Content):")
    for r in results:
        # Simple fuzzy check
        from difflib import SequenceMatcher
        ratio = SequenceMatcher(None, r['db_subject'].lower(), r['extracted_subject'].lower()).ratio()
        if ratio < 0.7:
             print(f"[{r['dept']}] DB: '{r['db_subject']}' | PDF: '{r['extracted_subject']}'")

if __name__ == "__main__":
    main()
