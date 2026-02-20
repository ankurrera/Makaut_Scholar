#!/usr/bin/env python3
"""Scrape, download, and upload CSE syllabus PDFs for Semesters 1, 3-7."""

import os
import sys
import re
import time
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
BASE_DIR = Path(__file__).parent / "syllabus_downloads" / "CSE"

HEADERS_SB = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
}

# Paper IDs discovered from browser navigation, grouped by semester
# Format: (paper_id, subject_name)
SEMESTERS = {
    1: [
        (558, "Physics-I"),
        (560, "Mathematics-IA"),
        (562, "Basic Electrical Engineering"),
        (563, "Physics-I Laboratory"),
        (565, "Basic Electrical Engineering Laboratory"),
        (567, "Workshop/Manufacturing Practices"),
    ],
    3: [
        (568, "Mathematics-III"),
        (95, "Computer Organisation"),
        (106, "Data Structure & Algorithms"),
        (139, "Analog & Digital Electronics"),
        (569, "Economics for Engineers"),
        (570, "IT Workshop"),
        (226, "Analog & Digital Electronics Laboratory"),
        (227, "Data Structure & Algorithms Laboratory"),
        (228, "Computer Organisation Laboratory"),
    ],
    4: [
        (14, "Formal Language & Automata Theory"),
        (16, "Computer Architecture"),
        (614, "Discrete Mathematics"),
        (615, "Design & Analysis of Algorithms"),
        (616, "Biology"),
        (618, "Design & Analysis of Algorithms Laboratory"),
        (619, "Computer Architecture Laboratory"),
    ],
    5: [
        (298, "Object Oriented Programming"),
        (667, "Operating Systems"),
        (668, "Compiler Design"),
        (669, "Software Engineering"),
        (670, "Introduction to Industrial Management"),
        (671, "Theory of Computation"),
        (672, "Artificial Intelligence"),
        (673, "Advanced Computer Architecture"),
        (674, "Computer Graphics"),
        (675, "Constitution of India"),
        (676, "Software Engineering Laboratory"),
        (677, "Operating Systems Laboratory"),
        (678, "Object Oriented Programming Laboratory"),
    ],
    6: [
        (19, "Computer Networks"),
        (351, "Database Management System"),
        (734, "Advanced Algorithms"),
        (735, "Distributed Systems"),
        (736, "Signals & Systems"),
        (737, "Image Processing"),
        (738, "Parallel and Distributed Algorithms"),
        (739, "Data Warehousing and Data Mining"),
        (740, "Human Computer Interaction"),
        (741, "Pattern Recognition"),
        (742, "Numerical Methods"),
        (743, "Human Resource Development"),
    ],
    7: [
        (102, "Software Engineering"),
        (103, "Artificial Intelligence"),
        (410, "Soft Computing"),
        (411, "Compiler Design"),
        (412, "Pattern Recognition"),
        (413, "Image Processing"),
        (414, "Distributed Operating System"),
        (415, "Cloud Computing"),
    ],
}


def fetch_pdf_url(paper_id: int) -> str | None:
    """Scrape the syllabus page for a paper_id and extract the wbuthelp PDF URL."""
    url = f"https://mywbut.com/syllabus/paper/{paper_id}/dept/2/"
    try:
        resp = requests.get(url, timeout=15, headers={"User-Agent": "Mozilla/5.0"})
        if resp.status_code != 200:
            return None
        # Look for wbuthelp.com/chapter_file/XXXX.pdf links
        matches = re.findall(r'https?://(?:www\.)?wbuthelp\.com/chapter_file/\d+\.pdf', resp.text)
        if matches:
            return matches[0]
        return None
    except Exception as e:
        print(f"    ⚠ Error fetching page: {e}")
        return None


def download_pdf(pdf_url: str, filepath: Path) -> bool:
    """Download a PDF from a URL to a local file."""
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
    print(f"    ⚠ Upload failed: {resp.status_code} {resp.text[:100]}")
    return ""


def insert_metadata(department: str, semester: int, subject: str, title: str, file_url: str) -> bool:
    """Insert syllabus metadata into the syllabus table."""
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
    """Convert a subject name to a safe filename."""
    return re.sub(r'[^\w\-]', '_', name).replace('__', '_').strip('_')


def main():
    total_success = 0
    total_attempted = 0

    for semester in sorted(SEMESTERS.keys()):
        subjects = SEMESTERS[semester]
        print(f"\n{'='*60}")
        print(f"📚 SEMESTER {semester} — {len(subjects)} subjects")
        print(f"{'='*60}")

        sem_dir = BASE_DIR / f"Sem{semester}"
        sem_dir.mkdir(parents=True, exist_ok=True)

        for paper_id, subject in subjects:
            total_attempted += 1
            print(f"\n  → [{paper_id}] {subject}")

            # 1. Fetch PDF URL from syllabus page
            pdf_url = fetch_pdf_url(paper_id)
            if not pdf_url:
                print(f"    ❌ No PDF found on syllabus page")
                continue
            print(f"    📄 PDF: {pdf_url}")

            # 2. Download
            filename = f"{safe_filename(subject)}.pdf"
            filepath = sem_dir / filename
            if not download_pdf(pdf_url, filepath):
                print(f"    ❌ Download failed")
                continue
            size_kb = filepath.stat().st_size / 1024
            print(f"    ⬇️  Downloaded ({size_kb:.0f} KB)")

            # 3. Upload to Supabase
            storage_path = f"{DEPARTMENT}/Sem{semester}/{filename}"
            public_url = upload_to_supabase(filepath, storage_path)
            if not public_url:
                continue

            # 4. Insert metadata
            title = f"{subject} Syllabus"
            if insert_metadata(DEPARTMENT, semester, subject, title, public_url):
                print(f"    ✅ Uploaded & recorded")
                total_success += 1
            else:
                print(f"    ⚠ Uploaded but metadata insert failed")

            # Small delay to be polite
            time.sleep(0.3)

    print(f"\n{'='*60}")
    print(f"✅ DONE! {total_success}/{total_attempted} syllabus PDFs processed successfully.")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
