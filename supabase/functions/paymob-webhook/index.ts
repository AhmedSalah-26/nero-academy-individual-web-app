import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const payload = await req.json()
    console.log('📥 Paymob Webhook received:', JSON.stringify(payload, null, 2))

    // Paymob sends different structures, check for transaction data
    const obj = payload.obj || payload
    
    // Extract payment info
    const success = obj.success === true || obj.success === 'true'
    const orderId = obj.order?.merchant_order_id || obj.merchant_order_id
    const transactionId = obj.id || obj.transaction_id
    const amountCents = obj.amount_cents
    
    console.log('💳 Payment Info:', {
      success,
      orderId,
      transactionId,
      amountCents
    })

    if (!orderId) {
      console.error('❌ No order ID found in webhook')
      return new Response(
        JSON.stringify({ 
          error: 'No order ID found',
          received_payload: payload 
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    if (success) {
      console.log('✅ Payment successful, confirming enrollment...')
      
      // Call the confirm_enrollment_payment function
      const { data, error } = await supabaseClient.rpc('confirm_enrollment_payment', {
        p_parent_enrollment_id: orderId,
        p_transaction_id: transactionId?.toString() || 'paymob_success'
      })

      if (error) {
        console.error('❌ Error confirming payment:', error)
        return new Response(
          JSON.stringify({ 
            error: error.message,
            details: error,
            orderId: orderId
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
        )
      }

      console.log('✅ Payment confirmed successfully')
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: 'Payment confirmed',
          orderId: orderId,
          transactionId: transactionId
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    } else {
      console.log('❌ Payment failed, marking as failed...')
      
      // Update parent_enrollment to failed
      const { error } = await supabaseClient
        .from('parent_enrollments')
        .update({
          payment_status: 'failed',
          updated_at: new Date().toISOString()
        })
        .eq('id', orderId)

      if (error) {
        console.error('❌ Error marking payment as failed:', error)
      }

      return new Response(
        JSON.stringify({ 
          success: false, 
          message: 'Payment failed',
          orderId: orderId
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }
  } catch (error) {
    console.error('❌ Webhook error:', error)
    return new Response(
      JSON.stringify({ 
        error: error.message,
        stack: error.stack
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})
