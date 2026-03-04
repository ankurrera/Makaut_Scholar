-- =============================================
-- Mock Test Questions Table
-- =============================================

CREATE TABLE IF NOT EXISTS public.mock_test_questions (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  department    TEXT NOT NULL,
  semester      INT  NOT NULL CHECK (semester BETWEEN 1 AND 8),
  subject       TEXT NOT NULL,
  paper_code    TEXT,             -- Link for cross-department syncing
  question_text TEXT NOT NULL,
  options       TEXT[] NOT NULL,  -- Array of MCQ options
  correct_index INT NOT NULL,     -- 0-based index of correct option
  explanation   TEXT,             -- Optional explanation
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);

-- Index for fast selection
CREATE INDEX IF NOT EXISTS idx_mock_questions_lookup
  ON public.mock_test_questions (department, semester, subject);

-- Enable RLS
ALTER TABLE public.mock_test_questions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Anyone can read questions (for taking quizzes)
DROP POLICY IF EXISTS "Anyone can view mock_test_questions" ON public.mock_test_questions;
CREATE POLICY "Anyone can view mock_test_questions"
ON public.mock_test_questions FOR SELECT
TO anon, authenticated
USING (true);

-- Only service role (admin) can insert/update/delete (from admin panel)
DROP POLICY IF EXISTS "Admins can manage mock_test_questions" ON public.mock_test_questions;
CREATE POLICY "Admins can manage mock_test_questions"
ON public.mock_test_questions FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_mock_test_questions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_mock_questions_updated_at
  BEFORE UPDATE ON public.mock_test_questions
  FOR EACH ROW EXECUTE FUNCTION update_mock_test_questions_updated_at();
