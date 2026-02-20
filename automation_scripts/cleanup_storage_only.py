import requests
import json

# --- CONFIG ---
SUPABASE_URL = "https://nikvdsulxvinkvxstxol.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5pa3Zkc3VseHZpbmt2eHN0eG9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyNjI0NzAsImV4cCI6MjA4NjgzODQ3MH0.QCsZ9SwePb5xhnnGIyPJ8ZksBuKJ8I8pYMtydkJuNc0"
BUCKET = "pyqs_pdf"

HEADERS_SB = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
    "Content-Type": "application/json"
}

def list_objects(prefix=""):
    url = f"{SUPABASE_URL}/storage/v1/object/list/{BUCKET}"
    payload = {
        "prefix": prefix,
        "limit": 1000,
        "offset": 0,
        "sortBy": {"column": "name", "order": "asc"}
    }
    resp = requests.post(url, headers=HEADERS_SB, json=payload)
    if resp.status_code == 200:
        return resp.json()
    print(f"Error listing {prefix}: {resp.status_code} {resp.text}")
    return []

def delete_objects(paths):
    if not paths: return
    url = f"{SUPABASE_URL}/storage/v1/object/{BUCKET}"
    payload = {"prefixes": paths}
    # DELETE with body is sometimes tricky, let's try the Bulk Delete endpoint if it exists
    # Standard Supabase Bulk Delete: DELETE /storage/v1/object/{bucketId}
    resp = requests.delete(url, headers=HEADERS_SB, json=payload)
    if resp.status_code in (200, 204):
        print(f"  Successfully deleted {len(paths)} objects.")
        return True
    print(f"  Error deleting objects: {resp.status_code} {resp.text}")
    return False

def recursive_delete_except_cse(prefix=""):
    items = list_objects(prefix)
    
    files_to_delete = []
    
    for item in items:
        name = item['name']
        full_path = f"{prefix}{name}" if not prefix else f"{prefix}/{name}"
        
        # Skip CSE top-level folder
        if prefix == "" and name == "CSE":
            print(f"Skipping department: {name}")
            continue
            
        if item.get('id') is None: # It's a folder (Supabase list returns items with id=None for folders)
            print(f"Entering folder: {full_path}")
            recursive_delete_except_cse(full_path)
        else:
            files_to_delete.append(full_path)
            
        if len(files_to_delete) >= 100: # Batch delete
            delete_objects(files_to_delete)
            files_to_delete = []
            
    if files_to_delete:
        delete_objects(files_to_delete)

def main():
    print(f"Starting cleanup of bucket '{BUCKET}' (Keeping CSE)...")
    recursive_delete_except_cse()
    print("Cleanup complete.")

if __name__ == "__main__":
    main()
