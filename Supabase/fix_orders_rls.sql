-- =============================================
-- Fix: Orders Table RLS & Schema for Price-Point Tiers
-- Run this in the Supabase SQL Editor
-- =============================================

-- 1. Allow authenticated users to INSERT their own orders
--    (The service-role key in Edge Functions bypasses this, but the anon key path needs it)
DROP POLICY IF EXISTS "Users can insert their own orders" ON public.orders;
CREATE POLICY "Users can insert their own orders"
ON public.orders FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- 2. Add a 'gateway' column to track which payment method was used
ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS gateway TEXT DEFAULT 'razorpay'; -- 'razorpay' | 'google_play'

-- 3. Update the has_premium_access function to also accept a 4th param (department)
--    This version already exists in your live DB from earlier work, but just ensure it's current:
CREATE OR REPLACE FUNCTION has_premium_access(
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
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
