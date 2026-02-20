import subprocess
import re

url = "https://www.makaut.com/"
cmd = ['curl', '-sL', '--resolve', 'www.makaut.com:443:104.21.14.240', url]
res = subprocess.run(cmd, capture_output=True, text=True)
html = res.stdout

links = set(re.findall(r'href="(https://www.makaut.com/[^"]+)"', html, re.IGNORECASE))
for l in links:
    if 'btech' in l.lower() and ('ear' in l.lower() or 'sem' in l.lower() or '1' in l.lower() or 'first' in l.lower()):
        print(l)

