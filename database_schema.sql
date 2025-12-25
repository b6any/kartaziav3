-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. USERS
create table if not exists users (
  id uuid references auth.users on delete cascade not null primary key,
  username text,
  avatar_url text,
  xp int default 0,
  level int default 1,
  created_at timestamptz default now()
);

-- 2. CARDS
create table if not exists cards (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  image_url text,
  price decimal(10,2) not null,
  xp_reward int default 0,
  is_active boolean default true,
  category text, -- extra useful field
  description text -- extra useful field
);

-- 3. CODES (Inventory)
create table if not exists codes (
  id uuid default uuid_generate_v4() primary key,
  card_id uuid references cards(id) not null,
  code_value text not null, -- Encrypt in production
  status text default 'available' check (status in ('available', 'used')),
  used_by_request_id uuid, -- Link to request when used
  created_at timestamptz default now()
);

-- 4. CARD REQUESTS (Child Transactions)
create table if not exists card_requests (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references users(id) not null,
  card_id uuid references cards(id) not null,
  status text default 'pending' check (status in ('pending', 'paid', 'delivered', 'expired')),
  allocated_code_id uuid references codes(id),
  created_at timestamptz default now(),
  paid_at timestamptz
);

-- 5. XP TRANSACTIONS
create table if not exists xp_transactions (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references users(id) not null,
  amount int not null,
  reason text,
  created_at timestamptz default now()
);

-- 6. BADGES
create table if not exists badges (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  icon text,
  xp_required int not null
);

-- 7. USER BADGES
create table if not exists user_badges (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references users(id) not null,
  badge_id uuid references badges(id) not null,
  unlocked_at timestamptz default now()
);

-- SECURITY POLICIES (RLS)

-- Users: Read own data
alter table users enable row level security;
create policy "Users can view own profile" on users for select using (auth.uid() = id);
create policy "Users can update own profile" on users for update using (auth.uid() = id);

-- Cards: Public read-only
alter table cards enable row level security;
create policy "Public view active cards" on cards for select using (is_active = true);

-- Requests: Own data only
alter table card_requests enable row level security;
create policy "Users view own requests" on card_requests for select using (auth.uid() = user_id);
create policy "Users create requests" on card_requests for insert with check (auth.uid() = user_id);
-- Allow public (parents) to read basic info of a request via ID (needed for payment page)
-- create policy "Public view request by ID" on card_requests for select using (true); -- BE CAREFUL: Limit columns in real implementation or use a secure edge function

-- Codes: Strictly protected
alter table codes enable row level security;
-- Only reveal code if it's allocated to the user's PAID request
create policy "User view assigned code" on codes for select using (
  exists (
    select 1 from card_requests
    where card_requests.allocated_code_id = codes.id
    and card_requests.user_id = auth.uid()
    and card_requests.status in ('paid', 'delivered')
  )
);

-- FUNCTIONS & TRIGGERS

-- Auto-create User Profile on Auth Signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, username, xp, level)
  values (new.id, new.raw_user_meta_data->>'username', 0, 1);
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- CRITICAL LOGIC: Handle Successful Payment
-- This function should be called by your Payment Webhook (e.g., Stripe)
create or replace function handle_payment_success(p_request_id uuid)
returns void
language plpgsql
security definer -- Runs with admin privileges
as $$
declare
  v_code_id uuid;
  v_card_id uuid;
begin
  -- 1. Get request details
  select card_id into v_card_id from card_requests where id = p_request_id;
  
  if v_card_id is null then
    raise exception 'Request not found';
  end if;

  -- 2. Select ONE available code (Atomic Lock)
  select id into v_code_id
  from codes
  where card_id = v_card_id and status = 'available'
  limit 1
  for update skip locked;
  
  if v_code_id is null then
    -- Handle Out of Stock (Refund logic would go here)
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
  
end;
$$;
