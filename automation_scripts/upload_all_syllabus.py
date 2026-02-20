#!/usr/bin/env python3
import os
import sys
import re
import time
import json
from pathlib import Path

try:
    import requests
except ImportError:
    os.system(f"{sys.executable} -m pip install requests -q")
    import requests

SUPABASE_URL = "https://nikvdsulxvinkvxstxol.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5pa3Zkc3VseHZpbmt2eHN0eG9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyNjI0NzAsImV4cCI6MjA4NjgzODQ3MH0.QCsZ9SwePb5xhnnGIyPJ8ZksBuKJ8I8pYMtydkJuNc0"
BUCKET = "syllabus_pdf"
TABLE = "syllabus"
BASE_DIR = Path(__file__).parent / "syllabus_downloads"

HEADERS_SB = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
}

DEPARTMENTS = {
    "IT": ("Information Technology", 4),
    "ECE": ("Electronics & Communication", 3),
    "EE": ("Electrical Engineering", 5),
    "ME": ("Mechanical Engineering", 8),
    "CE": ("Civil Engineering", 9)
}

def fetch_pdf_url(paper_id: int, dept_id: int) -> str | None:
    url = f"https://mywbut.com/syllabus/paper/{paper_id}/dept/{dept_id}/"
    try:
        resp = requests.get(url, timeout=15, headers={"User-Agent": "Mozilla/5.0"})
        if resp.status_code != 200:
            return None
        matches = re.findall(r'https?://(?:www\.)?wbuthelp\.com/chapter_file/\d+\.pdf', resp.text)
        if matches:
            return matches[0]
        return None
    except Exception as e:
        print(f"    ⚠ Error fetching page: {e}")
        return None


def download_pdf(pdf_url: str, filepath: Path) -> bool:
    try:
        resp = requests.get(pdf_url, timeout=30, headers={"User-Agent": "Mozilla/5.0"})
        if resp.status_code == 200 and len(resp.content) > 100:
            filepath.parent.mkdir(parents=True, exist_ok=True)
            filepath.write_bytes(resp.content)
            return True
        return False
    except Exception as e:
        print(f"    ⚠ Download error: {e}")
        return False


def upload_to_supabase(filepath: Path, storage_path: str) -> str:
    url = f"{SUPABASE_URL}/storage/v1/object/{BUCKET}/{storage_path}"
    with open(filepath, "rb") as f:
        resp = requests.post(
            url,
            headers={**HEADERS_SB, "Content-Type": "application/pdf", "x-upsert": "true"},
            data=f.read(),
        )
    if resp.status_code in (200, 201):
        return f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/{storage_path}"
    print(f"    ⚠ Upload failed: {resp.status_code} {resp.text[:100]}")
    return ""


def insert_metadata(department: str, semester: int, subject: str, title: str, file_url: str) -> bool:
    url = f"{SUPABASE_URL}/rest/v1/{TABLE}"
    row = {
        "department": department,
        "semester": semester,
        "subject": subject,
        "title": title,
        "file_url": file_url,
    }
    resp = requests.post(
        url,
        headers={**HEADERS_SB, "Content-Type": "application/json", "Prefer": "return=minimal"},
        json=row,
    )
    return resp.status_code in (200, 201)


def safe_filename(name: str) -> str:
    return re.sub(r'[^\w\-]', '_', name).replace('__', '_').strip('_')


def main():
    total_success = 0
    total_attempted = 0
    
    with open("other_depts_syllabus.json", "r") as f:
        data = json.load(f)

    for dept_code, _ in DEPARTMENTS.items():
        if dept_code not in data:
            continue
            
        dept_id = DEPARTMENTS[dept_code][1]
        dept_dir = BASE_DIR / dept_code
        
        print(f"\n{'='*60}")
        print(f"🚀 DEPARTMENT {dept_code}")
        print(f"{'='*60}")
        
        for sem_str, subjects in data[dept_code].items():
            semester = int(sem_str)
            if not subjects:
                continue
                
            print(f"\n  📚 SEMESTER {semester} — {len(subjects)} subjects")
            sem_dir = dept_dir / f"Sem{semester}"
            sem_dir.mkdir(parents=True, exist_ok=True)

            for subj in subjects:
                paper_id = subj["paper_id"]
                subject = subj["subject"]
                
                total_attempted += 1
                print(f"\n  → [{paper_id}] {subject}")

                pdf_url = fetch_pdf_url(paper_id, dept_id)
                if not pdf_url:
                    print(f"    ❌ No PDF found on syllabus page")
                    continue
                print(f"    📄 PDF: {pdf_url}")

                filename = f"{safe_filename(subject)}.pdf"
                filepath = sem_dir / filename
                if not download_pdf(pdf_url, filepath):
                    print(f"    ❌ Download failed")
                    continue
                size_kb = filepath.stat().st_size / 1024
                print(f"    ⬇️  Downloaded ({size_kb:.0f} KB)")

                storage_path = f"{dept_code}/Sem{semester}/{filename}"
                public_url = upload_to_supabase(filepath, storage_path)
                if not public_url:
                    continue

                title = f"{subject} Syllabus"
                if insert_metadata(dept_code, semester, subject, title, public_url):
                    print(f"    ✅ Uploaded & recorded")
                    total_success += 1
                else:
                    print(f"    ⚠ Uploaded but metadata insert failed")

                time.sleep(0.3)

    print(f"\n{'='*60}")
    print(f"✅ DONE! {total_success}/{total_attempted} syllabus PDFs processed successfully.")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
