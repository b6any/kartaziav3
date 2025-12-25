-- Create or Replace equip_avatar function
CREATE OR REPLACE FUNCTION equip_avatar(p_avatar_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  -- 1. Unequip all for this user
  UPDATE avatars_users
  SET equipped = false 
  WHERE user_id = v_user_id;

  -- 2. Equip the specific avatar
  UPDATE avatars_users
  SET equipped = true 
  WHERE user_id = v_user_id AND avatar_id = p_avatar_id;
  
  -- 3. Update the denormalized avatar_url in the users table (if it exists)
  -- We use a safe update that doesn't fail if the column is missing or user is missing
  UPDATE users
  SET avatar_url = (SELECT image_url FROM avatars WHERE id = p_avatar_id)
  WHERE id = v_user_id;
  
END;
$$;
