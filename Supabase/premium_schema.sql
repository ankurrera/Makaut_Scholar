-- Create table for tracking orders
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    currency TEXT DEFAULT 'INR',
    status TEXT DEFAULT 'pending', -- pending, completed, failed
    gateway_order_id TEXT UNIQUE, -- PhonePe/Razorpay Order ID
    google_transaction_id TEXT, -- For Google Play reporting
    item_type TEXT NOT NULL, -- 'notes', 'questions', 'premium_access'
    item_id TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create table for unlocked premium items
CREATE TABLE IF NOT EXISTS public.user_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    item_type TEXT NOT NULL,
    item_id TEXT NOT NULL,
    order_id UUID REFERENCES public.orders(id),
    purchase_date TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, item_type, item_id)
);

-- Enable RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_purchases ENABLE ROW LEVEL SECURITY;

-- RLS Policies for orders
CREATE POLICY "Users can view their own orders"
    ON public.orders FOR SELECT
    USING (auth.uid() = user_id);

-- RLS Policies for user_purchases
CREATE POLICY "Users can view their own purchases"
    ON public.user_purchases FOR SELECT
    USING (auth.uid() = user_id);

-- Simple function to check if user has access to an item
CREATE OR REPLACE FUNCTION has_premium_access(target_user_id UUID, target_item_type TEXT, target_item_id TEXT)
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
