-- 1. Create Important Questions table
CREATE TABLE IF NOT EXISTS public.important_questions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    department TEXT NOT NULL,
    semester INTEGER NOT NULL,
    subject TEXT NOT NULL,
    title TEXT NOT NULL,
    file_url TEXT NOT NULL,
    uploaded_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Enable RLS
ALTER TABLE public.important_questions ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policies
-- Anyone can read
DROP POLICY IF EXISTS "Anyone can view important_questions" ON public.important_questions;
CREATE POLICY "Anyone can view important_questions"
ON public.important_questions FOR SELECT
TO public
USING (true);

-- Authenticated can insert
DROP POLICY IF EXISTS "Anyone can insert important_questions" ON public.important_questions;
CREATE POLICY "Anyone can insert important_questions"
ON public.important_questions FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Authenticated can delete
DROP POLICY IF EXISTS "Anyone can delete important_questions" ON public.important_questions;
CREATE POLICY "Anyone can delete important_questions"
ON public.important_questions FOR DELETE
TO anon, authenticated
USING (true);

-- 4. Storage Bucket (This is usually done via UI, but here is the manual setup if needed)
-- Note: Supabase storage buckets are often managed via the dashboard. 
-- Ensure a bucket named 'important_questions_pdf' exists with public access.

-- 5. Helpful Index
CREATE INDEX IF NOT EXISTS idx_imp_dept_sem_subj ON public.important_questions(department, semester, subject);
