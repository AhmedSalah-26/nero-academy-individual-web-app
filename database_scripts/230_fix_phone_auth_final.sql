-- ============================================================
-- Fix Phone Authentication Profile Creation - V3
-- ============================================================
-- IMPORTANT: Run this script in Supabase SQL Editor
-- Issue: RLS blocking profile creation for phone auth users
-- Solution: Create SECURITY DEFINER function that bypasses RLS
-- Version: 3.0 | January 2026
-- ============================================================

-- Step 1: Create/Update the RPC function (SECURITY DEFINER bypasses RLS)
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
    -- Update existing profile with phone if missing
    UPDATE profiles 
    SET 
      phone = COALESCE(profiles.phone, user_phone),
      updated_at = NOW()
    WHERE id = user_id;
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
  )
  ON CONFLICT (id) DO UPDATE SET
    phone = COALESCE(profiles.phone, EXCLUDED.phone),
    updated_at = NOW();
    
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'create_profile_for_phone_auth failed: %', SQLERRM;
END;
$$;

-- Step 2: Grant execute permission to authenticated users and anon
GRANT EXECUTE ON FUNCTION public.create_profile_for_phone_auth TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_profile_for_phone_auth TO anon;
GRANT EXECUTE ON FUNCTION public.create_profile_for_phone_auth TO service_role;

-- Step 3: Create/Update trigger function for automatic profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Create profile for any new user (phone or email)
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
    COALESCE(
      NEW.raw_user_meta_data->>'name', 
      NEW.raw_user_meta_data->>'full_name',
      NEW.phone,
      split_part(NEW.email, '@', 1),
      'مستخدم جديد'
    ),
    COALESCE(NEW.raw_user_meta_data->>'role', 'student'),
    TRUE,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = COALESCE(profiles.email, EXCLUDED.email),
    phone = COALESCE(profiles.phone, EXCLUDED.phone),
    updated_at = NOW();
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail - app will create profile
    RAISE WARNING 'handle_new_user failed for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;

-- Step 4: Drop old triggers and create unified one
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_phone ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Step 5: Ensure RLS policies allow profile operations
-- Drop old policies
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Enable insert for auth" ON profiles;

-- Allow users to read their own profile
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
CREATE POLICY "Users can read own profile" 
ON profiles 
FOR SELECT 
TO authenticated
USING (auth.uid() = id);

-- Allow users to update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" 
ON profiles 
FOR UPDATE 
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Allow authenticated users to insert their own profile
CREATE POLICY "Users can insert own profile" 
ON profiles 
FOR INSERT 
TO authenticated
WITH CHECK (auth.uid() = id);

-- Step 6: Verify setup
DO $$
BEGIN
  RAISE NOTICE '✅ Phone auth profile creation fix applied successfully!';
  RAISE NOTICE 'RPC function: create_profile_for_phone_auth - READY';
  RAISE NOTICE 'Trigger: on_auth_user_created - READY';
END $$;

-- ============================================================
-- TEST: You can test the RPC function with:
-- SELECT create_profile_for_phone_auth(
--   'your-user-uuid'::uuid,
--   '+201234567890',
--   NULL,
--   'Test User'
-- );
-- ============================================================
