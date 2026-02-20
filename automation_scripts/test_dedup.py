import re
import difflib

html = """
<a href="https://www.makaut.com/papers/btech-cse-8-sem-e-commerce-and-erp-2009.html">E-Commerce And ERP 2009</a>
<a href="https://www.makaut.com/papers/btech-cse-8-sem-e-commerce-2009.html">E-Commerce 2009</a>
"""
pattern = r'href="(https://www.makaut.com/papers/btech-cse-(\d)-sem-[^"]+)">([^<]+)</a>'
matches = re.findall(pattern, html, re.IGNORECASE)

dept_cache = {str(i): {} for i in range(1, 9)}

for link, sem, text in matches:
    sub_name = text.upper()
    prefix = f"BTECH-CSE-{sem}-SEM-"
    if sub_name.startswith(prefix):
        sub_name = sub_name[len(prefix):]
    
    sub_name = re.sub(r'-20[0-9]{2}$', '', sub_name)
    sub_name = sub_name.replace('-', ' ').strip().title()
    
    if sub_name not in dept_cache[sem]:
        dept_cache[sem][sub_name] = []
    dept_cache[sem][sub_name].append(link)

print("Before merge:", dept_cache['8'])

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

print("After merge:", merge_similar_subjects(dept_cache['8']))
