-- Run this in your Supabase SQL Editor to add the missing column
ALTER TABLE public.mock_test_questions 
ADD COLUMN IF NOT EXISTS paper_code TEXT;

-- Notify PostgREST to reload the schema cache (happens automatically but this ensures it)
NOTIFY pgrst, 'reload schema';
