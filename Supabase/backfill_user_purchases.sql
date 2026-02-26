-- =============================================
-- Fix: Backfill user_purchases from completed orders
-- Run this in the Supabase SQL Editor to unlock content
-- for all users who already paid but were not recorded.
-- =============================================

-- 1. Insert into user_purchases for every completed order
--    that is not already in user_purchases.
--    Department is extracted from item_id:
--      unit_CSE_1_Physics_2  → CSE
--      subject_CSE_1_Physics → CSE
--      bundle_CSE_1          → CSE

INSERT INTO public.user_purchases (user_id, item_type, item_id, order_id, department)
SELECT
    o.user_id,
    o.item_type,
    o.item_id,
    o.id AS order_id,
    split_part(o.item_id, '_', 2) AS department
FROM public.orders o
WHERE o.status = 'completed'
ON CONFLICT (user_id, item_type, item_id, department) DO NOTHING;

-- 2. Verify result
SELECT COUNT(*) AS total_purchases FROM public.user_purchases;
SELECT * FROM public.user_purchases ORDER BY created_at DESC LIMIT 10;
