import requests
from bs4 import BeautifulSoup
import os
from supabase import create_client, Client
from datetime import datetime
import re
import json

# --- Supabase Configuration ---
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("⚠️  WARNING: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY missing!")
    print("   Running in DRY-RUN mode — no data will be saved to the database.")
    supabase: Client = None
else:
    print(f"✅ Supabase connected to: {SUPABASE_URL}")
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# --- Target URL ---
MAKAUT_NOTICE_URL = "https://www.makautexam.net/"
FALLBACK_URL = "https://www.makautexam.net/announcement.html"
BASE_URL = "https://www.makautexam.net/"

# Keywords for filtering
STUDENT_KEYWORDS = [
    "result", "exam", "examination", "routine", "schedule",
    "form fill-up", "form fill up", "admit card", "pps", "ppr",
    "academic calendar", "holiday", "commencement",
    "mar", "mooc", "nptel", "coursera", "internship",
    "registration", "enrollment", "enrolment", "syllabus", "postponement",
    "notification", "recruitment", "notice", "circular", "date sheet",
    "special", "back paper", "backlog", "certificate"
]

ADMIN_KEYWORDS = [
    "tender", "quotation", "vendor", "audit",
    "e-tender", "nit ", "rfp", "empanelment"
]


def parse_date(date_str):
    date_str = date_str.strip()
    formats = ["%d-%m-%Y", "%d/%m/%Y", "%Y-%m-%d", "%d.%m.%Y", "%B %d, %Y", "%d %B %Y"]
    for fmt in formats:
        try:
            return datetime.strptime(date_str, fmt).strftime("%Y-%m-%d")
        except ValueError:
            continue
    return datetime.now().strftime("%Y-%m-%d")


def is_relevant(title):
    title_lower = title.lower()
    if any(keyword in title_lower for keyword in ADMIN_KEYWORDS):
        return False, "Ignored"
    for keyword in STUDENT_KEYWORDS:
        if keyword in title_lower:
            if keyword in ["result", "pps", "ppr", "back paper", "backlog"]:
                return True, "Results"
            if keyword in ["routine", "schedule", "exam", "examination", "admit card", "postponement", "date sheet"]:
                return True, "Examinations"
            if keyword in ["holiday", "academic calendar", "commencement"]:
                return True, "Academic Calendar"
            if keyword in ["mar", "mooc", "internship", "nptel", "coursera"]:
                return True, "MAR & MOOCs"
            if keyword in ["registration", "enrollment", "form fill-up", "form fill up"]:
                return True, "Registration"
            return True, "General Student Notice"
    return False, "Uncategorized"


def fetch_from_url(url):
    from playwright.sync_api import sync_playwright
    
    html = ""
    try:
        with sync_playwright() as p:
            print("  [playwright] Launching headless browser...")
            browser = p.chromium.launch()
            page = browser.new_page()
            
            # Navigate to the page and wait for JS to execute (networkidle ensures all ajax requests finish)
            print(f"  [playwright] Navigating to {url}...")
            page.goto(url, wait_until='networkidle', timeout=30000)
            
            html = page.content()
            print(f"✅ Fetched {url} — Size: {len(html)} bytes")
            browser.close()
            return html
            
    except Exception as e:
        print(f"❌ Playwright Error fetching {url}: {e}")
        return None


def parse_notices(html, base_url):
    soup = BeautifulSoup(html, 'html.parser')
    notices = []

    date_pattern = r'(\d{1,2}[-/\.]\d{1,2}[-/\.]\d{4})'
    seen_links = set()

    # Try multiple common selectors for notice containers
    # MAKAUT typically puts notices in table rows or list items
    all_links = soup.find_all('a', href=True)
    print(f"  Found {len(all_links)} anchor tags total.")

    for link in all_links:
        href = link['href']
        text = link.get_text(separator=" ", strip=True)

        if not text or len(text) < 8:
            continue

        # Skip navigation/footer/header noise
        if any(skip in text.lower() for skip in ['home', 'about us', 'contact', 'login', 'gallery', 'sitemap', 'careers', 'tender']):
            continue

        # Resolve full URL
        if href.startswith('http'):
            full_link = href
        elif href.startswith('/'):
            full_link = base_url.rstrip('/') + href
        elif href.startswith('javascript') or href.startswith('#'):
            continue
        else:
            full_link = base_url.rstrip('/') + '/' + href

        if full_link in seen_links:
            continue
        seen_links.add(full_link)

        # Try to extract date
        date_match = re.search(date_pattern, text)
        date_str = ""
        if date_match:
            date_str = date_match.group(1)
            # Remove date from title to keep it clean
            clean_text = text.replace(date_str, "").strip()
            clean_text = re.sub(r'^[-:\s]+|[-:\s]+$', '', clean_text).strip()
            text = clean_text
        else:
            # Check parent element text for date if not in link text
            parent_text = link.parent.get_text(separator=" ", strip=True) if link.parent else ""
            parent_date_match = re.search(date_pattern, parent_text)
            if parent_date_match:
                date_str = parent_date_match.group(1)
            else:
                # Fallback to current date as a last resort
                date_str = datetime.now().strftime("%d-%m-%Y")

        if text:
            notices.append({
                "title": text,
                "link": full_link,
                "date_str": date_str
            })

    return notices


def save_to_supabase(notice_record):
    if not supabase:
        print(f"  [DRY-RUN] {notice_record['category']}: {notice_record['title']}")
        return False
    try:
        supabase.table("official_notifications").insert(notice_record).execute()
        print(f"  ✅ [SAVED] {notice_record['category']}: {notice_record['title']}")
        return True
    except Exception as e:
        err_str = str(e)
        if "duplicate key value" in err_str or "23505" in err_str:
            pass  # Already synced
        else:
            print(f"  ❌ Supabase Error: {err_str}")
        return False


def process(notices):
    from datetime import timedelta
    new_count = 0
    relevant_found = 0
    debug_data = []
    
    # 4 months = ~120 days
    cutoff_date = (datetime.now() - timedelta(days=120)).strftime("%Y-%m-%d")

    for notice in notices:
        relevant, category = is_relevant(notice['title'])
        if not relevant:
            continue

        db_date = parse_date(notice['date_str'])
        
        # Apply the 4-month cutoff filter requested by user
        if db_date < cutoff_date:
            print(f"  [SKIPPED - TOO OLD] {db_date} < {cutoff_date} : {notice['title'][:30]}...")
            continue
            
        relevant_found += 1
        record = {
            "title": notice['title'],
            "link": notice['link'],
            "date_posted": db_date,
            "category": category,
            "is_new": True
        }
        debug_data.append(record)
        if save_to_supabase(record):
            new_count += 1

    print(f"\n📊 Summary:")
    print(f"   Total links parsed:    {len(notices)}")
    print(f"   Relevant notices found: {relevant_found}")
    print(f"   Newly saved to DB:      {new_count}")

    with open("scraped_notices_debug.json", "w") as f:
        json.dump(debug_data, f, indent=4, ensure_ascii=False)
    print(f"   Debug output saved to scraped_notices_debug.json")


if __name__ == "__main__":
    print(f"🚀 Starting MAKAUT Scraper at {datetime.now().isoformat()}")

    # Try primary URL first, then fallback
    html = fetch_from_url(MAKAUT_NOTICE_URL)
    if not html or len(html) < 500:
        print("Primary URL returned too little content, trying fallback...")
        html = fetch_from_url(FALLBACK_URL)

    if html:
        raw_notices = parse_notices(html, BASE_URL)
        process(raw_notices)
    else:
        print("❌ Could not fetch any HTML content from MAKAUT.")

    print("✅ Scraper Job Finished.")
