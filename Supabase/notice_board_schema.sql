-- =================================================================================
-- MAKAUT Notifier: Database Schema
-- Provides tables for Official Notices and FCM Device Tokens
-- =================================================================================

-- 1. Create table for Official Notifications
CREATE TABLE IF NOT EXISTS public.official_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    link TEXT NOT NULL UNIQUE, -- Unique to prevent inserting the same notice twice
    date_posted DATE NOT NULL,
    category TEXT DEFAULT 'General',
    is_new BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Protect Official Notifications (Users can read, only admin/service role can write)
ALTER TABLE public.official_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for all users" 
ON public.official_notifications FOR SELECT 
TO public 
USING (true);

-- (Insert policies are managed by Service Role Key used in the scraper)
CREATE POLICY "Service role can manage notifications" 
ON public.official_notifications 
FOR ALL 
TO service_role 
USING (true) 
WITH CHECK (true);


-- 2. Create table for FCM Device Tokens
CREATE TABLE IF NOT EXISTS public.fcm_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    platform TEXT, -- e.g., 'android', 'ios'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for FCM Tokens
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Users can insert their own tokens
CREATE POLICY "Users can insert their own tokens" 
ON public.fcm_tokens FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

-- Users can read their own tokens
CREATE POLICY "Users can view their own tokens" 
ON public.fcm_tokens FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

-- Users can delete their own tokens (e.g. on logout)
CREATE POLICY "Users can delete their own tokens" 
ON public.fcm_tokens FOR DELETE 
TO authenticated 
USING (auth.uid() = user_id);

-- 3. Trigger to auto-update 'updated_at' column in FCM table
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_fcm_tokens_updated_at
BEFORE UPDATE ON public.fcm_tokens
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
