import re
import subprocess

# Let's try to pull btech-1-year or btech-first-year
url = "https://www.makaut.com/btech-first-year-question-papers.html"
cmd = ['curl', '-sL', '--resolve', 'www.makaut.com:443:104.21.14.240', url]
res = subprocess.run(cmd, capture_output=True, text=True)
html = res.stdout

print(html[:1500])
