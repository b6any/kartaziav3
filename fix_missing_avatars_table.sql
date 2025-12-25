-- 1. Create missing 'avatars_users' table
CREATE TABLE IF NOT EXISTS avatars_users (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  avatar_id UUID REFERENCES avatars(id) ON DELETE CASCADE NOT NULL,
  equipped BOOLEAN DEFAULT FALSE,
  purchased_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, avatar_id)
);

-- 2. Enable Row Level Security (RLS)
ALTER TABLE avatars_users ENABLE ROW LEVEL SECURITY;

-- 3. Create RLS Policies
-- Allow users to view their own purchased avatars
CREATE POLICY "Users view own avatars" ON avatars_users 
  FOR SELECT USING (auth.uid() = user_id);

-- Allow users to insert (purchase) their own avatars
CREATE POLICY "Users insert own avatars" ON avatars_users 
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow users to update (equip/unequip) their own avatars
CREATE POLICY "Users update own avatars" ON avatars_users 
  FOR UPDATE USING (auth.uid() = user_id);

-- 4. Re-apply the purchase function (Safe Version) just in case
DROP FUNCTION IF EXISTS purchase_avatar(UUID, INTEGER);
DROP FUNCTION IF EXISTS purchase_avatar(UUID);

CREATE OR REPLACE FUNCTION purchase_avatar(avatar_uuid UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_cost INTEGER;
  v_user_xp INTEGER;
  v_already_owned BOOLEAN;
BEGIN
  -- Check if already owned
  SELECT EXISTS(SELECT 1 FROM avatars_users WHERE user_id = v_user_id AND avatar_id = avatar_uuid) INTO v_already_owned;
  
  IF v_already_owned THEN
     RETURN; -- Idempotent success
  END IF;

  -- Get Avatar Cost
  SELECT xp_cost INTO v_cost FROM avatars WHERE id = avatar_uuid;
  
  IF v_cost IS NULL THEN
    RAISE EXCEPTION 'Avatar not found';
  END IF;

  -- Get User XP
  SELECT xp INTO v_user_xp FROM users WHERE id = v_user_id;

  IF v_user_xp IS NULL THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  -- Check Affordability
  IF v_user_xp < v_cost THEN
    RAISE EXCEPTION 'Insufficient XP';
  END IF;

  -- Deduct XP
  UPDATE users 
  SET xp = xp - v_cost 
  WHERE id = v_user_id;

  -- Add to Collection
  INSERT INTO avatars_users (user_id, avatar_id, equipped)
  VALUES (v_user_id, avatar_uuid, false);
END;
$$;
