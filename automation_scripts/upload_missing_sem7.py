#!/usr/bin/env python3
"""Upload missing Sem7 syllabus PDFs to Supabase storage + metadata table."""

import os
import sys
import re
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
DEPARTMENT = "CSE"
SEMESTER = 7

HEADERS_SB = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
}

SEM7_DIR = Path(__file__).parent / "syllabus_downloads" / "CSE" / "Sem7"

# These are the 7 subjects manually added locally but NOT yet in Supabase
# Format: (local_filename, subject_name)
MISSING_SUBJECTS = [
    ("Control System (CS705C).pdf", "Control System"),
    ("Data Warehousing and Data Mining (CS704C).pdf", "Data Warehousing and Data Mining"),
    ("Internet Technology (CS705A).pdf", "Internet Technology"),
    ("Microelectronics & VLSI Design (CS705B).pdf", "Microelectronics & VLSI Design"),
    ("Mobile Computing (CS704E).pdf", "Mobile Computing"),
    ("Modelling & Simulation (CS705D).pdf", "Modelling & Simulation"),
    ("Sensor Networks (CS704D).pdf", "Sensor Networks"),
]


def safe_filename(name: str) -> str:
    """Convert a subject name to a safe filename for Supabase storage path."""
    return re.sub(r'[^\w\-]', '_', name).replace('__', '_').strip('_')


def upload_to_supabase(filepath: Path, storage_path: str) -> str:
    """Upload a PDF to Supabase storage. Returns public URL."""
    url = f"{SUPABASE_URL}/storage/v1/object/{BUCKET}/{storage_path}"
    with open(filepath, "rb") as f:
        resp = requests.post(
            url,
            headers={**HEADERS_SB, "Content-Type": "application/pdf", "x-upsert": "true"},
            data=f.read(),
        )
    if resp.status_code in (200, 201):
        return f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/{storage_path}"
    print(f"    ⚠ Upload failed: {resp.status_code} {resp.text[:200]}")
    return ""


def insert_metadata(subject: str, title: str, file_url: str) -> bool:
    """Insert syllabus metadata into the syllabus table."""
    url = f"{SUPABASE_URL}/rest/v1/{TABLE}"
    row = {
        "department": DEPARTMENT,
        "semester": SEMESTER,
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


def main():
    success = 0
    print(f"\n{'='*60}")
    print(f"📚 Uploading {len(MISSING_SUBJECTS)} missing Sem7 subjects to Supabase")
    print(f"{'='*60}")

    for local_filename, subject in MISSING_SUBJECTS:
        filepath = SEM7_DIR / local_filename
        print(f"\n  → {subject}")

        if not filepath.exists():
            print(f"    ❌ File not found: {filepath}")
            continue

        size_kb = filepath.stat().st_size / 1024
        print(f"    📄 Local file: {local_filename} ({size_kb:.0f} KB)")

        # Use safe filename for storage path
        safe_name = f"{safe_filename(subject)}.pdf"
        storage_path = f"{DEPARTMENT}/Sem{SEMESTER}/{safe_name}"

        # 1. Upload to Supabase storage
        public_url = upload_to_supabase(filepath, storage_path)
        if not public_url:
            continue
        print(f"    ⬆️  Uploaded to storage")

        # 2. Insert metadata
        title = f"{subject} Syllabus"
        if insert_metadata(subject, title, public_url):
            print(f"    ✅ Uploaded & recorded")
            success += 1
        else:
            print(f"    ⚠ Uploaded but metadata insert failed")

    print(f"\n{'='*60}")
    print(f"✅ DONE! {success}/{len(MISSING_SUBJECTS)} missing PDFs uploaded successfully.")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
