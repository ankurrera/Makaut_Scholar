import subprocess
import re

dept = "CSE"
url_dept = "cse"
url = f"https://www.makaut.com/btech-{url_dept}-question-papers.html"
cmd = ['curl', '-sL', '--resolve', 'www.makaut.com:443:104.21.14.240', url]
res = subprocess.run(cmd, capture_output=True, text=True)
html = res.stdout

# The reason we aren't finding Sem 1 is probably because Makaut doesn't HAVE Sem 1 papers 
# on the BTech CSE page AT ALL! Let's check:
sem1_words = re.findall(r'1-sem', html, re.IGNORECASE)
print(f"Occurrences of '1-sem' on {url_dept} page:", len(sem1_words))
