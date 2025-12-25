
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.0.0"
import Stripe from "https://esm.sh/stripe@12.0.0?target=deno"

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
    apiVersion: '2022-11-15',
    httpClient: Stripe.createFetchHttpClient(),
});

const endpointSecret = Deno.env.get('STRIPE_WEBHOOK_SIGNING_SECRET')

serve(async (req) => {
    try {
        const signature = req.headers.get('stripe-signature')

        if (!signature || !endpointSecret) {
            return new Response('Webhook Error: Missing signature or secret', { status: 400 })
        }

        const body = await req.text()
        let event;

        try {
            event = stripe.webhooks.constructEvent(body, signature, endpointSecret);
        } catch (err) {
            return new Response(`Webhook Error: ${err.message}`, { status: 400 });
        }

        // Handle the event
        if (event.type === 'checkout.session.completed') {
            const session = event.data.object;
            // Metadata keys are case-sensitive and should match creation
            const cardRequestId = session.metadata?.request_id || session.metadata?.card_request_id;

            if (cardRequestId) {
                console.log(`Payment success for request: ${cardRequestId}`);

                // Initialize Supabase Admin Client (Service Role)
                const supabaseAdmin = createClient(
                    Deno.env.get('SUPABASE_URL') ?? '',
                    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
                )

                // Call database RPC to handle allocation atomically
                const { error } = await supabaseAdmin
                    .rpc('handle_payment_success', {
                        p_request_id: cardRequestId
                    });

                if (error) {
                    console.error('Database allocation error:', error);
                    // Return 400 to retry webhook? Or 200 to stop loop?
                    // If 400, Stripe retries. If DB error is transient, good.
                    return new Response('Allocation Failed', { status: 500 });
                }
            }
        }

        return new Response(JSON.stringify({ received: true }), { status: 200 })

    } catch (error) {
        return new Response(
            JSON.stringify({ error: error.message }),
            { status: 400 }
        )
    }
})
