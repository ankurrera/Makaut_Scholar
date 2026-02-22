// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
        const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

        const authHeader = req.headers.get('Authorization');
        if (!authHeader) throw new Error('Missing Authorization header');

        const supabaseClient = createClient(supabaseUrl, supabaseServiceKey);

        const { data: { user }, error: authError } = await supabaseClient.auth.getUser(authHeader.replace('Bearer ', ''));

        if (authError || !user) {
            return new Response(
                JSON.stringify({ error: 'Unauthorized' }),
                { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 }
            );
        }

        const { itemId, itemType, amount } = await req.json();

        if (!itemId || !itemType || !amount) {
            throw new Error('Missing required fields');
        }

        // 1. Create a pending order - USE EXPLICIT COLUMNS
        const { data: order, error: orderError } = await supabaseClient
            .from('orders')
            .insert({
                user_id: user.id,
                amount: amount,
                item_type: itemType,
                item_id: itemId,
                status: 'pending'
            })
            .select('id, user_id, amount, item_id, item_type')
            .single();

        if (orderError) {
            console.error('Order Creation Error:', orderError);
            throw orderError;
        }

        // 2. Call Razorpay API
        const razorpayKey = Deno.env.get('RAZORPAY_KEY_ID');
        const razorpaySecret = Deno.env.get('RAZORPAY_KEY_SECRET');

        const razorpayResponse = await fetch('https://api.razorpay.com/v1/orders', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Basic ${btoa(`${razorpayKey}:${razorpaySecret}`)}`,
            },
            body: JSON.stringify({
                amount: Math.round(amount * 100),
                currency: 'INR',
                receipt: order.id,
            }),
        });

        const razorpayOrder = await razorpayResponse.json();

        if (razorpayOrder.error) {
            throw new Error(`Razorpay Error: ${razorpayOrder.error.description}`);
        }

        // 3. Update order with Razorpay Order ID
        const { error: updateError } = await supabaseClient
            .from('orders')
            .update({ gateway_order_id: razorpayOrder.id })
            .eq('id', order.id);

        if (updateError) console.error('Order Update Error:', updateError);

        return new Response(
            JSON.stringify({
                orderId: order.id,
                razorpayOrderId: razorpayOrder.id,
                amount: amount,
                currency: 'INR',
                keyId: razorpayKey
            }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
        );

    } catch (error) {
        console.error(error);
        return new Response(
            JSON.stringify({ error: (error as Error).message }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
        );
    }
})
