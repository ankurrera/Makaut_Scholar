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

        // Get user from auth header
        const authHeader = req.headers.get('Authorization')
        if (!authHeader) throw new Error('Missing Authorization header')

        const { data: { user }, error: authError } = await supabaseClient.auth.getUser(authHeader.replace('Bearer ', ''))
        if (authError || !user) throw new Error('Unauthorized')

        const body = await req.json()
        const { itemId, itemType, amount } = body

        if (!itemId || !itemType || !amount) {
            throw new Error('Missing required fields: itemId, itemType, amount')
        }

        // 1. Create a pending order in our database
        // Note: ensure 'orders' table exists with these columns
        const { data: order, error: orderError } = await supabaseClient
            .from('orders')
            .insert({
                user_id: user.id,
                amount: amount,
                item_type: itemType,
                item_id: itemId,
                status: 'pending'
            })
            .select()
            .single()

        if (orderError) throw orderError

        // 2. Call Razorpay API to create order
        const razorpayKey = Deno.env.get('RAZORPAY_KEY_ID')
        const razorpaySecret = Deno.env.get('RAZORPAY_KEY_SECRET')

        if (!razorpayKey || !razorpaySecret) {
            throw new Error('Razorpay keys not configured in environment')
        }

        const razorpayResponse = await fetch('https://api.razorpay.com/v1/orders', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Basic ${btoa(`${razorpayKey}:${razorpaySecret}`)}`,
            },
            body: JSON.stringify({
                amount: Math.round(amount * 100), // in paise
                currency: 'INR',
                receipt: order.id,
                notes: {
                    itemId: itemId,
                    itemType: itemType,
                    userId: user.id
                }
            }),
        })

        const razorpayOrder = await razorpayResponse.json()

        if (razorpayOrder.error) {
            throw new Error(`Razorpay Error: ${razorpayOrder.error.description}`)
        }

        // 3. Update order with Razorpay Order ID
        await supabaseClient
            .from('orders')
            .update({ notes: { ...order.notes, razorpay_order_id: razorpayOrder.id } })
            .eq('id', order.id)

        return new Response(
            JSON.stringify({
                orderId: order.id,
                razorpayOrderId: razorpayOrder.id,
                amount: amount,
                currency: 'INR',
                keyId: razorpayKey
            }),
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
