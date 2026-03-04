-- Update RLS policies to allow management from Admin Panel (using anon/authenticated keys)
-- This ensures the "new row violates RLS" error is resolved.

-- 1. Broaden the management policy to include anon and authenticated roles
DROP POLICY IF EXISTS "Admins can manage mock_test_questions" ON public.mock_test_questions;

CREATE POLICY "Admins can manage mock_test_questions"
ON public.mock_test_questions FOR ALL
TO anon, authenticated, service_role
USING (true)
WITH CHECK (true);

-- 2. Keep the select policy as is (Anyone can view)
-- (Already exists, but ensuring it's robust)
DROP POLICY IF EXISTS "Anyone can view mock_test_questions" ON public.mock_test_questions;
CREATE POLICY "Anyone can view mock_test_questions"
ON public.mock_test_questions FOR SELECT
TO anon, authenticated
USING (true);
