-- =============================================
-- Supabase: Notes Table + PDF Storage Bucket
-- Run this in the Supabase SQL Editor
-- =============================================

-- 1. Create the notes table
CREATE TABLE IF NOT EXISTS public.notes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  department TEXT NOT NULL,
  semester INTEGER NOT NULL CHECK (semester >= 1 AND semester <= 8),
  subject TEXT NOT NULL,
  unit INTEGER NOT NULL CHECK (unit >= 1 AND unit <= 6),
  title TEXT NOT NULL,
  file_url TEXT NOT NULL,
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_notes_lookup
ON public.notes (department, semester, subject, unit);

-- 3. Enable RLS
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
-- Anyone can read notes
CREATE POLICY "Anyone can view notes"
ON public.notes FOR SELECT
TO public
USING (true);

-- Anon + authenticated users can insert notes (admin use)
CREATE POLICY "Anon and authenticated can insert notes"
ON public.notes FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Anon + authenticated users can delete notes (admin use)
CREATE POLICY "Anon and authenticated can delete notes"
ON public.notes FOR DELETE
TO anon, authenticated
USING (true);

-- =============================================
-- 5. Create the storage bucket for note PDFs
-- =============================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'notes_pdf',
  'notes_pdf',
  true,
  10485760,                    -- 10MB limit
  ARRAY['application/pdf']     -- PDF only
)
ON CONFLICT (id) DO NOTHING;

-- 6. Storage RLS Policies

-- Anyone can read PDFs
CREATE POLICY "Anyone can view note PDFs"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'notes_pdf');

-- Anon + authenticated users can upload PDFs
CREATE POLICY "Anon and authenticated can upload note PDFs"
ON storage.objects FOR INSERT
TO anon, authenticated
WITH CHECK (bucket_id = 'notes_pdf');

-- Anon + authenticated users can delete PDFs
CREATE POLICY "Anon and authenticated can delete note PDFs"
ON storage.objects FOR DELETE
TO anon, authenticated
USING (bucket_id = 'notes_pdf');
