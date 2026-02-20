import urllib.request
import re
import json

departments = ['cse', 'it', 'ec', 'ee', 'me', 'ce']
all_subjects = {}

for dept in departments:
    try:
        url = f"https://www.makaut.com/btech-{dept}-question-papers.html"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        html = urllib.request.urlopen(req).read().decode('utf-8')
        
        dept_subs = {str(i): set() for i in range(1, 9)}
        
        pattern = rf'href="https://www.makaut.com/papers/btech-{dept}-(\d)-sem-[^"]+">([^<]+)</a>'
        matches = re.findall(pattern, html, re.IGNORECASE)
        
        for sem, text in matches:
            text = text.upper()
            prefix = f"BTECH-{dept.upper()}-{sem}-SEM-"
            if text.startswith(prefix):
                sub_name = text[len(prefix):]
            else:
                sub_name = text
            
            # aggressive cleanup
            sub_name = re.sub(r'-20[0-9]{2}$', '', sub_name)
            sub_name = re.sub(r'-V\d$', '', sub_name)
            sub_name = re.sub(r'-S\d$', '', sub_name)
            sub_name = re.sub(r'-OLD$', '', sub_name)
            sub_name = re.sub(r'-O$', '', sub_name)
            sub_name = re.sub(r'-[A-Z]{2,4}-?[0-9]{3}[A-Z]?$', '', sub_name)
            sub_name = re.sub(r'-PCC-?[A-Z]*[0-9]*.*$', '', sub_name)
            sub_name = re.sub(r'-PEC-?[A-Z]*[0-9]*.*$', '', sub_name)
            sub_name = re.sub(r'-HSMC-?[A-Z]*[0-9]*.*$', '', sub_name)
            sub_name = re.sub(r'-ESC-?[A-Z]*[0-9]*.*$', '', sub_name)
            sub_name = re.sub(r'-PC-?[A-Z]*[0-9]*.*$', '', sub_name)
            sub_name = re.sub(r'-PE-?[A-Z]*[0-9]*.*$', '', sub_name)
            sub_name = re.sub(r'-BS-?[A-Z]*[0-9]*.*$', '', sub_name)
            sub_name = re.sub(r'-BSC-?[A-Z]*[0-9]*.*$', '', sub_name)
            
            sub_name = sub_name.replace('-', ' ').strip().title()
            
            if len(sub_name) > 2 and 'Paper' not in sub_name:
                dept_subs[sem].add(sub_name)
                
        key = 'ECE' if dept == 'ec' else dept.upper()
        
        all_subjects[key] = {sem: sorted(list(subs)) for sem, subs in dept_subs.items() if subs}
        print(f"Extracted {key}")
        
    except Exception as e:
        print(f"Error {dept.upper()}: {e}")

with open('scraped_subjects.json', 'w') as f:
    json.dump(all_subjects, f, indent=4)
print("Saved to scraped_subjects.json")
