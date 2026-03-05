import sys
sys.path.append('.')
from scraper.makaut_scraper import fetch_from_url, parse_notices, BASE_URL

html = fetch_from_url('https://www.makautexam.net/')
notices = parse_notices(html, BASE_URL)
for n in notices:
    print("FOUND:", n)
