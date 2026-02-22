// @ts-nocheck
import { serve } from "std/http/server.ts"
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
    const authHeader = req.headers.get('Authorization')!
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(authHeader.replace('Bearer ', ''))

    if (authError || !user) throw new Error('Unauthorized')

    const { itemId, itemType, amount, paymentMethod } = await req.json()

    // 1. Create a pending order in our database
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

    // 2. Integration with Payment Gateway (e.g., PhonePe)
    // For PhonePe, we generate a transaction request and get a deep link
    // This is a placeholder for the actual API call logic

    /* 
    const payload = {
      merchantId: Deno.env.get('PHONEPE_MERCHANT_ID'),
      merchantTransactionId: order.id,
      amount: amount * 100, // in paise
      callbackUrl: `${Deno.env.get('SUPABASE_URL')}/functions/v1/payment-webhook`,
      // ... other required fields
    }
    */

    // Simulate getting a UPI Intent URL from gateway
    const upiIntentUrl = `upi://pay?pa=merchant@upi&pn=MAKAUT_Scholar&tr=${order.id}&am=${amount}&cu=INR&tn=Premium_${itemId}`

    return new Response(
      JSON.stringify({
        orderId: order.id,
        upiIntentUrl: upiIntentUrl
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
