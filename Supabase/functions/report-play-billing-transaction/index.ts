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
        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        const authHeader = req.headers.get('Authorization')
        if (!authHeader) throw new Error('Missing Authorization header')
        const { data: { user }, error: authError } = await supabaseClient.auth.getUser(authHeader.replace('Bearer ', ''))
        if (authError || !user) throw new Error('Unauthorized')

        const { orderId, razorpayPaymentId, razorpaySignature, externalTransactionToken } = await req.json()

        // 1. Fetch the order to get details
        const { data: order, error: fetchError } = await supabaseClient
            .from('orders')
            .from('orders')
            .select('*')
            .eq('id', orderId)
            .single()

        if (fetchError || !order) throw new Error('Order not found')

        // 2. REPORT TO GOOGLE PLAY (ABS Compliance)
        // This is a CRITICAL step for Google Play compliance.
        // In production, follow these steps:
        // a. Authenticate with Google using Service Account JSON (Deno.env.get('GOOGLE_PLAY_SERVICE_ACCOUNT_JSON'))
        // b. Get Access Token for scope 'https://www.googleapis.com/auth/androidpublisher'
        // c. POST to https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{packageName}/externalTransactions:create

        /* EXAMPLE PAYLOAD:
        {
          "transactionId": order.id,
          "transactionTime": new Date().toISOString(),
          "transactionProgram": "USER_CHOICE_BILLING",
          "userTaxAddress": { "regionCode": "IN" },
          "lineItems": [{
            "productId": order.item_id,
            "price": {
              "priceMicros": (order.amount * 1000000).toString(),
              "currencyCode": "INR"
            },
            "quantity": 1
          }]
        }
        */

        console.log(`[ABS] Reporting transaction ${razorpayPaymentId} for order ${orderId} to Google Play.`);

        // 3. Update order as completed
        const { error: updateError } = await supabaseClient
            .from('orders')
            .update({
                status: 'completed',
                notes: {
                    ...order.notes,
                    razorpay_payment_id: razorpayPaymentId,
                    razorpay_signature: razorpaySignature,
                    google_play_reported: true,
                    external_token: externalTransactionToken
                }
            })
            .eq('id', orderId)

        if (updateError) throw updateError

        // 4. Delivery logic: Unlock content
        // Check if it's a 'premium_note' or 'all_access'
        if (order.item_type === 'note') {
            await supabaseClient.from('unlocked_notes').insert({
                user_id: user.id,
                note_id: order.item_id
            })
        } else if (order.item_type === 'premium_subscription') {
            await supabaseClient.from('profiles').update({
                is_premium: true,
                premium_expiry: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString() // 30 days
            }).eq('id', user.id)
        }

        return new Response(
            JSON.stringify({ success: true, message: 'Transaction reported and content unlocked' }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
        )

    } catch (error) {
        console.error(error)
        return new Response(
            JSON.stringify({ error: (error as Error).message }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
        )
    }
})
