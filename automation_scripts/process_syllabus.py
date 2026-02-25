import json
from collections import defaultdict

JSON_PATH = "/Users/ankurbag/Documents/GitHub/Makaut_Scholar/automation_scripts/syllabus_data.json"

def main():
    try:
        with open(JSON_PATH, 'r') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error reading JSON: {e}")
        return

    code_to_subjects = defaultdict(list)

    # Filtering keywords
    FILTER_KEYWORDS = ["LAB", "LABORATORY", "[LAB]"]

    for row in data:
        subject_name = row.get('subject', 'Unknown')
        
        # Skip laboratory subjects
        if any(kw in subject_name.upper() for kw in FILTER_KEYWORDS):
            continue

        code = row.get('paper_code')
        if not code:
            continue
        
        # Normalize code (uppercase, trim)
        normalized_code = code.strip().upper()
        
        code_to_subjects[normalized_code].append({
            'name': row.get('subject', 'Unknown'),
            'dept': row.get('department', 'Unknown'),
            'sem': row.get('semester', 'Unknown')
        })

    # Find duplicates (code mapping to multiple different entities)
    # A "duplicate" here means same code used for different subjects/depts/sems
    print(f"{'Paper Code':<15} | {'Subject Name':<45} | {'Dept':<6} | {'Sem'}")
    print("-" * 80)
    
    unique_codes_sorted = sorted(code_to_subjects.keys())
    
    has_duplicates = False
    for code in unique_codes_sorted:
        subjects = code_to_subjects[code]
        if len(subjects) > 1:
            has_duplicates = True
            for s in subjects:
                print(f"{code:<15} | {s['name'][:45]:<45} | {s['dept']:<6} | {s['sem']}")
            print("-" * 80)

    if not has_duplicates:
        print("No duplicate paper codes found.")

if __name__ == "__main__":
    main()
