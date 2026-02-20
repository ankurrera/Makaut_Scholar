import re
import subprocess

dept = "CSE"
url_dept = "cse"
url = f"https://www.makaut.com/btech-{url_dept}-question-papers.html"
cmd = ['curl', '-sL', '--resolve', 'www.makaut.com:443:104.21.14.240', url]
res = subprocess.run(cmd, capture_output=True, text=True)
html = res.stdout

# The pattern needs to match: href="https://www.makaut.com/papers/btech-1-sem-physics-ph-101-2009.html"
# Or href="https://www.makaut.com/papers/btech-cse-3-sem-..."
pattern = r'href="(https://www.makaut.com/papers/btech-(?:[a-z]+-)?(\d)-sem-[^"]+)">([^<]+)</a>'
matches = re.findall(pattern, html, re.IGNORECASE)

print("Total matches:", len(matches))
sem1_matches = [m for m in matches if m[1] == '1']
print("Sem 1 matches:", len(sem1_matches))
for m in sem1_matches[:5]:
    print(m)

