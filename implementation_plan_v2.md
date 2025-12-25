# Kartazia Payment & Allocation Implementation Plan

## 1. Supabase Edge Functions

### `create-stripe-checkout-link`
- **Purpose**: Generates a Stripe Checkout Session for a specific Card Request.
- **Input**: `{ card_request_id: string, card_id: string }`
- **Logic**:
  1. Fetch `cards` table to get the REAL price using `service_role` (trust no client input).
  2. Create Stripe Checkout Session:
     - `payment_method_types`: ['card']
     - `mode`: 'payment'
     - `line_items`: [{ price_data: { currency: 'usd', product_data: { name: card.name }, unit_amount: card.price * 100 }, quantity: 1 }]
     - `metadata`: { `card_request_id`: input.card_request_id } (CRITICAL)
     - `success_url`: `https://kartazia.app/success` (Dummy)
     - `cancel_url`: `https://kartazia.app/cancel` (Dummy)
- **Output**: `{ url: string }`

### `stripe-webhook`
- **Purpose**: Handles `checkout.session.completed` event to allocate codes.
- **Logic**:
  1. Validates Stripe Signature.
  2. Extracts `card_request_id` from metadata.
  3. Calls Postgres RPC `handle_payment_success(card_request_id)`.
  4. Returns 200 OK.

## 2. Flutter Integration

### `CardsRepository`
- Add `getCheckoutUrl(String requestId, String cardId)`:
  - Calls `supabase.functions.invoke('create-stripe-checkout-link', body: { ... })`.

### `CardsPage` (Request Flow)
- On "Request Card" tap:
  1. `CardsRepository.createRequest(card.id)` -> Returns `CardRequestModel`.
  2. `CardsRepository.getCheckoutUrl(req.id, card.id)` -> Returns `url`.
  3. Launch WhatsApp: `https://wa.me/?text=Hi Mom! Please buy me this card: <url>`

### `MyCardsPage` (Share Flow)
- On "Share via WhatsApp" tap:
  1. Find the most recent `pending` request from the list.
  2. Re-fetch checkout URL (Generate new session to ensure valid link).
  3. Launch WhatsApp.

## 3. Database Updates
- Ensure `handle_payment_success` function is present (Verified in schema).
