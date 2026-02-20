import subprocess
import re
import difflib

url_root_page = "https://www.makaut.com/"
cmd_root = ['curl', '-sL', '--resolve', 'www.makaut.com:443:104.21.14.240', url_root_page]
res_root = subprocess.run(cmd_root, capture_output=True, text=True)
html_root = res_root.stdout

links_root = set(re.findall(r'href="(https://www.makaut.com/papers/[^"]+)"', html_root, re.IGNORECASE))
matches_root = []
for link in links_root:
    m = re.search(r'btech-(?:all-)?([12])-sem-([^"]+?)(?:-20\d\d)?\.html', link, re.IGNORECASE)
    if m:
        sem = m.group(1)
        slug = m.group(2)
        text = slug.replace('-', ' ').title()
        matches_root.append((link, sem, text))

print(f"Sem 1 raw extracts: {len([m for m in matches_root if m[1] == '1'])}")
print(f"Sem 2 raw extracts: {len([m for m in matches_root if m[1] == '2'])}")
if len([m for m in matches_root if m[1] == '1']) > 0:
    print([m for m in matches_root if m[1] == '1'][:5])
