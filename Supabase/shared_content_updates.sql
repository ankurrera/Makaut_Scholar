-- =================================================================
-- SHARED CONTENT & DEPARTMENT-LOCKED ACCESS UPDATES
-- =================================================================

-- 1. Add paper_code to content tables
ALTER TABLE public.pyq ADD COLUMN IF NOT EXISTS paper_code TEXT;
ALTER TABLE public.notes ADD COLUMN IF NOT EXISTS paper_code TEXT;
ALTER TABLE public.important_questions ADD COLUMN IF NOT EXISTS paper_code TEXT;

-- 2. Update department_subjects to include paper_code
ALTER TABLE public.department_subjects ADD COLUMN IF NOT EXISTS paper_code TEXT;

-- 3. Update sync_department_subjects trigger function
CREATE OR REPLACE FUNCTION public.sync_department_subjects()
RETURNS TRIGGER AS $$
BEGIN
  -- Handle Insertion or Update of subject
  IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE' AND (NEW.subject <> OLD.subject OR NEW.semester <> OLD.semester OR NEW.department <> OLD.department OR NEW.paper_code <> OLD.paper_code)) THEN
    INSERT INTO public.department_subjects (department, semester, subject, paper_code, source)
    VALUES (NEW.department, NEW.semester, NEW.subject, NEW.paper_code, TG_TABLE_NAME)
    ON CONFLICT (department, semester, subject) 
    DO UPDATE SET 
      paper_code = EXCLUDED.paper_code,
      source = EXCLUDED.source;
  END IF;

  -- Handle Removal of OLD subject
  IF (TG_OP = 'DELETE') OR (TG_OP = 'UPDATE' AND (NEW.subject <> OLD.subject OR NEW.semester <> OLD.semester OR NEW.department <> OLD.department)) THEN
    IF NOT EXISTS (SELECT 1 FROM public.syllabus WHERE department = OLD.department AND semester = OLD.semester AND subject = OLD.subject)
       AND NOT EXISTS (SELECT 1 FROM public.pyq WHERE department = OLD.department AND semester = OLD.semester AND subject = OLD.subject)
       AND NOT EXISTS (SELECT 1 FROM public.notes WHERE department = OLD.department AND semester = OLD.semester AND subject = OLD.subject)
       AND NOT EXISTS (SELECT 1 FROM public.important_questions WHERE department = OLD.department AND semester = OLD.semester AND subject = OLD.subject)
    THEN
      DELETE FROM public.department_subjects 
      WHERE department = OLD.department AND semester = OLD.semester AND subject = OLD.subject;
    END IF;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 4. Attach trigger to important_questions (if not already attached)
DROP TRIGGER IF EXISTS trg_important_questions_sync ON public.important_questions;
CREATE TRIGGER trg_important_questions_sync
  AFTER INSERT OR UPDATE OR DELETE ON public.important_questions
  FOR EACH ROW EXECUTE FUNCTION public.sync_department_subjects();

-- 5. Update user_purchases for department locking
-- Add department column if it doesn't exist
ALTER TABLE public.user_purchases ADD COLUMN IF NOT EXISTS department TEXT;

-- Note: In a real scenario, we might need to backfill 'department' for existing purchases 
-- from the user's profile at the time of migration.

-- Update unique constraint to include department
-- First drop existing constraint if it exists (might need to check name)
ALTER TABLE public.user_purchases DROP CONSTRAINT IF EXISTS user_purchases_user_id_item_type_item_id_key;
ALTER TABLE public.user_purchases ADD CONSTRAINT user_purchases_user_id_item_type_item_id_dept_key UNIQUE(user_id, item_type, item_id, department);

-- 6. Update has_premium_access function
CREATE OR REPLACE FUNCTION public.has_premium_access(
    target_user_id UUID, 
    target_item_type TEXT, 
    target_item_id TEXT,
    target_department TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_purchases
        WHERE user_id = target_user_id
        AND item_type = target_item_type
        AND item_id = target_item_id
        AND (target_department IS NULL OR department = target_department)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
