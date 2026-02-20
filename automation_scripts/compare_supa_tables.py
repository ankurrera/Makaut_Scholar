import requests
from collections import defaultdict

SUPABASE_URL = "https://nikvdsulxvinkvxstxol.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5pa3Zkc3VseHZpbmt2eHN0eG9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyNjI0NzAsImV4cCI6MjA4NjgzODQ3MH0.QCsZ9SwePb5xhnnGIyPJ8ZksBuKJ8I8pYMtydkJuNc0"

HEADERS_SB = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
}

def get_data(table, columns):
    url = f"{SUPABASE_URL}/rest/v1/{table}?select={columns}&limit=10000"
    resp = requests.get(url, headers=HEADERS_SB)
    if resp.status_code == 200:
        return resp.json()
    else:
        print(f"Error fetching {table}: {resp.status_code}")
    return []

def main():
    pyqs = get_data("pyq", "department,subject")
    sylls = get_data("syllabus", "department,subject")

    # Clean function to match case-insensitively and remove trailing whitespace
    def clean(s):
        return s.strip().lower() if s else ""

    pyq_set = set()
    pyq_map = {}
    for item in pyqs:
        if not item.get('department'):
            continue
        dept = item['department'].upper()
        subj_clean = clean(item['subject'])
        pyq_set.add((dept, subj_clean))
        # Keep track of original name for display, prefer the first seen
        if (dept, subj_clean) not in pyq_map:
            pyq_map[(dept, subj_clean)] = item['subject']

    syll_set = set()
    for item in sylls:
        if not item.get('department'):
            continue
        syll_set.add((item['department'].upper(), clean(item['subject'])))

    # Find missing subjects (present in PYQ but not in Syllabus)
    missing = pyq_set - syll_set

    # Group by department
    missing_by_dept = defaultdict(list)
    for dept, subj_clean in missing:
        orig_subj = pyq_map[(dept, subj_clean)]
        missing_by_dept[dept].append(orig_subj)

    # Print results
    for dept in sorted(missing_by_dept.keys()):
        print(f"\n--- Department: {dept} ---")
        for subj in sorted(missing_by_dept[dept]):
            print(f"- {subj}")

    print(f"\nTotal unique (department, subject) pairs in PYQ but NOT in Syllabus: {len(missing)}")

if __name__ == "__main__":
    main()
