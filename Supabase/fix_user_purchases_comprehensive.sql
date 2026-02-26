-- =============================================
-- COMPREHENSIVE FIX: user_purchases & access
-- Run this ENTIRE script in Supabase SQL Editor
-- =============================================

-- 1. Ensure the department column exists
ALTER TABLE public.user_purchases ADD COLUMN IF NOT EXISTS department TEXT;

-- 2. Fix the unique constraint to handle both old (3-col) and new (4-col) schemas.
--    Drop both possible variants and recreate the correct 4-column one.
ALTER TABLE public.user_purchases 
  DROP CONSTRAINT IF EXISTS user_purchases_user_id_item_type_item_id_key;
ALTER TABLE public.user_purchases 
  DROP CONSTRAINT IF EXISTS user_purchases_user_id_item_type_item_id_dept_key;
ALTER TABLE public.user_purchases 
  ADD CONSTRAINT user_purchases_user_id_item_type_item_id_dept_key 
  UNIQUE(user_id, item_type, item_id, department);

-- 3. Backfill user_purchases from ALL completed orders (covers your existing payment)
INSERT INTO public.user_purchases (user_id, item_type, item_id, order_id, department)
SELECT
    o.user_id,
    o.item_type,
    o.item_id,
    o.id,
    split_part(o.item_id, '_', 2)  -- extracts dept: 'unit_CSE_1_X_1' → 'CSE'
FROM public.orders o
WHERE o.status = 'completed'
ON CONFLICT (user_id, item_type, item_id, department) DO NOTHING;

-- 4. Make sure RLS allows users to SELECT their own purchases
DROP POLICY IF EXISTS "Users can view their own purchases" ON public.user_purchases;
CREATE POLICY "Users can view their own purchases"
    ON public.user_purchases FOR SELECT
    USING (auth.uid() = user_id);

-- 5. Verify result -- you should see your purchase here
SELECT up.*, o.status AS order_status
FROM public.user_purchases up
LEFT JOIN public.orders o ON up.order_id = o.id
ORDER BY up.purchase_date DESC
LIMIT 20;
