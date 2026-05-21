-- Drop the old function first if it exists
DROP FUNCTION IF EXISTS add_phone_to_auth_user(UUID, TEXT);

-- Function to add phone number to auth.users without triggering OTP
-- This bypasses the OTP verification for development/testing purposes

CREATE OR REPLACE FUNCTION add_phone_to_auth_user(
  user_id UUID,
  phone_number TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER -- Run with elevated privileges
AS $$
DECLARE
  result JSONB;
  rows_updated INTEGER;
BEGIN
  -- Update the phone in auth.users table directly
  UPDATE auth.users
  SET 
    phone = phone_number,
    phone_confirmed_at = NOW(), -- Mark as confirmed immediately
    phone_change = NULL, -- Clear any pending phone change
    phone_change_token = NULL,
    phone_change_sent_at = NULL,
    updated_at = NOW()
  WHERE id = user_id;
  
  GET DIAGNOSTICS rows_updated = ROW_COUNT;
  
  -- Also update the raw_user_meta_data if needed
  UPDATE auth.users
  SET raw_user_meta_data = 
    COALESCE(raw_user_meta_data, '{}'::jsonb) || 
    jsonb_build_object('phone', phone_number, 'phone_verified', true)
  WHERE id = user_id;
  
  -- Return success result
  result := jsonb_build_object(
    'success', true,
    'rows_updated', rows_updated,
    'phone', phone_number,
    'confirmed_at', NOW()
  );
  
  RETURN result;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION add_phone_to_auth_user(UUID, TEXT) TO authenticated;

COMMENT ON FUNCTION add_phone_to_auth_user IS 'Adds phone number to auth.users without OTP verification - for development/testing only';
