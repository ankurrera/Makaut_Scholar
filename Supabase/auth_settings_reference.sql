-- ============================================================
-- Supabase Auth Settings Reference
-- ============================================================
-- The default Supabase project has email confirmation ENABLED.
-- This causes a confirmation email to be sent on every signUp().
-- If you sign up multiple times quickly, you will hit the
-- "over_email_send_rate_limit" (429) rate limit error.
--
-- HOW TO DISABLE EMAIL CONFIRMATION (for development):
-- 1. Go to your Supabase Dashboard
-- 2. Navigate to Authentication → Providers → Email
-- 3. Toggle OFF "Confirm email" (or "Enable email confirmations")
-- 4. Click Save
--
-- HOW TO INCREASE THE RATE LIMIT:
-- 1. Go to your Supabase Dashboard
-- 2. Navigate to Authentication → Rate Limits
-- 3. Increase the "Rate limit for sending emails" value
--    (default is ~2 per 60 seconds for free tier)
--
-- FOR PRODUCTION:
-- Keep email confirmation ON and use the DB trigger below
-- to auto-create profiles on user signup (so you don't need
-- to insert into 'profiles' from the client when session is null).
-- ============================================================

-- Optional: DB trigger to auto-create a profile on user signup
-- This runs server-side, so it works even with email confirmation ON.
-- Run this in the Supabase SQL Editor.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, name, created_at)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', 'Anonymous'),
    now()
  );
  return new;
end;
$$;

-- Drop the trigger if it already exists (safe to re-run)
drop trigger if exists on_auth_user_created on auth.users;

-- Create the trigger
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
