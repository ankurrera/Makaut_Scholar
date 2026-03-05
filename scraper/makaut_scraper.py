# makaut_scraper.py
import requests
from bs4 import BeautifulSoup
import os
from supabase import create_client, Client
from datetime import datetime
import re
import json

# --- Supabase Configuration ---
# These will be provided securely as environment variables in GitHub Actions
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("WARNING: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY missing. Script will run in dry-run mode.")
    # Initialize with dummy values for dry-run testing locally if env vars are missing
    supabase: Client = None 
else:
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# --- Configuration ---
MAKAUT_NOTICE_URL = "https://makautwb.ac.in/page.php?id=302" # Change this if MAKAUT revamps their site page ID
BASE_URL = "https://makautwb.ac.in/"

# Keywords defining a "Student Relevant" notice
# We convert everything to lowercase for matching
STUDENT_KEYWORDS = [
    "result", "exam", "examination", "routine", "schedule", 
    "form fill-up", "form fill up", "admit card", "pps", "ppr", 
    "academic calendar", "holiday", "commencement", 
    "mar", "mooc", "nptel", "coursera", "internship", 
    "registration", "enrollment", "syllabus", "postponement"
]

# Keywords that mark a notice as administrative/irrelevant 
ADMIN_KEYWORDS = [
    "tender", "quotation", "affiliation", "faculty", "recruitment", 
    "vendor", "audit", "meeting", "workshop", "seminar", "invited lecture",
    "ph.d", "convocation", "e-tender"
]

def parse_date(date_str):
    """
    Tries to parse different date formats found on the MAKAUT site.
    Usually looking like 'DD-MM-YYYY' or similar.
    Returns ISO format date string (YYYY-MM-DD)
    """
    date_str = date_str.strip()
    try:
        # Common format: DD-MM-YYYY
        dt = datetime.strptime(date_str, "%d-%m-%Y")
        return dt.strftime("%Y-%m-%d")
    except ValueError:
        pass
    
    try:
        # Another common format: DD/MM/YYYY
        dt = datetime.strptime(date_str, "%d/%m/%Y")
        return dt.strftime("%Y-%m-%d")
    except ValueError:
        pass
    
    # Fallback, just return today's date if completely unparseable
    # so the DB insertion doesn't fail
    return datetime.now().strftime("%Y-%m-%d")


def is_relevant(title):
    """
    Determine if a notice is relevant to students.
    Returns (Boolean, Category_String)
    """
    title_lower = title.lower()
    
    # 1. Check for Admin Keywords (Exclusion List overrides everything)
    if any(keyword in title_lower for keyword in ADMIN_KEYWORDS):
        return False, "Ignored"
        
    # 2. Check for Student Keywords (Inclusion List)
    for keyword in STUDENT_KEYWORDS:
        if keyword in title_lower:
            # Assign a basic category based on keyword hit
            if keyword in ["result", "pps", "ppr"]: return True, "Results"
            if keyword in ["routine", "schedule", "exam", "admit card", "postponement"]: return True, "Examinations"
            if keyword in ["holiday", "academic calendar"]: return True, "Academic Calendar"
            if keyword in ["mar", "mooc", "internship", "nptel"]: return True, "MAR & MOOCs"
            
            return True, "General Student Notice"
            
    # Default: if it doesn't match admin but also doesn't explicitly match student keywords,
    # we might want to flag it for manual review or just drop it. 
    # For a low-noise app, we drop it.
    return False, "Uncategorized"

def fetch_notices():
    """
    Scrape the MAKAUT webpage and parse notices.
    """
    print(f"Fetching notices from {MAKAUT_NOTICE_URL}...")
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    
    try:
        response = requests.get(MAKAUT_NOTICE_URL, headers=headers, timeout=10)
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        print(f"Error fetching page: {e}")
        return []

    soup = BeautifulSoup(response.text, 'html.parser')
    notices = []
    
    # *** WARNING: This logic is tightly coupled to current MAKAUT website DOM. ***
    # Notice boards are usually in tables or lists. 
    # Inspecting typical MAKAUT site, notices are often in an accordion or list group.
    
    # Let's attempt a generalized extraction. Usually they are in <a> tags ending in .pdf
    # or inside a specific main content div.
    # Searching for links that look like notices.
    links = soup.find_all('a', href=True)
    
    for link in links:
        href = link['href']
        text = link.get_text(separator=" ", strip=True)
        
        # MAKAUT notices usually link to PDF files or other display pages
        if not text:
            continue
            
        # VERY rudimentary date extraction: looking for text near the link or inside it
        # Sometimes dates are in a sibling <span> or preceding text.
        # This regex looks for DD-MM-YYYY or DD/MM/YYYY
        date_pattern = r'(\d{1,2}[-/]\d{1,2}[-/]\d{4})'
        
        # Try finding date in the link text itself first
        date_match = re.search(date_pattern, text)
        date_str = ""
        
        if date_match:
            date_str = date_match.group(1)
            # Remove date from title for cleaner display
            text = text.replace(date_str, "").strip()
            # Clean up trailing dashes or colons
            text = re.sub(r'^[-:]|[-:]$', '', text).strip()
        else:
            # Look at the parent or previous sibling (often table cells)
            parent_text = link.parent.get_text(separator=" ", strip=True)
            parent_date_match = re.search(date_pattern, parent_text)
            if parent_date_match:
                date_str = parent_date_match.group(1)
            else:
                date_str = datetime.now().strftime("%d-%m-%Y") # Fallback
                
        # Resolve relative URLs
        full_link = href if href.startswith('http') else BASE_URL + href.lstrip('/')
        
        # Basic filtering: we only want links that resemble documents or specific notice pages.
        # MAKAUT sometimes uses javascript:void(0) or anchors. Skip those.
        if "javascript" in full_link or full_link.startswith('#') or full_link == BASE_URL:
            continue
            
        # Deduplicate within the same run
        if any(n['link'] == full_link for n in notices):
            continue
            
        notices.append({
            "title": text,
            "link": full_link,
            "date_str": date_str
        })
        
    print(f"Parsed {len(notices)} potential links.")
    return notices

def process_and_save(notices):
    """
    Filter notices and save to Supabase.
    """
    new_notices_count = 0
    scraped_data = []

    for notice in notices:
        title = notice['title']
        link = notice['link']
        
        # 1. Filter
        relevant, category = is_relevant(title)
        
        if not relevant:
            continue
            
        # 2. Format Date
        db_date = parse_date(notice['date_str'])
        
        notice_record = {
            "title": title,
            "link": link,
            "date_posted": db_date,
            "category": category,
            "is_new": True
        }
        
        scraped_data.append(notice_record)
        
        # 3. Save to Supabase
        if supabase:
            try:
                # Upsert based on unique 'link'. If it exists, it ignores.
                # In Supabase, you can set 'on_conflict' on your PK or UNIQUE constraints.
                # We defined 'link' as UNIQUE in our schema.
                response = supabase.table("official_notifications").insert(
                    notice_record
                ).execute()
                
                # If we get here, insertion was successful (no unique constraint violation)
                print(f"[NEW] {category}: {title}")
                new_notices_count += 1
                
            except Exception as e:
                err_str = str(e)
                # Ignore duplicate key errors, that just means we've already synced this notice
                if "duplicate key value" in err_str or "23505" in err_str:
                    pass
                else:
                    print(f"Supabase Error on '{title}': {err_str}")
        else:
            # Dry run mode
            print(f"[DRY-RUN - NEW] {category}: {title} | {db_date} | {link}")
            
    if supabase:
        print(f"\nSync complete. Inserted {new_notices_count} new student-relevant notices into Supabase.")
    else:
        print(f"\nDry-run complete. Found {len(scraped_data)} relevant notices.")
        
    # Optional: Save dry-run to file for local inspection
    with open("scraped_notices_debug.json", "w") as f:
        json.dump(scraped_data, f, indent=4)

if __name__ == "__main__":
    print(f"Starting MAKAUT Scraper Job at {datetime.now().isoformat()}")
    raw_notices = fetch_notices()
    process_and_save(raw_notices)
    print("Scraper Job Finished.")
