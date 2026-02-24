-- =============================================
-- Monetization Strategy Schema Updates
-- Run this in the Supabase SQL Editor
-- =============================================

-- 1. Add preview flag to notes table (Tier 1: Free Hook)
ALTER TABLE public.notes 
ADD COLUMN IF NOT EXISTS is_preview BOOLEAN DEFAULT FALSE;

-- 2. Create the semester_bundles table (Tier 3: Semester Access)
CREATE TABLE IF NOT EXISTS public.semester_bundles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  department TEXT NOT NULL,
  semester INT NOT NULL CHECK (semester BETWEEN 1 AND 8),
  bundle_price DECIMAL(10, 2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(department, semester)
);

-- Enable RLS for semester_bundles
ALTER TABLE public.semester_bundles ENABLE ROW LEVEL SECURITY;

-- Anyone can read
DROP POLICY IF EXISTS "Anyone can view semester_bundles" ON public.semester_bundles;
CREATE POLICY "Anyone can view semester_bundles"
ON public.semester_bundles FOR SELECT
TO public
USING (true);

-- Anon and authenticated can insert/update/delete (Admin use)
DROP POLICY IF EXISTS "Anon and authenticated can manage semester_bundles" ON public.semester_bundles;
CREATE POLICY "Anon and authenticated can manage semester_bundles"
ON public.semester_bundles FOR ALL
TO anon, authenticated
USING (true)
WITH CHECK (true);


-- 3. Add pricing info to department_subjects table (Tier 2: Subject Access)
ALTER TABLE public.department_subjects
ADD COLUMN IF NOT EXISTS subject_price DECIMAL(10, 2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS semester_bundle_id UUID REFERENCES public.semester_bundles(id);

-- 4. Create App Settings table for Engagement Thresholds
CREATE TABLE IF NOT EXISTS public.app_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  setting_key TEXT UNIQUE NOT NULL,
  setting_value JSONB NOT NULL,
  description TEXT,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Insert default threshold setting
INSERT INTO public.app_settings (setting_key, setting_value, description)
VALUES ('preview_interactions_threshold', '3', 'Number of interactions before triggering paywall nudge')
ON CONFLICT (setting_key) DO NOTHING;

-- Enable RLS for app_settings
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Anyone can read settings
DROP POLICY IF EXISTS "Anyone can view app_settings" ON public.app_settings;
CREATE POLICY "Anyone can view app_settings"
ON public.app_settings FOR SELECT
TO public
USING (true);

-- Admin can manage settings
DROP POLICY IF EXISTS "Anon and authenticated can manage app_settings" ON public.app_settings;
CREATE POLICY "Anon and authenticated can manage app_settings"
ON public.app_settings FOR ALL
TO anon, authenticated
USING (true)
WITH CHECK (true);
