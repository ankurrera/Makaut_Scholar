-- =============================================
-- Pricing Tiers Setup + Reset
-- Run this ONCE in Supabase SQL Editor
-- =============================================

-- 1. Create the canonical pricing_tiers table
CREATE TABLE IF NOT EXISTS public.pricing_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  price DECIMAL(10, 2) NOT NULL UNIQUE
);

-- Safely add columns (handles case where table already existed without them)
ALTER TABLE public.pricing_tiers ADD COLUMN IF NOT EXISTS product_id TEXT;
ALTER TABLE public.pricing_tiers ADD COLUMN IF NOT EXISTS label TEXT;
ALTER TABLE public.pricing_tiers ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 0;

-- Add unique constraint on product_id if not already there
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'pricing_tiers_product_id_key'
  ) THEN
    ALTER TABLE public.pricing_tiers ADD CONSTRAINT pricing_tiers_product_id_key UNIQUE (product_id);
  END IF;
END $$;

-- RLS (public read)
ALTER TABLE public.pricing_tiers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view pricing_tiers" ON public.pricing_tiers;
CREATE POLICY "Anyone can view pricing_tiers"
  ON public.pricing_tiers FOR SELECT TO public USING (true);

-- Drop NOT NULL on all pre-existing columns (safe — we use product_id + label instead)
ALTER TABLE public.pricing_tiers ALTER COLUMN tier_name      DROP NOT NULL;
ALTER TABLE public.pricing_tiers ALTER COLUMN google_play_sku DROP NOT NULL;

-- 2. Seed the 7 canonical tiers (clean replace)
DELETE FROM public.pricing_tiers;
INSERT INTO public.pricing_tiers (price, product_id, google_play_sku, label, tier_name, sort_order) VALUES
  (49.00,  'scholar_price_49',  'scholar_price_49',  '₹49',  'Tier 49',  1),
  (99.00,  'scholar_price_99',  'scholar_price_99',  '₹99',  'Tier 99',  2),
  (129.00, 'scholar_price_129', 'scholar_price_129', '₹129', 'Tier 129', 3),
  (149.00, 'scholar_price_149', 'scholar_price_149', '₹149', 'Tier 149', 4),
  (199.00, 'scholar_price_199', 'scholar_price_199', '₹199', 'Tier 199', 5),
  (399.00, 'scholar_price_399', 'scholar_price_399', '₹399', 'Tier 399', 6),
  (699.00, 'scholar_price_699', 'scholar_price_699', '₹699', 'Tier 699', 7);


-- =============================================
-- 3. RESET pre-seeded prices (start clean)
-- =============================================

-- Must NULL the FK first before deleting semester_bundles
UPDATE public.department_subjects
SET semester_bundle_id = NULL,
    subject_price = 0.00;

-- Now safe to delete bundles
DELETE FROM public.semester_bundles;

-- Clear unit prices
DELETE FROM public.unit_prices;


-- =============================================
-- VERIFY
-- =============================================
SELECT price, product_id, label FROM public.pricing_tiers ORDER BY sort_order;
