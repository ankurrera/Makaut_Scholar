import subprocess
import re

dept = "CSE"
url_dept = "cse"
url = f"https://www.makaut.com/btech-{url_dept}-question-papers.html"

# Use python urllib since curl might be failing or caching old in python script
import urllib.request
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
html = urllib.request.urlopen(req).read().decode('utf-8')

pattern = rf'href="(https://www.makaut.com/papers/btech-{url_dept}-(\d)-sem-[^"]+)">([^<]+)</a>'
matches = re.findall(pattern, html, re.IGNORECASE)

print(f"Matches found: {len(matches)}")
if matches:
    print("Sample:", matches[0])
