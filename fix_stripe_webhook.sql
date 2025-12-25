-- Fix Stripe Webhook Logic
-- 1. Updates card_requests status to 'paid'
-- 2. Selects oldest available code
-- 3. Marks code as used
-- 4. Allocates code to request (via allocated_code_id)

create or replace function handle_payment_success(p_request_id uuid)
returns void
language plpgsql
security definer
as $$
declare
  v_request_status text;
  v_code_id uuid;
  v_card_id uuid;
begin
  -- 1. Get request details and lock the row
  select status, card_id into v_request_status, v_card_id
  from card_requests
  where id = p_request_id
  for update;

  if v_request_status is null then
    raise exception 'Request not found';
  end if;

  -- Idempotency check: If already paid, do nothing
  if v_request_status = 'paid' then
    return;
  end if;

  -- 2. Select OLDEST available code
  select id into v_code_id
  from codes
  where card_id = v_card_id and status = 'available'
  order by created_at asc
  limit 1
  for update skip locked;

  if v_code_id is null then
    raise exception 'Out of Stock';
  end if;

  -- 3. Mark code as used
  update codes
  set status = 'used',
      used_by_request_id = p_request_id
  where id = v_code_id;

  -- 4. Mark request as paid & allocate code
  update card_requests
  set status = 'paid',
      paid_at = now(),
      allocated_code_id = v_code_id
  where id = p_request_id;
  
  -- Note: card_requests.code_value column does not exist in the current schema.
  -- The app retrieves the code via the relation allocated_code_id -> codes.code_value.
  
end;
$$;
