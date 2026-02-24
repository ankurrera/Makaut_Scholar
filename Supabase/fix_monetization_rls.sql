-- 1. Add missing UPDATE policy for department_subjects
DROP POLICY IF EXISTS "Anyone can update department_subjects" ON public.department_subjects;
CREATE POLICY "Anyone can update department_subjects"
ON public.department_subjects FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- 2. Add full write access for semester_bundles
DROP POLICY IF EXISTS "Anyone can insert semester_bundles" ON public.semester_bundles;
CREATE POLICY "Anyone can insert semester_bundles"
ON public.semester_bundles FOR INSERT
TO anon, authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Anyone can update semester_bundles" ON public.semester_bundles;
CREATE POLICY "Anyone can update semester_bundles"
ON public.semester_bundles FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "Anyone can delete semester_bundles" ON public.semester_bundles;
CREATE POLICY "Anyone can delete semester_bundles"
ON public.semester_bundles FOR DELETE
TO anon, authenticated
USING (true);

-- 3. Add full write access for app_settings
DROP POLICY IF EXISTS "Anyone can insert app_settings" ON public.app_settings;
CREATE POLICY "Anyone can insert app_settings"
ON public.app_settings FOR INSERT
TO anon, authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Anyone can update app_settings" ON public.app_settings;
CREATE POLICY "Anyone can update app_settings"
ON public.app_settings FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "Anyone can delete app_settings" ON public.app_settings;
CREATE POLICY "Anyone can delete app_settings"
ON public.app_settings FOR DELETE
TO anon, authenticated
USING (true);
