-- =============================================
-- Migration: Rename department_subjects cache table to subjects_bundle
-- Run this in the Supabase SQL Editor
-- =============================================

-- 1. Rename the table
ALTER TABLE IF EXISTS public.department_subjects RENAME TO subjects_bundle;

-- 2. Drop the old trigger function (which will drop the triggers hooked to it)
DROP FUNCTION IF EXISTS public.sync_department_subjects() CASCADE;

-- 3. Create the new trigger function
CREATE OR REPLACE FUNCTION public.sync_subjects_bundle()
RETURNS TRIGGER AS $$
BEGIN
  -- 1. Handle Insertion of NEW subject (on INSERT or subject-changing UPDATE)
  IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE' AND (NEW.subject <> OLD.subject OR NEW.semester <> OLD.semester OR NEW.department <> OLD.department OR COALESCE(NEW.paper_code, '') <> COALESCE(OLD.paper_code, ''))) THEN
    INSERT INTO public.subjects_bundle (department, semester, subject, paper_code, source)
    VALUES (NEW.department, NEW.semester, NEW.subject, NEW.paper_code, TG_TABLE_NAME)
    ON CONFLICT (department, semester, subject) DO UPDATE
    SET paper_code = EXCLUDED.paper_code;
  END IF;

  -- 2. Handle Removal of OLD subject (on DELETE or subject-changing UPDATE)
  IF (TG_OP = 'DELETE') OR (TG_OP = 'UPDATE' AND (NEW.subject <> OLD.subject OR NEW.semester <> OLD.semester OR NEW.department <> OLD.department)) THEN
    -- Only delete from lookup if it no longer exists in ANY source table
    IF NOT EXISTS (SELECT 1 FROM public.syllabus WHERE department = OLD.department AND semester = OLD.semester AND subject = OLD.subject)
       AND NOT EXISTS (SELECT 1 FROM public.pyq WHERE department = OLD.department AND semester = OLD.semester AND subject = OLD.subject)
       AND NOT EXISTS (SELECT 1 FROM public.notes WHERE department = OLD.department AND semester = OLD.semester AND subject = OLD.subject)
    THEN
      DELETE FROM public.subjects_bundle 
      WHERE department = OLD.department AND semester = OLD.semester AND subject = OLD.subject;
    END IF;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 4. Attach new triggers to all three source tables
CREATE TRIGGER trg_syllabus_sync
  AFTER INSERT OR UPDATE OR DELETE ON public.syllabus
  FOR EACH ROW EXECUTE FUNCTION public.sync_subjects_bundle();

CREATE TRIGGER trg_pyq_sync
  AFTER INSERT OR UPDATE OR DELETE ON public.pyq
  FOR EACH ROW EXECUTE FUNCTION public.sync_subjects_bundle();

CREATE TRIGGER trg_notes_sync
  AFTER INSERT OR UPDATE OR DELETE ON public.notes
  FOR EACH ROW EXECUTE FUNCTION public.sync_subjects_bundle();

-- 5. Fix RLS policies to reflect new name
DROP POLICY IF EXISTS "Anyone can view department_subjects" ON public.subjects_bundle;
DROP POLICY IF EXISTS "Anyone can insert department_subjects" ON public.subjects_bundle;
DROP POLICY IF EXISTS "Anyone can delete department_subjects" ON public.subjects_bundle;
DROP POLICY IF EXISTS "Anyone can update department_subjects" ON public.subjects_bundle;

CREATE POLICY "Anyone can view subjects_bundle" ON public.subjects_bundle FOR SELECT TO public USING (true);
CREATE POLICY "Anyone can insert subjects_bundle" ON public.subjects_bundle FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Anyone can update subjects_bundle" ON public.subjects_bundle FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Anyone can delete subjects_bundle" ON public.subjects_bundle FOR DELETE TO anon, authenticated USING (true);
