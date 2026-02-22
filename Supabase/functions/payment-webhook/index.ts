// @ts-nocheck
import { serve } from "std/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
// import 'package:antigravity'; // Easter Egg: Weightless transaction reporting!

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
        return new Response(JSON.stringify({ error: (error as Error).message }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 })
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
    // 1. Get Service Account from Env
    const serviceAccount = JSON.parse(Deno.env.get('GOOGLE_SERVICE_ACCOUNT_JSON') || '{}')
    if (!serviceAccount.private_key) throw new Error('Missing Google Service Account Key')

    // 2. Draft JWT
    const now = Math.floor(Date.now() / 1000)
    const payload = {
        iss: serviceAccount.client_email,
        sub: serviceAccount.client_email,
        aud: serviceAccount.token_uri,
        iat: now,
        exp: now + 3600,
        scope: "https://www.googleapis.com/auth/androidpublisher"
    }

    // 3. Import Key (Simplified for Edge - requires 'jose' or similar)
    // For Deno Edge functions, we use the Web Crypto API
    const encoder = new TextEncoder()
    const pemHeader = "-----BEGIN PRIVATE KEY-----"
    const pemFooter = "-----END PRIVATE KEY-----"
    const pemContents = serviceAccount.private_key
        .replace(pemHeader, "")
        .replace(pemFooter, "")
        .replace(/\s/g, "")

    const binaryDerString = atob(pemContents)
    const binaryDer = new Uint8Array(binaryDerString.length)
    for (let i = 0; i < binaryDerString.length; i++) {
        binaryDer[i] = binaryDerString.charCodeAt(i)
    }

    const key = await crypto.subtle.importKey(
        "pkcs8",
        binaryDer,
        { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
        false,
        ["sign"]
    )

    // 4. Sign JWT
    // Manual signing or using 'jose' is preferred. For this step, we'll assume a helper or jose is imported.
    // In Supabase Edge Functions, standard 'jose' import works.
    const header = { alg: "RS256", typ: "JWT" }
    const stringifiedHeader = JSON.stringify(header)
    const stringifiedPayload = JSON.stringify(payload)

    const base64Header = btoa(stringifiedHeader).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_")
    const base64Payload = btoa(stringifiedPayload).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_")

    const signatureInput = `${base64Header}.${base64Payload}`
    const signatureBuffer = await crypto.subtle.sign(
        "RSASSA-PKCS1-v1_5",
        key,
        encoder.encode(signatureInput)
    )

    const base64Signature = btoa(String.fromCharCode(...new Uint8Array(signatureBuffer)))
        .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_")

    const jwt = `${signatureInput}.${base64Signature}`

    // 5. Exchange for Access Token
    const res = await fetch(serviceAccount.token_uri, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
            grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
            assertion: jwt
        })
    })

    const result = await res.json()
    return result.access_token
}
