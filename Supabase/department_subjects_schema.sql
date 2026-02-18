-- =============================================
-- Department-Subjects Lookup Table
-- Auto-synced from syllabus, pyq, and notes
-- Run this in the Supabase SQL Editor
-- =============================================

-- 1. Create the lookup table
CREATE TABLE IF NOT EXISTS public.department_subjects (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  department TEXT NOT NULL,
  semester   INT  NOT NULL CHECK (semester BETWEEN 1 AND 8),
  subject    TEXT NOT NULL,
  source     TEXT NOT NULL DEFAULT 'syllabus',  -- which table first introduced this row
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (department, semester, subject)
);

-- 2. Index for fast queries
CREATE INDEX IF NOT EXISTS idx_dept_subjects_lookup
  ON public.department_subjects (department, semester);

-- 3. Enable RLS
ALTER TABLE public.department_subjects ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies

-- Anyone can read
DROP POLICY IF EXISTS "Anyone can view department_subjects" ON public.department_subjects;
CREATE POLICY "Anyone can view department_subjects"
ON public.department_subjects FOR SELECT
TO public
USING (true);

-- Authenticated can insert (trigger runs as table owner, but just in case)
DROP POLICY IF EXISTS "Anyone can insert department_subjects" ON public.department_subjects;
CREATE POLICY "Anyone can insert department_subjects"
ON public.department_subjects FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Authenticated can delete
DROP POLICY IF EXISTS "Anyone can delete department_subjects" ON public.department_subjects;
CREATE POLICY "Anyone can delete department_subjects"
ON public.department_subjects FOR DELETE
TO anon, authenticated
USING (true);

-- 5. Trigger function: full synchronization (INSERT, UPDATE, DELETE)
-- =============================================
CREATE OR REPLACE FUNCTION sync_department_subjects()
RETURNS TRIGGER AS $$
BEGIN
  -- 1. Handle Insertion of NEW subject (on INSERT or subject-changing UPDATE)
  IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE' AND (NEW.subject <> OLD.subject OR NEW.semester <> OLD.semester OR NEW.department <> OLD.department)) THEN
    INSERT INTO public.department_subjects (department, semester, subject, source)
    VALUES (NEW.department, NEW.semester, NEW.subject, TG_TABLE_NAME)
    ON CONFLICT (department, semester, subject) DO NOTHING;
  END IF;

  -- 2. Handle Removal of OLD subject (on DELETE or subject-changing UPDATE)
  IF (TG_OP = 'DELETE') OR (TG_OP = 'UPDATE' AND (NEW.subject <> OLD.subject OR NEW.semester <> OLD.semester OR NEW.department <> OLD.department)) THEN
    -- Only delete from lookup if it no longer exists in ANY source table
    IF NOT EXISTS (SELECT 1 FROM public.syllabus WHERE department = OLD.department AND semester = OLD.semester AND subject = OLD.subject)
       AND NOT EXISTS (SELECT 1 FROM public.pyq WHERE department = OLD.department AND semester = OLD.semester AND subject = OLD.subject)
       AND NOT EXISTS (SELECT 1 FROM public.notes WHERE department = OLD.department AND semester = OLD.semester AND subject = OLD.subject)
    THEN
      DELETE FROM public.department_subjects 
      WHERE department = OLD.department AND semester = OLD.semester AND subject = OLD.subject;
    END IF;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 6. Attach trigger to all three source tables (INSERT, UPDATE, DELETE)
-- Clear existing to avoid duplicates if re-run
DROP TRIGGER IF EXISTS trg_syllabus_sync ON public.syllabus;
CREATE TRIGGER trg_syllabus_sync
  AFTER INSERT OR UPDATE OR DELETE ON public.syllabus
  FOR EACH ROW EXECUTE FUNCTION sync_department_subjects();

DROP TRIGGER IF EXISTS trg_pyq_sync ON public.pyq;
CREATE TRIGGER trg_pyq_sync
  AFTER INSERT OR UPDATE OR DELETE ON public.pyq
  FOR EACH ROW EXECUTE FUNCTION sync_department_subjects();

DROP TRIGGER IF EXISTS trg_notes_sync ON public.notes;
CREATE TRIGGER trg_notes_sync
  AFTER INSERT OR UPDATE OR DELETE ON public.notes
  FOR EACH ROW EXECUTE FUNCTION sync_department_subjects();

-- =============================================
-- 7. Backfill from existing data
-- =============================================
INSERT INTO public.department_subjects (department, semester, subject, source)
SELECT DISTINCT department, semester, subject, 'syllabus'
FROM public.syllabus
ON CONFLICT (department, semester, subject) DO NOTHING;

INSERT INTO public.department_subjects (department, semester, subject, source)
SELECT DISTINCT department, semester, subject, 'pyq'
FROM public.pyq
ON CONFLICT (department, semester, subject) DO NOTHING;

INSERT INTO public.department_subjects (department, semester, subject, source)
SELECT DISTINCT department, semester, subject, 'notes'
FROM public.notes
ON CONFLICT (department, semester, subject) DO NOTHING;
