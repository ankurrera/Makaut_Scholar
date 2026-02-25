import requests
from collections import defaultdict
import re

SUPABASE_URL = "https://nikvdsulxvinkvxstxol.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5pa3Zkc3VseHZpbmt2eHN0eG9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyNjI0NzAsImV4cCI6MjA4NjgzODQ3MH0.QCsZ9SwePb5xhnnGIyPJ8ZksBuKJ8I8pYMtydkJuNc0"

HEADERS = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
}

def fetch_syllabus():
    url = f"{SUPABASE_URL}/rest/v1/syllabus?select=*"
    resp = requests.get(url, headers=HEADERS)
    if resp.status_code == 200:
        return resp.json()
    else:
        print(f"Error: {resp.status_code}")
        return []

def main():
    data = fetch_syllabus()
    if not data:
        return

    # Try to find codes in 'subject' or 'title'
    # Common patterns: CS301, ECE-401, BS-PH101, etc.
    code_pattern = re.compile(r'([A-Z]{2,4}\s*-?\s*[0-9]{3}[A-Z]?)')

    code_to_subjects = defaultdict(list)

    for row in data:
        subject_name = row.get('subject', '')
        title = row.get('title', '')
        dept = row.get('department', '')
        sem = row.get('semester', '')

        # Combine subject and title to find code
        search_text = f"{subject_name} {title}"
        match = code_pattern.search(search_text)
        
        if match:
            code = match.group(1).replace(' ', '').replace('-', '')
            code_to_subjects[code].append({
                'name': subject_name,
                'dept': dept,
                'sem': sem,
                'full_text': search_text
            })
        else:
            # Fallback: maybe the whole name is a code? (unlikely but check)
            pass

    # Find duplicates
    print(f"{'Code':<10} | {'Subject Name':<40} | {'Dept':<5} | {'Sem'}")
    print("-" * 70)
    
    # We want same code, but could be different depts or semesters
    # The user asked: "list me the subject_code with subject's name department and semester wise which has same subject codes."
    
    duplicates_found = False
    for code, subjects in sorted(code_to_subjects.items()):
        if len(subjects) > 1:
            duplicates_found = True
            for s in subjects:
                print(f"{code:<10} | {s['name'][:40]:<40} | {s['dept']:<5} | {s['sem']}")
            print("-" * 70)

    if not duplicates_found:
        print("No duplicate codes found in the parsed data.")

if __name__ == "__main__":
    main()
