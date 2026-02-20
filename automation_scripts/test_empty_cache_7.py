import subprocess
import re

url = "https://www.makaut.com/btech-1-year-question-papers.html"
cmd = ['curl', '-sL', '--resolve', 'www.makaut.com:443:104.21.14.240', url]
res = subprocess.run(cmd, capture_output=True, text=True)
html = res.stdout
print("First year size:", len(html))

# Looking for links like btech-1-sem-physics...
pattern = r'href="(https://www.makaut.com/papers/btech-(\d)-sem-[^"]+)"'
matches = re.findall(pattern, html, re.IGNORECASE)
print("1st year matches found:", len(matches))
for m in matches[:10]:
    print(m)
    
