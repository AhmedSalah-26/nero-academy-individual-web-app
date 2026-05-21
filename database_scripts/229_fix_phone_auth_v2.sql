-- ============================================================
-- Fix Phone Authentication Profile Creation - V2
-- ============================================================
-- Issue: Race condition between app insert and trigger insert
-- Solution: Use SECURITY DEFINER function with ON CONFLICT DO NOTHING
-- Version: 2.0 | January 2026
-- ============================================================

-- Update the trigger function to be more robust
CREATE OR REPLACE FUNCTION public.handle_new_phone_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only create profile if user has a phone number
  IF NEW.phone IS NOT NULL THEN
    -- Use INSERT ... ON CONFLICT to avoid race conditions
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
      COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'full_name', NEW.phone, 'مستخدم جديد'),
      COALESCE(NEW.raw_user_meta_data->>'role', 'student'),
      TRUE,
      NOW(),
      NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
      phone = COALESCE(profiles.phone, EXCLUDED.phone),
      updated_at = NOW();
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail the trigger
    RAISE WARNING 'handle_new_phone_user failed for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created_phone ON auth.users;

CREATE TRIGGER on_auth_user_created_phone
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_phone_user();

-- Also create/update the function for email auth
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

-- Drop old trigger and create unified one
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_phone ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Ensure RLS policy allows insert
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- Policy: Authenticated users can insert their own profile
CREATE POLICY "Users can insert own profile" 
ON profiles 
FOR INSERT 
TO authenticated
WITH CHECK (auth.uid() = id);

-- Policy: Service role can insert any profile (for triggers)
DROP POLICY IF EXISTS "Service role full access" ON profiles;

-- ============================================================
-- Verify everything is set up correctly
-- ============================================================
-- SELECT 
--   tgname AS trigger_name,
--   proname AS function_name
-- FROM pg_trigger t
-- JOIN pg_proc p ON t.tgfoid = p.oid
-- WHERE tgrelid = 'auth.users'::regclass;
-- ============================================================
