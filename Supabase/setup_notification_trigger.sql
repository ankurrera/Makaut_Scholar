-- =====================================================================
-- PUSH NOTIFICATIONS: official_notifications -> broadcast_notice
-- Run this in the Supabase SQL Editor.
-- This creates a trigger that calls your Edge Function automatically
-- whenever a new notice is published from the Admin Panel.
-- =====================================================================

-- 1. Enable the 'pg_net' extension to allow HTTP requests from Postgres
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Create the trigger function
CREATE OR REPLACE FUNCTION public.trg_func_broadcast_notice()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Perform an asynchronous POST request to the Edge Function
  -- We include the record in the payload so the function knows what notice was added
  PERFORM
    net.http_post(
      url := 'https://nikvdsulxvinkvxstxol.supabase.co/functions/v1/broadcast_notice',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
      ),
      body := jsonb_build_object(
        'record', row_to_json(NEW)
      )
    );
  RETURN NEW;
END;
$$;

-- 3. Attach the trigger to the official_notifications table
DROP TRIGGER IF EXISTS trg_broadcast_notice ON public.official_notifications;
CREATE TRIGGER trg_broadcast_notice
  AFTER INSERT ON public.official_notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_func_broadcast_notice();

-- NOTE: If current_setting('app.settings.service_role_key') fails, 
-- you might need to hardcode the Service Role Key or set it in the DB settings.
-- Alternatively, set up the Webhook via the Supabase Dashboard UI:
-- 1. Database -> Webhooks -> Create New
-- 2. Table: official_notifications, Events: Insert
-- 3. Action: Call Edge Function -> broadcast_notice
