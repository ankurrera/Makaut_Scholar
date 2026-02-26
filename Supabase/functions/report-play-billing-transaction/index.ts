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

        // Verify identity
        const { data: { user }, error: authError } = await supabaseClient.auth.getUser(authHeader.replace('Bearer ', ''));

        if (authError || !user) {
            return new Response(
                JSON.stringify({ error: 'Unauthorized' }),
                { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 }
            );
        }

        const { orderId, razorpayPaymentId, razorpaySignature, externalTransactionToken } = await req.json();

        // 1. Fetch the order - USE EXPLICIT COLUMNS TO AVOID SCHEMA CACHE ISSUES
        let orderData = null;

        const { data: uuidOrder } = await supabaseClient
            .from('orders')
            .select('id, user_id, amount, item_id, item_type, gateway_order_id')
            .eq('id', orderId)
            .maybeSingle();

        if (uuidOrder) {
            orderData = uuidOrder;
        } else {
            const { data: gatewayOrder } = await supabaseClient
                .from('orders')
                .select('id, user_id, amount, item_id, item_type, gateway_order_id')
                .eq('gateway_order_id', orderId)
                .maybeSingle();

            if (gatewayOrder) {
                orderData = gatewayOrder;
            }
        }

        if (!orderData) throw new Error(`Order not found for ID: ${orderId}`);

        // 2. Report to Google Play (ABS) - Placeholder logic
        console.log(`[ABS] Reporting transaction ${razorpayPaymentId} for order ${orderData.id}`);

        // 3. Update order status
        const { error: updateError } = await supabaseClient
            .from('orders')
            .update({
                status: 'completed',
                google_transaction_id: razorpayPaymentId
            })
            .eq('id', orderData.id);

        if (updateError) throw updateError;

        // 4. Delivery (Insert into user_purchases)
        console.log(`[ABS] Unlocking content for user ${user.id}, item ${orderData.item_id}, type ${orderData.item_type}`);

        // Extract department from item_id format:
        //   unit_CSE_1_Physics_2   → CSE
        //   subject_CSE_1_Physics  → CSE
        //   bundle_CSE_1           → CSE
        const parts = (orderData.item_id as string).split('_');
        const department = parts.length > 1 ? parts[1] : null;

        // Use INSERT with ON CONFLICT DO NOTHING since the unique constraint
        // is now (user_id, item_type, item_id, department) — 4 columns.
        const { error: deliveryError } = await supabaseClient
            .from('user_purchases')
            .upsert({
                user_id: user.id,
                item_type: orderData.item_type,
                item_id: orderData.item_id,
                order_id: orderData.id,
                department: department
            }, { onConflict: 'user_id,item_type,item_id,department' });

        if (deliveryError) {
            console.error('Delivery Error:', JSON.stringify(deliveryError));
            throw new Error(`Failed to unlock content: ${deliveryError.message}`);
        }

        return new Response(
            JSON.stringify({ success: true, message: 'Content unlocked successfully' }),
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
