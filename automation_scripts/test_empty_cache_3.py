import re
import subprocess
import difflib

dept = "CSE"
url_dept = "cse"
url = f"https://www.makaut.com/btech-{url_dept}-question-papers.html"
cmd = ['curl', '-sL', '--resolve', 'www.makaut.com:443:104.21.14.240', url]
res = subprocess.run(cmd, capture_output=True, text=True)
html = res.stdout

# Pattern now matches BOTH "btech-cse-1-sem" AND "btech-1-sem"
# (we use an optional department string inside the regex)
pattern = rf'href="(https://www.makaut.com/papers/btech-(?:{url_dept}-)?(\d)-sem-[^"]+)">([^<]+)</a>'
matches = re.findall(pattern, html, re.IGNORECASE)

dept_cache = {str(i): {} for i in range(1, 9)}

for link, sem, text in matches:
    sub_name = text.upper()
    prefix_dept = f"BTECH-{dept.upper()}-{sem}-SEM-"
    prefix_gen = f"BTECH-{sem}-SEM-"
    
    if sub_name.startswith(prefix_dept):
        sub_name = sub_name[len(prefix_dept):]
    elif sub_name.startswith(prefix_gen):
        sub_name = sub_name[len(prefix_gen):]
    
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

print("Dept Cache 1 matches before merge:", len(dept_cache['1']))
print("Dept Cache 2 matches before merge:", len(dept_cache['2']))

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

print("Merged Cache 1 matches:", len(merge_similar_subjects(dept_cache['1'])))
print("Merged Cache 2 matches:", len(merge_similar_subjects(dept_cache['2'])))
print("Merged Cache 8 matches:", len(merge_similar_subjects(dept_cache['8'])))
