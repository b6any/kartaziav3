-- Function to handle avatar purchase
CREATE OR REPLACE FUNCTION purchase_avatar(p_avatar_id UUID, p_cost INTEGER)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_xp INTEGER;
  v_user_id UUID := auth.uid();
BEGIN
  -- Get user XP
  SELECT xp INTO v_user_xp FROM users WHERE id = v_user_id;
  
  -- Check if user exists
  IF v_user_xp IS NULL THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  -- Check capability
  IF v_user_xp < p_cost THEN
    RAISE EXCEPTION 'Insufficient XP';
  END IF;
  
  -- Deduct XP
  UPDATE users SET xp = xp - p_cost WHERE id = v_user_id;
  
  -- Add to collection
  INSERT INTO avatars_users (user_id, avatar_id, equipped)
  VALUES (v_user_id, p_avatar_id, false);
END;
$$;

-- Function to handle avatar equipping
CREATE OR REPLACE FUNCTION equip_avatar(p_avatar_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_avatar_url TEXT;
BEGIN
  -- 1. Unequip all for this user
  UPDATE avatars_users 
  SET equipped = false 
  WHERE user_id = v_user_id;
  
  -- 2. Equip the target avatar (verify ownership implicitly by where clause)
  UPDATE avatars_users 
  SET equipped = true 
  WHERE user_id = v_user_id AND avatar_id = p_avatar_id;

  -- 3. Get the avatar URL
  SELECT image_url INTO v_avatar_url FROM avatars WHERE id = p_avatar_id;

  -- 4. Update the main users table too for easy access
  UPDATE users 
  SET avatar_url = v_avatar_url 
  WHERE id = v_user_id;
END;
$$;
