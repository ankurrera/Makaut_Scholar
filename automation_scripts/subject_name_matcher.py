import os
import difflib
import requests
from pathlib import Path
from collections import defaultdict

# --- CONFIG ---
SUPABASE_URL = "https://nikvdsulxvinkvxstxol.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5pa3Zkc3VseHZpbmt2eHN0eG9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyNjI0NzAsImV4cCI6MjA4NjgzODQ3MH0.QCsZ9SwePb5xhnnGIyPJ8ZksBuKJ8I8pYMtydkJuNc0"

HEADERS_SB = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
}

BASE_DIR = Path("/Users/ankurbag/Documents/GitHub/Makaut_Scholar/PYQ questions/Departments")

def get_syllabus_subjects():
    print("Fetching syllabus subjects from Supabase...")
    url = f"{SUPABASE_URL}/rest/v1/syllabus?select=department,subject"
    resp = requests.get(url, headers=HEADERS_SB)
    if resp.status_code != 200:
        print(f"Error fetching syllabus: {resp.status_code}")
        return {}
    
    # Map department -> list of subjects
    syll_map = defaultdict(set)
    for item in resp.json():
        dept = item['department'].upper()
        subj = item['subject'].strip()
        syll_map[dept].add(subj)
    return syll_map

def clean_name(name):
    """Clean name for better matching: lower, remove extra spaces, and common codes."""
    import re
    n = name.lower().strip()
    # Remove common subject codes at end: (CS701), Bs Ph 101, etc.
    n = re.sub(r'\s*\(?[a-z]{2,4}-?[0-9]{3}[a-z]?\)?$', '', n)
    n = re.sub(r'\s*[a-z]{2,4}\s*[a-z]{2,4}\s*[0-9]{3}\s*[a-z]?$', '', n)
    return n.replace('-', ' ').replace('_', ' ')

def find_match(folder_name, dept_subjects):
    if not dept_subjects:
        return None, 0
    
    clean_folder = clean_name(folder_name)
    subject_list = list(dept_subjects)
    clean_subjects = {clean_name(s): s for s in subject_list}
    
    # Exact match after cleaning
    if clean_folder in clean_subjects:
        return clean_subjects[clean_folder], 1.0
    
    # Fuzzy match
    matches = difflib.get_close_matches(clean_folder, list(clean_subjects.keys()), n=1, cutoff=0.7)
    if matches:
        best_clean = matches[0]
        # Calculate ratio manually for the clean names
        ratio = difflib.SequenceMatcher(None, clean_folder, best_clean).ratio()
        return clean_subjects[best_clean], ratio
        
    return None, 0

def main():
    syll_map = get_syllabus_subjects()
    
    proposals = [] # (dept, old_name, new_name, ratio)
    unmatched = defaultdict(list)
    
    for dept_path in sorted(BASE_DIR.iterdir()):
        if not dept_path.is_dir(): continue
        dept = dept_path.name.upper()
        
        for sem_path in sorted(dept_path.iterdir()):
            if not sem_path.is_dir() or not sem_path.name.startswith("SEM"): continue
            
            for sub_path in sorted(sem_path.iterdir()):
                if not sub_path.is_dir(): continue
                
                old_name = sub_path.name
                new_name, ratio = find_match(old_name, syll_map.get(dept))
                
                if new_name and ratio >= 0.8:
                    if old_name != new_name:
                        proposals.append((dept, old_name, new_name, ratio))
                else:
                    unmatched[dept].append(old_name)

    # Print Proposals
    print("\n" + "="*50)
    print("PROPOSED RENAMES (Old -> New)")
    print("="*50)
    # Sort by dept and ratio
    proposals.sort(key=lambda x: (x[0], -x[3]))
    for dept, old, new, ratio in proposals:
        print(f"[{dept}] {old}  --->  {new}  ({ratio:.2f})")
        
    # Print Unmatched
    print("\n" + "="*50)
    print("UNMATCHED SUBJECTS (No close syllabus equivalent)")
    print("="*50)
    for dept in sorted(unmatched.keys()):
        print(f"\n--- {dept} ---")
        for sub in sorted(list(set(unmatched[dept]))):
            print(f"- {sub}")

if __name__ == "__main__":
    main()
