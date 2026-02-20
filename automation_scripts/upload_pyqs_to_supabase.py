import os
import re
import requests
from pathlib import Path

# --- CONFIG ---
SUPABASE_URL = "https://nikvdsulxvinkvxstxol.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5pa3Zkc3VseHZpbmt2eHN0eG9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyNjI0NzAsImV4cCI6MjA4NjgzODQ3MH0.QCsZ9SwePb5xhnnGIyPJ8ZksBuKJ8I8pYMtydkJuNc0"
BUCKET = "pyqs_pdf"
TABLE = "pyq"

HEADERS_SB = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
}

BASE_DIR = Path("/Users/ankurbag/Documents/GitHub/Makaut_Scholar/PYQ questions/Departments")
TARGET_DEPARTMENTS = ["CSE", "IT", "ECE", "EE", "ME", "CE"]

def get_existing_records():
    print("Fetching existing records from Supabase...")
    url = f"{SUPABASE_URL}/rest/v1/{TABLE}?select=department,semester,subject,year"
    resp = requests.get(url, headers=HEADERS_SB)
    if resp.status_code == 200:
        return set((r['department'], r['semester'], r['subject'], r['year']) for r in resp.json())
    print(f"Failed to fetch records: {resp.status_code} {resp.text}")
    return set()

def upload_file(file_path, storage_path):
    public_url = f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/{storage_path}"
    
    # 1. First check if it's already in storage
    try:
        head_resp = requests.head(public_url)
        if head_resp.status_code == 200:
            return public_url
    except:
        pass

    # 2. Try to upload
    url = f"{SUPABASE_URL}/storage/v1/object/{BUCKET}/{storage_path}"
    with open(file_path, "rb") as f:
        resp = requests.post(
            url,
            headers={**HEADERS_SB, "Content-Type": "application/pdf", "x-upsert": "true"},
            data=f.read(),
        )
    if resp.status_code in (200, 201):
        return public_url
    
    # 3. If RLS error, it might already be there but we can't overwrite
    if resp.status_code == 400 and "violates row-level security" in resp.text:
        try:
            head_resp = requests.head(public_url)
            if head_resp.status_code == 200:
                return public_url
        except:
            pass

    print(f"  Upload failed for {storage_path}: {resp.status_code} {resp.text[:200]}")
    return None

def insert_metadata(dept, sem, subject, year, file_url):
    url = f"{SUPABASE_URL}/rest/v1/{TABLE}"
    row = {
        "department": dept,
        "semester": sem,
        "subject": subject,
        "year": str(year),
        "file_url": file_url,
    }
    resp = requests.post(
        url,
        headers={**HEADERS_SB, "Content-Type": "application/json", "Prefer": "return=minimal"},
        json=row,
    )
    if resp.status_code in (200, 201):
        return True
    print(f"  Metadata insert failed for {subject} {year}: {resp.status_code} {resp.text[:200]}")
    return False

def main():
    existing = get_existing_records()
    print(f"Found {len(existing)} existing records.")

    count = 0
    uploaded = 0
    
    # Traverse Departments
    for dept_dir in BASE_DIR.iterdir():
        if not dept_dir.is_dir(): continue
        dept = dept_dir.name
        if dept not in TARGET_DEPARTMENTS:
            continue
        
        # Traverse Semesters (SEM1, SEM2, etc.)
        for sem_dir in dept_dir.iterdir():
            if not sem_dir.is_dir(): continue
            sem_name = sem_dir.name
            m = re.match(r'SEM(\d)', sem_name)
            if not m: continue
            sem = int(m.group(1))
            
            # Traverse Subjects
            for sub_dir in sem_dir.iterdir():
                if not sub_dir.is_dir(): continue
                subject = sub_dir.name
                
                # Traverse Files
                for file in sub_dir.glob("*.pdf"):
                    filename = file.name
                    # Parse year from filename: Subject_Name-2023.pdf
                    year_match = re.search(r'-(\d{4})\.pdf$', filename)
                    year = year_match.group(1) if year_match else "Unknown"
                    
                    count += 1
                    
                    # Check if already exists
                    if (dept, sem, subject, year) in existing:
                        # print(f"Skipping {dept} Sem {sem} {subject} {year} (Already exists)")
                        continue
                    
                    print(f"Processing {dept} Sem {sem} {subject} {year}...")
                    
                    # 1. Upload
                    storage_path = f"{dept}/{sem_name}/{subject}/{filename}"
                    file_url = upload_file(file, storage_path)
                    if not file_url: continue
                    
                    # 2. Insert metadata
                    if insert_metadata(dept, sem, subject, year, file_url):
                        uploaded += 1
                        print(f"  Success!")
                        
    print(f"\nDone! Processed {count} files. Uploaded {uploaded} new records.")

if __name__ == "__main__":
    main()
