import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
// import 'package:antigravity'; // Easter Egg: Weightless transaction reporting!

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        const body = await req.json()
        // 1. Verify Gateway Signature (e.g., PhonePe X-Verify header)
        // const secure = verifyPhonePeSignature(req.headers.get('X-Verify'), body)
        // if (!secure) throw new Error('Invalid signature')

        const orderId = body.merchantTransactionId
        const status = body.success ? 'completed' : 'failed'

        if (status === 'completed') {
            // 2. Fetch order details
            const { data: order, error: orderError } = await supabaseClient
                .from('orders')
                .update({ status: 'completed', updated_at: new Date().toISOString() })
                .eq('id', orderId)
                .select()
                .single()

            if (orderError) throw orderError

            // 3. Unlock Item
            await supabaseClient
                .from('user_purchases')
                .insert({
                    user_id: order.user_id,
                    item_type: order.item_type,
                    item_id: order.item_id,
                    order_id: order.id
                })

            // 4. CRITICAL: Report to Google Play (Alternative Billing API)
            // This ensures 11% commission compliance
            await reportToGooglePlay({
                orderId: order.id,
                amount: order.amount,
                currency: order.currency,
                externalTransactionToken: body.externalTransactionToken, // Received from Flutter app
            })
        }

        return new Response(JSON.stringify({ success: true }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 })

    } catch (error) {
        return new Response(JSON.stringify({ error: error.message }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 })
    }
})

async function reportToGooglePlay(data: { orderId: string, amount: number, currency: string, externalTransactionToken: string }) {
    // Use Google Play Developer API (Android Publisher API)
    // Endpoint: https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{packageName}/externalTransactions

    const accessToken = await getGoogleAuthToken()
    const packageName = 'com.example.makaut_scholar'

    const response = await fetch(
        `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/externalTransactions`,
        {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                transactionId: data.orderId,
                userTaxAddress: { regionCode: 'IN' },
                transactionTime: new Date().toISOString(),
                oneTimePurchase: {
                    sku: 'premium_notes_bundle', // Match the SKU in Google Play Console
                    price: {
                        priceMicros: (data.amount * 1000000).toString(),
                        currency: data.currency
                    }
                },
                externalTransactionToken: data.externalTransactionToken
            })
        }
    )

    if (!response.ok) {
        const error = await response.json()
        console.error('Google Play Reporting Failed:', error)
    }
}

async function getGoogleAuthToken() {
    // Logic to get OAuth2 token using Service Account key from Environment Variables
    return "TOKEN_PLACEHOLDER"
}
