-- =====================================================================
-- AUTO-SYNC: user_purchases via Postgres Trigger
-- Run this ONCE in Supabase SQL Editor.
-- After this, user_purchases is updated AUTOMATICALLY on every
-- successful payment — no edge function or Flutter code required.
-- =====================================================================

-- STEP 1: Ensure department column exists
ALTER TABLE public.user_purchases ADD COLUMN IF NOT EXISTS department TEXT;

-- STEP 2: Recreate correct 4-column unique constraint
ALTER TABLE public.user_purchases
  DROP CONSTRAINT IF EXISTS user_purchases_user_id_item_type_item_id_key;
ALTER TABLE public.user_purchases
  DROP CONSTRAINT IF EXISTS user_purchases_user_id_item_type_item_id_dept_key;
ALTER TABLE public.user_purchases
  ADD CONSTRAINT user_purchases_user_id_item_type_item_id_dept_key
  UNIQUE(user_id, item_type, item_id, department);

-- STEP 3: Create the trigger function
-- Fires whenever an order row is updated to status = 'completed'.
-- item_id format: 'unit_CSE_1_Physics_2', 'subject_CSE_1_Physics', 'bundle_CSE_1'
-- → department = split_part(item_id, '_', 2)  →  'CSE'
CREATE OR REPLACE FUNCTION public.sync_user_purchases_on_order_complete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only act when transitioning INTO 'completed'
  IF NEW.status = 'completed'
     AND (OLD.status IS DISTINCT FROM 'completed')
  THEN
    INSERT INTO public.user_purchases (
      user_id,
      item_type,
      item_id,
      order_id,
      department
    )
    VALUES (
      NEW.user_id,
      NEW.item_type,
      NEW.item_id,
      NEW.id,
      split_part(NEW.item_id, '_', 2)
    )
    ON CONFLICT (user_id, item_type, item_id, department) DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;

-- STEP 4: Attach trigger to orders table (drop first to avoid duplicates)
DROP TRIGGER IF EXISTS trg_sync_user_purchases ON public.orders;

CREATE TRIGGER trg_sync_user_purchases
  AFTER UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_user_purchases_on_order_complete();

-- STEP 5: Backfill — sync ALL existing completed orders that are missing from user_purchases
INSERT INTO public.user_purchases (user_id, item_type, item_id, order_id, department)
SELECT
  o.user_id,
  o.item_type,
  o.item_id,
  o.id,
  split_part(o.item_id, '_', 2)
FROM public.orders o
WHERE o.status = 'completed'
ON CONFLICT (user_id, item_type, item_id, department) DO NOTHING;

-- STEP 6: Verify — you should see your purchases here
SELECT
  up.item_type,
  up.item_id,
  up.department,
  o.status AS order_status,
  up.purchase_date
FROM public.user_purchases up
LEFT JOIN public.orders o ON up.order_id = o.id
ORDER BY up.purchase_date DESC;
