import os
import re
import urllib.request
import subprocess
import difflib
from pathlib import Path

# --- CONFIG ---
BASE_DIR = Path("/Users/ankurbag/Documents/GitHub/Makaut_Scholar/PYQ questions/Departments")
DEPARTMENTS = ["IT", "ECE", "EE", "ME", "CE"]
ECE_ONLY = ["ECE"]

def clean_subject_name(text, sem, dept=None):
    text = text.upper()
    prefix_dept = f"BTECH-{dept}-{sem}-SEM-" if dept else None
    prefix_gen = f"BTECH-{sem}-SEM-"
    prefix_all = f"BTECH-ALL-{sem}-SEM-"
    
    if prefix_dept and text.startswith(prefix_dept):
        sub_name = text[len(prefix_dept):]
    elif text.startswith(prefix_gen):
        sub_name = text[len(prefix_gen):]
    elif text.startswith(prefix_all):
        sub_name = text[len(prefix_all):]
    else:
        # Try a more generic match if it's BTECH-CS-201 style
        sub_name = re.sub(rf'^BTECH-(?:[A-Z]+-)?{sem}-SEM-', '', text)
        if sub_name == text: # No change
             sub_name = re.sub(rf'^BTECH-[A-Z]+-[0-9]+-', '', text)

    # Cleanup regex from extract.py
    sub_name = re.sub(r'-20[0-9]{2}$', '', sub_name)
    sub_name = re.sub(r'-V\d$', '', sub_name)
    sub_name = re.sub(r'-S\d$', '', sub_name)
    sub_name = re.sub(r'-OLD$', '', sub_name)
    sub_name = re.sub(r'-O$', '', sub_name)
    sub_name = re.sub(r'-[A-Z]{2,4}-?[0-9]{3}[A-Z]?$', '', sub_name)
    sub_name = re.sub(r'-(PCC|PEC|HSMC|ESC|PC|PE|BS|BSC)-?[A-Z]*[0-9]*.*$', '', sub_name)
    
    sub_name = sub_name.replace('-', ' ').strip().title()
    return sub_name

def merge_similar_subjects(subjects_dict):
    merged = {}
    keys = sorted(subjects_dict.keys(), key=len, reverse=True)
    for key in keys:
        found_merge = False
        for m_key in list(merged.keys()):
            ratio = difflib.SequenceMatcher(None, key.lower(), m_key.lower()).ratio()
            is_substring = (key.lower() in m_key.lower()) and len(key) >= 5
            
            if ratio > 0.85 or is_substring:
                merged[m_key].extend(subjects_dict[key])
                merged[m_key] = list(set(merged[m_key]))
                found_merge = True
                break
        if not found_merge:
            merged[key] = list(set(subjects_dict[key]))
    return merged

def download_file(url, target_path):
    if target_path.exists():
        return True
    
    target_path.parent.mkdir(parents=True, exist_ok=True)
    print(f"Downloading {url} to {target_path}")
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response, open(target_path, 'wb') as out_file:
            out_file.write(response.read())
        return True
    except Exception as e:
        print(f"Error downloading {url}: {e}")
        return False

def get_html(url):
    cmd = ['curl', '-sL', '--resolve', 'www.makaut.com:443:104.21.14.240', url]
    res = subprocess.run(cmd, capture_output=True, text=True)
    return res.stdout

def scrape_sem_1_2():
    print("Scraping Semester 1 & 2 from root...")
    html = get_html("https://www.makaut.com/")
    links = set(re.findall(r'href="(https://www.makaut.com/papers/[^"]+)"', html, re.IGNORECASE))
    
    results = {"1": {}, "2": {}}
    for link in links:
        m = re.search(r'btech-(?:all-)?([12])-sem-([^"]+?)(?:-(20\d\d))?\.html', link, re.IGNORECASE)
        if m:
            sem = m.group(1)
            slug = m.group(2)
            year = m.group(3) or "Unknown"
            text = slug.replace('-', ' ').title()
            
            sub_name = clean_subject_name(text, sem)
            if len(sub_name) < 3 or 'Paper' in sub_name: continue
            
            if sub_name not in results[sem]: results[sem][sub_name] = []
            pdf_url = link.replace('.html', '.pdf')
            results[sem][sub_name].append((pdf_url, year))
    
    # Merge similar
    for sem in ["1", "2"]:
        # We need to adapt merge_similar_subjects because it stores only URLs
        raw_subs = results[sem]
        merged_names = merge_similar_subjects({name: [i for i, _ in items] for name, items in raw_subs.items()})
        
        final_merged = {}
        for m_name, urls in merged_names.items():
            final_merged[m_name] = []
            for url in urls:
                # Find original year
                orig_year = "Unknown"
                for name, items in raw_subs.items():
                    for u, y in items:
                        if u == url:
                            orig_year = y
                            break
                    if orig_year != "Unknown": break
                final_merged[m_name].append((url, orig_year))
        results[sem] = final_merged
        
    return results

def scrape_ece_sem_8():
    print("Scraping ECE Semester 8...")
    url = "https://www.makaut.com/btech-ec-question-papers.html"
    html = get_html(url)
    
    # Pattern for dept specific
    pattern = r'href="(https://www.makaut.com/papers/btech-(?:ec-|ece-)?(8)-sem-[^"]+)">([^<]+)</a>'
    matches = re.findall(pattern, html, re.IGNORECASE)
    
    results = {}
    for link, sem, text in matches:
        # Extract year from link if possible
        year_match = re.search(r'-20(\d\d)\.html', link)
        year = f"20{year_match.group(1)}" if year_match else "Unknown"
        
        sub_name = clean_subject_name(text, sem, dept="ECE")
        if len(sub_name) < 3 or 'Paper' in sub_name: continue
        
        if sub_name not in results: results[sub_name] = []
        pdf_url = link.replace('.html', '.pdf')
        results[sub_name].append((pdf_url, year))
        
    # Merge similar
    merged_names = merge_similar_subjects({name: [i for i, _ in items] for name, items in results.items()})
    final_merged = {}
    for m_name, urls in merged_names.items():
        final_merged[m_name] = []
        for url in urls:
            orig_year = "Unknown"
            for name, items in results.items():
                for u, y in items:
                    if u == url:
                        orig_year = y
                        break
                if orig_year != "Unknown": break
            final_merged[m_name].append((url, orig_year))
            
    return final_merged

def main():
    # 1. Sem 1 & 2
    sem12_data = scrape_sem_1_2()
    for sem in ["1", "2"]:
        for sub_name, papers in sem12_data[sem].items():
            for pdf_url, year in papers:
                for dept in DEPARTMENTS:
                    target_filename = f"{sub_name.replace(' ', '_')}-{year}.pdf"
                    target_path = BASE_DIR / dept / f"SEM{sem}" / sub_name / target_filename
                    download_file(pdf_url, target_path)
                    
    # 2. ECE Sem 8
    ece8_data = scrape_ece_sem_8()
    for sub_name, papers in ece8_data.items():
        for pdf_url, year in papers:
            target_filename = f"{sub_name.replace(' ', '_')}-{year}.pdf"
            target_path = BASE_DIR / "ECE" / "SEM8" / sub_name / target_filename
            download_file(pdf_url, target_path)

if __name__ == "__main__":
    main()
