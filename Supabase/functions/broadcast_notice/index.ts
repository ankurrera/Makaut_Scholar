import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { initializeApp, cert } from "npm:firebase-admin/app"
import { getMessaging } from "npm:firebase-admin/messaging"

// --- Configuration ---
// Make sure to add FIREBASE_SERVICE_ACCOUNT to your Supabase Edge Function Secrets
// It should be the full JSON string of the Service Account key.
const serviceAccountStr = Deno.env.get("FIREBASE_SERVICE_ACCOUNT")
if (!serviceAccountStr) {
    console.error("Missing FIREBASE_SERVICE_ACCOUNT environment variable")
}

let firebaseApp;
if (serviceAccountStr) {
    const serviceAccount = JSON.parse(serviceAccountStr)
    firebaseApp = initializeApp({
        credential: cert(serviceAccount)
    })
}

// Initialize Supabase Client to fetch FCM tokens
const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? ""
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
const supabase = createClient(supabaseUrl, supabaseKey)

console.log("Broadcast Notice function initialized (HTTP v1 API)")

serve(async (req) => {
    try {
        if (!firebaseApp) {
            throw new Error("Firebase Admin SDK not initialized. Missing FIREBASE_SERVICE_ACCOUNT.")
        }

        // 1. Parse the incoming Webhook payload from Supabase
        const payload = await req.json()
        console.log("Received Webhook Payload:", JSON.stringify(payload))

        // This webhook should trigger on INSERT to `official_notifications`
        const newNotice = payload.record
        if (!newNotice) {
            return new Response("No record found in payload", { status: 400 })
        }

        const { title, category, link } = newNotice

        // 2. Fetch all unique FCM tokens from the database
        const { data: tokensError, data: tokensData } = await supabase
            .from('fcm_tokens')
            .select('token')

        if (tokensError) {
            console.error("Error fetching tokens:", tokensError)
            throw tokensError
        }

        const tokens = tokensData?.map(t => t.token) || []
        console.log(`Found \${tokens.length} tokens to broadcast to.`)

        if (tokens.length === 0) {
            return new Response("No users to send notifications to.", { status: 200 })
        }

        // 3. Construct the FCM Multicast Payload directly for Firebase Admin 
        const message = {
            notification: {
                title: `📌 New \${category} Notice`,
                body: title,
            },
            data: {
                url: link, // The actual PDF link, so the app can open it directly
            },
            tokens: tokens, // Array of tokens (max 500 per batch in sendEachForMulticast)
        }

        // 4. Send using FCM HTTP v1 Admin SDK
        const response = await getMessaging().sendEachForMulticast(message);

        console.log(`Successfully sent \${response.successCount} messages.`);
        if (response.failureCount > 0) {
            console.error(`Failed to send \${response.failureCount} messages.`);
            // Optional: Handle token cleanup here if tokens are unregistered (error.code === 'messaging/registration-token-not-registered')
        }

        return new Response(JSON.stringify({
            success: true,
            successCount: response.successCount,
            failureCount: response.failureCount
        }), {
            headers: { "Content-Type": "application/json" },
            status: 200,
        })

    } catch (error) {
        console.error("Function Error:", error)
        return new Response(JSON.stringify({ error: error.message }), {
            headers: { "Content-Type": "application/json" },
            status: 500,
        })
    }
})
