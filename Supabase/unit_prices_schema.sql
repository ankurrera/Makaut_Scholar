-- =============================================
-- Unit-Level Pricing Schema
-- Run this in the Supabase SQL Editor
-- =============================================

-- 1. Create unit_prices table (Tier 2 pricing: per-unit access)
CREATE TABLE IF NOT EXISTS public.unit_prices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  department TEXT NOT NULL,
  semester INT NOT NULL CHECK (semester BETWEEN 1 AND 8),
  subject TEXT NOT NULL,
  unit INT NOT NULL CHECK (unit BETWEEN 1 AND 6),
  price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(department, semester, subject, unit)
);

-- 2. Enable RLS
ALTER TABLE public.unit_prices ENABLE ROW LEVEL SECURITY;

-- 3. Anyone can read unit prices (for app display)
DROP POLICY IF EXISTS "Anyone can view unit_prices" ON public.unit_prices;
CREATE POLICY "Anyone can view unit_prices"
ON public.unit_prices FOR SELECT
TO public
USING (true);

-- 4. Admin (anon key) can manage unit prices
DROP POLICY IF EXISTS "Admin can manage unit_prices" ON public.unit_prices;
CREATE POLICY "Admin can manage unit_prices"
ON public.unit_prices FOR ALL
TO anon, authenticated
USING (true)
WITH CHECK (true);
