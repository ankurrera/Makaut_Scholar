-- =================================================================
-- YOUTUBE PLAYLISTS SCHEMA
-- =================================================================

-- 1. Create the table
CREATE TABLE IF NOT EXISTS public.youtube_playlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department TEXT NOT NULL,
    semester INTEGER NOT NULL,
    subject TEXT NOT NULL,
    paper_code TEXT,
    title TEXT NOT NULL,
    channel_name TEXT NOT NULL,
    playlist_url TEXT NOT NULL,
    thumbnail_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Add an index for faster lookups based on department, semester, and subject
CREATE INDEX IF NOT EXISTS idx_youtube_playlists_dept_sem_sub 
ON public.youtube_playlists (department, semester, subject);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.youtube_playlists ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS Policies

DROP POLICY IF EXISTS "Anyone can view youtube playlists" ON public.youtube_playlists;
DROP POLICY IF EXISTS "Authenticated users can insert youtube playlists" ON public.youtube_playlists;
DROP POLICY IF EXISTS "Authenticated users can update youtube playlists" ON public.youtube_playlists;
DROP POLICY IF EXISTS "Authenticated users can delete youtube playlists" ON public.youtube_playlists;
DROP POLICY IF EXISTS "Users can insert youtube playlists" ON public.youtube_playlists;
DROP POLICY IF EXISTS "Users can update youtube playlists" ON public.youtube_playlists;
DROP POLICY IF EXISTS "Users can delete youtube playlists" ON public.youtube_playlists;
DROP POLICY IF EXISTS "Anon can view youtube playlists" ON public.youtube_playlists;

-- Everyone can view youtube playlists
CREATE POLICY "Anyone can view youtube playlists"
    ON public.youtube_playlists
    FOR SELECT
    TO public
    USING (true);

-- Allow both anon (admin portal) and authenticated (app users if testing) to insert/update/delete
CREATE POLICY "Users can insert youtube playlists"
    ON public.youtube_playlists
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

CREATE POLICY "Users can update youtube playlists"
    ON public.youtube_playlists
    FOR UPDATE
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Users can delete youtube playlists"
    ON public.youtube_playlists
    FOR DELETE
    TO anon, authenticated
    USING (true);

-- Optional: Since the admin portal currently might use service_role, these policies
-- primarily protect normal web/app clients from mutating.

-- 5. Attach the trigger to keep `subjects_bundle` updated so the subject 
-- appears in the subject selection screen even if NO pyq/notes exist.
CREATE OR REPLACE FUNCTION public.sync_subjects_bundle_youtube()
RETURNS TRIGGER AS $$
BEGIN
  -- Handle Insertion
  IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE' AND (NEW.subject <> OLD.subject OR NEW.semester <> OLD.semester OR NEW.department <> OLD.department OR COALESCE(NEW.paper_code, '') <> COALESCE(OLD.paper_code, ''))) THEN
    INSERT INTO public.subjects_bundle (department, semester, subject, paper_code, source)
    VALUES (NEW.department, NEW.semester, NEW.subject, NEW.paper_code, TG_TABLE_NAME)
    ON CONFLICT (department, semester, subject) 
    DO UPDATE SET 
      paper_code = EXCLUDED.paper_code,
      source = EXCLUDED.source;
  END IF;

  -- Handle Removal
  IF (TG_OP = 'DELETE') OR (TG_OP = 'UPDATE' AND (NEW.subject <> OLD.subject OR NEW.semester <> OLD.semester OR NEW.department <> OLD.department)) THEN
    IF NOT EXISTS (SELECT 1 FROM public.syllabus WHERE department = OLD.department AND semester = OLD.semester AND subject = OLD.subject)
       AND NOT EXISTS (SELECT 1 FROM public.pyq WHERE department = OLD.department AND semester = OLD.semester AND subject = OLD.subject)
       AND NOT EXISTS (SELECT 1 FROM public.notes WHERE department = OLD.department AND semester = OLD.semester AND subject = OLD.subject)
       AND NOT EXISTS (SELECT 1 FROM public.important_questions WHERE department = OLD.department AND semester = OLD.semester AND subject = OLD.subject)
       AND NOT EXISTS (SELECT 1 FROM public.youtube_playlists WHERE department = OLD.department AND semester = OLD.semester AND subject = OLD.subject)
    THEN
      DELETE FROM public.subjects_bundle 
      WHERE department = OLD.department AND semester = OLD.semester AND subject = OLD.subject;
    END IF;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Attach the trigger
-- First drop if exists in case we are re-running
DROP TRIGGER IF EXISTS trg_youtube_playlists_sync ON public.youtube_playlists;

CREATE TRIGGER trg_youtube_playlists_sync
  AFTER INSERT OR UPDATE OR DELETE ON public.youtube_playlists
  FOR EACH ROW EXECUTE FUNCTION public.sync_subjects_bundle_youtube();
