-- Add the missing UPDATE policy for the notes table
-- This allows the Admin Panel to update price and premium status
DROP POLICY IF EXISTS "Anon and authenticated can update notes" ON public.notes;
CREATE POLICY "Anon and authenticated can update notes"
ON public.notes FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- Verify other tables as well (just in case)
DROP POLICY IF EXISTS "Anyone can update pyq" ON public.pyq;
CREATE POLICY "Anyone can update pyq"
ON public.pyq FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "Anyone can update important_questions" ON public.important_questions;
CREATE POLICY "Anyone can update important_questions"
ON public.important_questions FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);
