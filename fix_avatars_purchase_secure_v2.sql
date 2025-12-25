-- Update purchase_avatar to handle duplicate purchase gracefully without error
-- Drop old versions 
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
  -- 0. Check if already owned
  SELECT EXISTS(SELECT 1 FROM avatars_users WHERE user_id = v_user_id AND avatar_id = avatar_uuid) INTO v_already_owned;
  
  IF v_already_owned THEN
     -- If already owned, just return silently (idempotent success)
     RETURN;
  END IF;

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

  -- 5. Add to Collection
  INSERT INTO avatars_users (user_id, avatar_id, equipped)
  VALUES (v_user_id, avatar_uuid, false);
  
END;
$$;
