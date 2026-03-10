-- =============================================
-- Supabase Storage: Missing Buckets Fix
-- Run this in the Supabase SQL Editor
-- =============================================

-- 1. Create the 'notices_pdf' bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'notices_pdf',
  'notices_pdf',
  true,
  10485760, -- 10MB
  ARRAY['application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- 2. Create the 'important_questions_pdf' bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'important_questions_pdf',
  'important_questions_pdf',
  true,
  10485760, -- 10MB
  ARRAY['application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- 3. RLS Policies for 'notices_pdf'
DROP POLICY IF EXISTS "Public Read Notices" ON storage.objects;
CREATE POLICY "Public Read Notices" ON storage.objects FOR SELECT TO public USING (bucket_id = 'notices_pdf');

DROP POLICY IF EXISTS "Admin Upload Notices" ON storage.objects;
CREATE POLICY "Admin Upload Notices" ON storage.objects FOR INSERT TO anon, authenticated WITH CHECK (bucket_id = 'notices_pdf');

DROP POLICY IF EXISTS "Admin Delete Notices" ON storage.objects;
CREATE POLICY "Admin Delete Notices" ON storage.objects FOR DELETE TO anon, authenticated USING (bucket_id = 'notices_pdf');

-- 4. RLS Policies for 'important_questions_pdf'
DROP POLICY IF EXISTS "Public Read Imp Questions" ON storage.objects;
CREATE POLICY "Public Read Imp Questions" ON storage.objects FOR SELECT TO public USING (bucket_id = 'important_questions_pdf');

DROP POLICY IF EXISTS "Admin Upload Imp Questions" ON storage.objects;
CREATE POLICY "Admin Upload Imp Questions" ON storage.objects FOR INSERT TO anon, authenticated WITH CHECK (bucket_id = 'important_questions_pdf');

DROP POLICY IF EXISTS "Admin Delete Imp Questions" ON storage.objects;
CREATE POLICY "Admin Delete Imp Questions" ON storage.objects FOR DELETE TO anon, authenticated USING (bucket_id = 'important_questions_pdf');
