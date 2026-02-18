-- ====================================
-- Syllabus Schema for Makaut Scholar
-- ====================================

-- 1. Create syllabus table
CREATE TABLE IF NOT EXISTS public.syllabus (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  department  TEXT NOT NULL,            -- e.g. 'CSE', 'ECE', 'ME'
  semester    INT  NOT NULL CHECK (semester BETWEEN 1 AND 8),
  subject     TEXT NOT NULL,            -- Subject name
  title       TEXT NOT NULL,            -- Display title for the syllabus PDF
  file_url    TEXT NOT NULL,            -- Public URL of the PDF
  uploaded_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Index for fast lookups
CREATE INDEX idx_syllabus_dept_sem
  ON public.syllabus (department, semester);

CREATE INDEX idx_syllabus_dept_sem_sub
  ON public.syllabus (department, semester, subject);

-- 3. Enable RLS
ALTER TABLE public.syllabus ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies

-- Anyone can read syllabus
CREATE POLICY "Anyone can view syllabus"
ON public.syllabus FOR SELECT
TO public
USING (true);

-- Anon + authenticated can insert (for admin uploads / scraping)
CREATE POLICY "Anyone can insert syllabus"
ON public.syllabus FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Anon + authenticated can delete
CREATE POLICY "Anyone can delete syllabus"
ON public.syllabus FOR DELETE
TO anon, authenticated
USING (true);

-- Anon + authenticated can update (for admin edits)
CREATE POLICY "Anyone can update syllabus"
ON public.syllabus FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- 5. Create storage bucket for syllabus PDFs
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'syllabus_pdf',
  'syllabus_pdf',
  true,
  10485760,  -- 10 MB
  ARRAY['application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- 6. Storage RLS policies
CREATE POLICY "Anyone can view syllabus PDFs"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'syllabus_pdf');

CREATE POLICY "Anyone can upload syllabus PDFs"
ON storage.objects FOR INSERT
TO anon, authenticated
WITH CHECK (bucket_id = 'syllabus_pdf');

CREATE POLICY "Anyone can delete syllabus PDFs"
ON storage.objects FOR DELETE
TO anon, authenticated
USING (bucket_id = 'syllabus_pdf');
