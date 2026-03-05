import requests
from bs4 import BeautifulSoup
import os
from supabase import create_client, Client
from datetime import datetime, timedelta
import re
import json

# --- Supabase Configuration ---
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

def get_supabase_client():
    if not SUPABASE_URL or not SUPABASE_KEY:
        print("⚠️  WARNING: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY missing!")
        print("   Running in DRY-RUN mode — no data will be saved to the database.")
        return None
    try:
        # Debug: Print key info (securely) to identify if it's anon or service_role
        key_type = "SERVICE_ROLE" if len(SUPABASE_KEY) > 100 else "ANON/SHORT"
        print(f"✅ Supabase connected to: {SUPABASE_URL}")
        print(f"📊 Auth Mode: Using {key_type} key (Length: {len(SUPABASE_KEY)})")
        return create_client(SUPABASE_URL, SUPABASE_KEY)
    except Exception as e:
        print(f"❌ Error connecting to Supabase: {e}")
        return None

supabase: Client = get_supabase_client()

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
    # Handle common prefix format DD-MM-YYYY- Title or DD-MM-YYYY Title
    date_match = re.search(r'(\d{1,2}[-/\.]\d{1,2}[-/\.]\d{4})', date_str)
    if date_match:
        date_str = date_match.group(1)

    formats = ["%d-%m-%Y", "%d/%m/%Y", "%Y-%m-%d", "%d.%m.%Y", "%B %d, %Y", "%d %B %Y"]
    for fmt in formats:
        try:
            return datetime.strptime(date_str, fmt).strftime("%Y-%m-%d")
        except ValueError:
            continue
    
    # If no date found, default to today
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
            if keyword in ["registration", "enrollment", "form fill-up", "form fill up", "enrolment"]:
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
            
            # Navigate to the page and wait for JS to execute
            print(f"  [playwright] Navigating to {url}...")
            page.goto(url, wait_until='networkidle', timeout=60000)
            
            # Small extra wait for slow loaders
            page.wait_for_timeout(3000) 
            
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

    # Find all anchor tags
    all_links = soup.find_all('a', href=True)
    print(f"  Found {len(all_links)} anchor tags total.")

    for link in all_links:
        href = link['href']
        text = link.get_text(separator=" ", strip=True)

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

        # Try to extract date from link text, parent text, or grandparent text
        parent = link.parent
        grandparent = parent.parent if parent else None
        
        parent_text = parent.get_text(separator=" ", strip=True) if parent else ""
        grandparent_text = grandparent.get_text(separator=" ", strip=True) if grandparent else ""
        
        combined_text = f"{text} {parent_text} {grandparent_text}"
        
        date_match = re.search(date_pattern, combined_text)
        date_str = ""
        if date_match:
            date_str = date_match.group(1)
            # Remove date from the title to keep it clean
            text = text.replace(date_str, "").strip()
            text = re.sub(r'^[-:\s]+|[-:\s]+$', '', text).strip()
        else:
            date_str = datetime.now().strftime("%d-%m-%Y")

        if text and len(text) > 5:
            notices.append({
                "title": text,
                "link": full_link,
                "date_str": date_str
            })

    return notices


def save_to_supabase(notice_record):
    if not supabase:
        print(f"  [DRY-RUN] {notice_record['category']}: {notice_record['title'][:50]}...")
        return False
    try:
        supabase.table("official_notifications").upsert(notice_record, on_conflict='link').execute()
        print(f"  ✅ [SAVED/UPDATED] {notice_record['category']}: {notice_record['title'][:50]}...")
        return True
    except Exception as e:
        err_str = str(e)
        if "duplicate key value" in err_str or "23505" in err_str:
            return False # Already synced (upsert shouldn't really hit this but good for safety)
        else:
            print(f"  ❌ Supabase Error for '{notice_record['title'][:30]}...': {err_str}")
        return False


def process(notices):
    new_count = 0
    relevant_found = 0
    max_notices_to_keep = 7

    print(f"🔍 Keeping only the latest {max_notices_to_keep} student notices...")

    # Sort notices by date descending to ensure we get the latest ones first
    # However, the site usually lists them newest-first. We'll parse the date and sort just in case.
    for n in notices:
        n['parsed_date'] = parse_date(n['date_str'])
    
    notices.sort(key=lambda x: x['parsed_date'], reverse=True)

    for notice in notices:
        if relevant_found >= max_notices_to_keep:
            break

        relevant, category = is_relevant(notice['title'])
        if not relevant:
            continue
            
        relevant_found += 1
        record = {
            "title": notice['title'],
            "link": notice['link'],
            "date_posted": notice['parsed_date'],
            "category": category,
            "is_new": True
        }
        
        if save_to_supabase(record):
            new_count += 1

    print(f"\n📊 Summary:")
    print(f"   Total unique links found: {len(notices)}")
    print(f"   Relevant kept:            {relevant_found}")
    print(f"   Newly added/updated:       {new_count}")



if __name__ == "__main__":
    print(f"🚀 Starting MAKAUT Scraper at {datetime.now().isoformat()}")

    # Try primary URL
    html = fetch_from_url(MAKAUT_NOTICE_URL)
    
    # If primary has notices, parse them. Also try fallback if no notices found on primary.
    if html:
        raw_notices = parse_notices(html, BASE_URL)
        if len(raw_notices) < 5:
            print("Very few notices found on primary, trying fallback...")
            html_fallback = fetch_from_url(FALLBACK_URL)
            if html_fallback:
                raw_notices.extend(parse_notices(html_fallback, BASE_URL))
        
        if raw_notices:
            process(raw_notices)
        else:
            print("❌ No notices found in the fetched HTML.")
    else:
        print("❌ Could not fetch any HTML content.")

    print("✅ Scraper Job Finished.")
