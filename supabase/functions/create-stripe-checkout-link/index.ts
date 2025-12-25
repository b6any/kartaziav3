import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import Stripe from "https://esm.sh/stripe@12.0.0?target=deno"

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
    apiVersion: '2022-11-15',
    httpClient: Stripe.createFetchHttpClient(),
})

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const body = await req.json()
        const requestId = body.requestId || body.card_request_id

        if (!requestId) {
            throw new Error('Missing requestId (or card_request_id)')
        }

        // ✅ استخدم SERVICE ROLE (مهم جدًا)
        const supabase = createClient(
            Deno.env.get('SUPABASE_URL')!,
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
        )

        // 1️⃣ جلب طلب البطاقة
        const { data: request, error: requestError } = await supabase
            .from('card_requests')
            .select('id, card_id, cards ( name, price, image_url )')
            .eq('id', requestId)
            .single()

        if (requestError || !request || !request.cards) {
            throw new Error('Card request not found or card missing')
        }

        const card = request.cards

        // 2️⃣ إنشاء Stripe Session
        const session = await stripe.checkout.sessions.create({
            payment_method_types: ['card'],
            mode: 'payment',
            line_items: [
                {
                    price_data: {
                        currency: 'usd', // أو sar حسب نظامك
                        unit_amount: Math.round(card.price * 100),
                        product_data: {
                            name: card.name,
                            images: card.image_url ? [card.image_url] : [],
                        },
                    },
                    quantity: 1,
                },
            ],
            metadata: {
                card_request_id: requestId,
            },
            success_url: 'https://kartazia.vercel.app/success',
            cancel_url: 'https://kartazia.vercel.app/cancel',
        })

        return new Response(
            JSON.stringify({ url: session.url }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error) {
        console.error('Stripe Function Error:', error)

        return new Response(
            JSON.stringify({ error: error.message }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})
