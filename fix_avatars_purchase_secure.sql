-- Secure version of purchase_avatar that calculates cost on server
-- Drop old versions to be safe (overloading might cause confusion)
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
BEGIN
  -- 1. Get Avatar Cost
  SELECT xp_cost INTO v_cost FROM avatars WHERE id = avatar_uuid;
  
  IF v_cost IS NULL THEN
    RAISE EXCEPTION 'Avatar not found';
  END IF;

  -- 2. Get User XP
  SELECT xp INTO v_user_xp FROM users WHERE id = v_user_id;

  IF v_user_xp IS NULL THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  -- 3. Check Affordability
  IF v_user_xp < v_cost THEN
    RAISE EXCEPTION 'Insufficient XP';
  END IF;

  -- 4. Deduct XP
  UPDATE users 
  SET xp = xp - v_cost 
  WHERE id = v_user_id;

  -- 5. Add to Collection (Ignore if already owned to prevent error, or let it fail? Unique constraint usually handles it)
  -- efficient upsert or ignore
  INSERT INTO avatars_users (user_id, avatar_id, equipped)
  VALUES (v_user_id, avatar_uuid, false)
  ON CONFLICT (user_id, avatar_id) DO NOTHING;
  
END;
$$;
