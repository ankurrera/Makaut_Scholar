import re
import difflib
import subprocess

dept_cache = {str(i): {} for i in range(1, 9)}

# --- SCRAPE SEM 3-8 FROM DEPT ---
dept = "CSE"
url_dept = "cse"
url = f"https://www.makaut.com/btech-{url_dept}-question-papers.html"
cmd = ['curl', '-sL', '--resolve', 'www.makaut.com:443:104.21.14.240', url]
res = subprocess.run(cmd, capture_output=True, text=True)
html_dept = res.stdout

pattern_dept = rf'href="(https://www.makaut.com/papers/btech-(?:{url_dept}-)?(\d)-sem-[^"]+)">([^<]+)</a>'
matches_dept = re.findall(pattern_dept, html_dept, re.IGNORECASE)

# --- SCRAPE SEM 1-2 FROM ROOT ---
url_root = "https://www.makaut.com/"
cmd_root = ['curl', '-sL', '--resolve', 'www.makaut.com:443:104.21.14.240', url_root]
res_root = subprocess.run(cmd_root, capture_output=True, text=True)
html_root = res_root.stdout

# The root page has raw BTECH-[ALL-]?(\d)-SEM links scattered
# Note that we use a simple regex matching `href="..."`
links_root = set(re.findall(r'href="(https://www.makaut.com/papers/[^"]+)"', html_root, re.IGNORECASE))
matches_root = []
for link in links_root:
    m = re.search(r'btech-(?:all-)?([12])-sem-([^"]+?)(?:-20\d\d)?\.html', link, re.IGNORECASE)
    if m:
        sem = m.group(1)
        # raw unformatted slug
        slug = m.group(2)
        # Fake the "Text" field by converting slug to Title Case
        text = slug.replace('-', ' ').title()
        matches_root.append((link, sem, text))
        
# Combine
all_matches = set(matches_dept + matches_root)

for link, sem, text in all_matches:
    sub_name = text.upper()
    prefix_dept = f"BTECH-{dept.upper()}-{sem}-SEM-"
    prefix_gen = f"BTECH-{sem}-SEM-"
    prefix_all = f"BTECH-ALL-{sem}-SEM-"
    
    if sub_name.startswith(prefix_dept):
        sub_name = sub_name[len(prefix_dept):]
    elif sub_name.startswith(prefix_gen):
        sub_name = sub_name[len(prefix_gen):]
    elif sub_name.startswith(prefix_all):
        sub_name = sub_name[len(prefix_all):]
        
    sub_name = re.sub(r'-20[0-9]{2}$', '', sub_name)
    sub_name = re.sub(r'-V\d$', '', sub_name)
    sub_name = re.sub(r'-S\d$', '', sub_name)
    sub_name = re.sub(r'-OLD$', '', sub_name)
    sub_name = re.sub(r'-O$', '', sub_name)
    sub_name = re.sub(r'-[A-Z]{2,4}-?[0-9]{3}[A-Z]?$', '', sub_name)
    sub_name = re.sub(r'-(PCC|PEC|HSMC|ESC|PC|PE|BS|BSC)-?[A-Z]*[0-9]*.*$', '', sub_name)
    
    sub_name = sub_name.replace('-', ' ').strip().title()
    
    if len(sub_name) > 2 and 'Paper' not in sub_name:
        if sub_name not in dept_cache[sem]:
            dept_cache[sem][sub_name] = []
        dept_cache[sem][sub_name].append(link)

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

merged_cache = {sem: merge_similar_subjects(dept_cache[sem]) for sem in dept_cache}

print("Sem 1 items:", len(merged_cache['1']))
print(list(merged_cache['1'].keys())[:5])
print("Sem 2 items:", len(merged_cache['2']))
print(list(merged_cache['2'].keys())[:5])
