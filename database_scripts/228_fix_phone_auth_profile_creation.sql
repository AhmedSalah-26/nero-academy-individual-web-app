-- ============================================================
-- Fix Phone Authentication Profile Creation
-- ============================================================
-- Issue: RLS policy prevents profile creation during phone auth
-- Solution: Create a function that bypasses RLS for initial profile creation
-- Version: 1.0 | January 2026
-- ============================================================

-- Drop existing policy that might cause issues
DROP POLICY IF EXISTS "Enable insert for auth" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON profiles;

-- Create new policy that allows authenticated users to insert their own profile
CREATE POLICY "Enable insert for authenticated users" 
ON profiles 
FOR INSERT 
TO authenticated
WITH CHECK (auth.uid() = id);

-- Create a function to handle profile creation (bypasses RLS)
CREATE OR REPLACE FUNCTION public.create_profile_for_phone_auth(
  user_id UUID,
  user_phone TEXT,
  user_email TEXT DEFAULT NULL,
  user_name TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- This allows the function to bypass RLS
SET search_path = public
AS $$
BEGIN
  -- Check if profile already exists
  IF EXISTS (SELECT 1 FROM profiles WHERE id = user_id) THEN
    RETURN;
  END IF;

  -- Create the profile
  INSERT INTO profiles (
    id,
    email,
    phone,
    name,
    role,
    is_active,
    created_at,
    updated_at
  ) VALUES (
    user_id,
    COALESCE(user_email, REPLACE(user_phone, '+', '') || '@phone.user'),
    user_phone,
    COALESCE(user_name, user_phone, 'مستخدم جديد'),
    'student',
    TRUE,
    NOW(),
    NOW()
  );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.create_profile_for_phone_auth TO authenticated;

-- Create a trigger to automatically create profile after phone auth
CREATE OR REPLACE FUNCTION public.handle_new_phone_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only create profile if it doesn't exist and user has a phone
  IF NEW.phone IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profiles WHERE id = NEW.id) THEN
    INSERT INTO profiles (
      id,
      email,
      phone,
      name,
      role,
      is_active,
      created_at,
      updated_at
    ) VALUES (
      NEW.id,
      COALESCE(NEW.email, REPLACE(NEW.phone, '+', '') || '@phone.user'),
      NEW.phone,
      COALESCE(NEW.raw_user_meta_data->>'name', NEW.phone, 'مستخدم جديد'),
      'student',
      TRUE,
      NOW(),
      NOW()
    )
    ON CONFLICT (id) DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS on_auth_user_created_phone ON auth.users;

-- Create trigger on auth.users table
CREATE TRIGGER on_auth_user_created_phone
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_phone_user();

-- ============================================================
-- Testing
-- ============================================================
-- Test the function:
-- SELECT create_profile_for_phone_auth(
--   'test-uuid'::uuid,
--   '+201234567890',
--   NULL,
--   'Test User'
-- );
-- ============================================================
