-- 1. Avatars Table
create table if not exists avatars (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  image_url text not null,
  xp_cost int default 0,
  rarity text default 'common',
  is_active boolean default true,
  is_free boolean default false,
  created_at timestamptz default now()
);

-- 2. User Avatars (Ownership)
create table if not exists avatars_users (
  user_id uuid references users(id) on delete cascade not null,
  avatar_id uuid references avatars(id) on delete cascade not null,
  equipped boolean default false,
  purchased_at timestamptz default now(),
  primary key (user_id, avatar_id)
);

-- RLS Policies
alter table avatars enable row level security;
create policy "Public view active avatars" on avatars for select using (is_active = true);

alter table avatars_users enable row level security;
create policy "Users view own avatars" on avatars_users for select using (auth.uid() = user_id);
create policy "Users insert own avatars" on avatars_users for insert with check (auth.uid() = user_id);
create policy "Users update own avatars" on avatars_users for update using (auth.uid() = user_id);

-- RPC: Purchase Avatar
create or replace function purchase_avatar(p_avatar_id uuid, p_cost int)
returns void
language plpgsql
security definer
as $$
declare
  v_user_id uuid := auth.uid();
  v_user_xp int;
begin
  -- 1. Check User XP
  select xp into v_user_xp from users where id = v_user_id;
  
  if v_user_xp < p_cost then
    raise exception 'Insufficient XP';
  end if;

  -- 2. Deduct XP
  update users 
  set xp = xp - p_cost 
  where id = v_user_id;

  -- 3. Add to Inventory
  insert into avatars_users (user_id, avatar_id, equipped)
  values (v_user_id, p_avatar_id, false);

  -- 4. Record Transaction
  insert into xp_transactions (user_id, amount, reason)
  values (v_user_id, -p_cost, 'Purchased Avatar');

end;
$$;

-- RPC: Equip Avatar
create or replace function equip_avatar(p_avatar_id uuid)
returns void
language plpgsql
security definer
as $$
declare
  v_user_id uuid := auth.uid();
begin
  -- 1. Unequip all
  update avatars_users
  set equipped = false 
  where user_id = v_user_id;

  -- 2. Equip target
  update avatars_users
  set equipped = true 
  where user_id = v_user_id and avatar_id = p_avatar_id;
  
  -- 3. Update denormalized avatar_url in users table
  update users
  set avatar_url = (select image_url from avatars where id = p_avatar_id)
  where id = v_user_id;
  
end;
$$;

-- SEED DATA
insert into avatars (name, image_url, xp_cost, rarity, is_free) values
('الأمير الصغير', 'https://cdn-icons-png.flaticon.com/512/4140/4140048.png', 0, 'common', true),
('رائد الفضاء', 'https://cdn-icons-png.flaticon.com/512/3069/3069172.png', 100, 'rare', false),
('البطل الخارق', 'https://cdn-icons-png.flaticon.com/512/1255/1255903.png', 200, 'epic', false),
('القطة السعيدة', 'https://cdn-icons-png.flaticon.com/512/616/616430.png', 50, 'common', false),
('النمر القوي', 'https://cdn-icons-png.flaticon.com/512/3069/3069185.png', 300, 'legendary', false),
('الأميرة', 'https://cdn-icons-png.flaticon.com/512/4140/4140037.png', 150, 'rare', false);
