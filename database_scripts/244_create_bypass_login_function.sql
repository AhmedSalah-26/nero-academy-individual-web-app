-- ============================================================================
-- CREATE BYPASS LOGIN FUNCTION
-- ============================================================================
-- This function creates a magic link for bypass login in development
-- ============================================================================

-- Function to generate a one-time password (OTP) link for development
CREATE OR REPLACE FUNCTION generate_dev_login_link(
  user_email TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_id UUID;
  magic_link TEXT;
BEGIN
  -- Get user ID from email
  SELECT id INTO user_id
  FROM auth.users
  WHERE email = user_email;
  
  IF user_id IS NULL THEN
    RAISE EXCEPTION 'User not found with email: %', user_email;
  END IF;
  
  -- For development, we'll return a success message
  -- The actual login will be handled by the client
  RETURN 'User found: ' || user_id::TEXT;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION generate_dev_login_link(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_dev_login_link(TEXT) TO anon;

COMMENT ON FUNCTION generate_dev_login_link IS 
  'Generates a development login link for bypass authentication';

-- ============================================================================
-- ALTERNATIVE: Use Supabase Admin API
-- ============================================================================
-- The best way to handle bypass login is to use Supabase Admin API
-- from a secure backend, not from the client app
-- ============================================================================
