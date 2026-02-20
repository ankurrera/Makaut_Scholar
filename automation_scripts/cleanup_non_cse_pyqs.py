import requests
import json
from urllib.parse import unquote

# --- CONFIG ---
SUPABASE_URL = "https://nikvdsulxvinkvxstxol.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5pa3Zkc3VseHZpbmt2eHN0eG9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyNjI0NzAsImV4cCI6MjA4NjgzODQ3MH0.QCsZ9SwePb5xhnnGIyPJ8ZksBuKJ8I8pYMtydkJuNc0"
BUCKET = "pyqs_pdf"
TABLE = "pyq"

HEADERS_SB = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
    "Content-Type": "application/json"
}

def get_non_cse_records():
    print("Fetching non-CSE records from Supabase...")
    # Get ID and file_url for deletion
    url = f"{SUPABASE_URL}/rest/v1/{TABLE}?department=neq.CSE&select=id,file_url,department,subject&limit=10000"
    resp = requests.get(url, headers=HEADERS_SB)
    if resp.status_code == 200:
        return resp.json()
    print(f"Failed to fetch records: {resp.status_code} {resp.text}")
    return []

def delete_storage_file(file_url):
    # URL format: .../public/pyqs_pdf/DEPT/SEMx/SUBJ/FILE.pdf
    # We need the path: DEPT/SEMx/SUBJ/FILE.pdf
    try:
        path_start_marker = f"/public/{BUCKET}/"
        if path_start_marker not in file_url:
            print(f"  Unexpected URL format: {file_url}")
            return False
        
        storage_path = file_url.split(path_start_marker)[1]
        storage_path = unquote(storage_path) # Decode URL entities like %20
        
        url = f"{SUPABASE_URL}/storage/v1/object/{BUCKET}/{storage_path}"
        # Remove Content-Type for DELETE request to storage
        headers = {k: v for k, v in HEADERS_SB.items() if k != "Content-Type"}
        resp = requests.delete(url, headers=headers)
        
        if resp.status_code in (200, 204):
            return True
        elif resp.status_code == 404:
            # Already gone or path mismatch
            return True
        else:
            print(f"  Storage delete failed for {storage_path}: {resp.status_code} {resp.text}")
            return False
    except Exception as e:
        print(f"  Error deleting storage file: {e}")
        return False

def delete_db_record(record_id):
    url = f"{SUPABASE_URL}/rest/v1/{TABLE}?id=eq.{record_id}"
    resp = requests.delete(url, headers=HEADERS_SB)
    if resp.status_code in (200, 204):
        return True
    print(f"  DB delete failed for {record_id}: {resp.status_code} {resp.text}")
    return False

def main():
    records = get_non_cse_records()
    total = len(records)
    print(f"Found {total} records to delete.")
    
    deleted_storage = 0
    deleted_db = 0
    
    for i, rec in enumerate(records):
        rec_id = rec['id']
        file_url = rec['file_url']
        dept = rec['department']
        subj = rec['subject']
        
        print(f"[{i+1}/{total}] Deleting {dept} - {subj}...")
        
        # 1. Delete from storage
        if delete_storage_file(file_url):
            deleted_storage += 1
        
        # 2. Delete from DB
        if delete_db_record(rec_id):
            deleted_db += 1
            
    print(f"\nCleanup finished!")
    print(f"Storage files deleted: {deleted_storage}")
    print(f"DB records deleted: {deleted_db}")

if __name__ == "__main__":
    main()
