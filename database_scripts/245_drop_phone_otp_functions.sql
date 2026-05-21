-- ============================================================================
-- DROP PHONE OTP BYPASS FUNCTIONS
-- ============================================================================
-- This script removes all functions related to phone OTP bypass
-- ============================================================================

-- Drop the add_phone_to_auth_user function
DROP FUNCTION IF EXISTS add_phone_to_auth_user(UUID, TEXT);

-- Drop the generate_dev_login_link function
DROP FUNCTION IF EXISTS generate_dev_login_link(TEXT);

-- Verify functions are dropped
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE '%phone%' OR routine_name LIKE '%login%';

-- ============================================================================
-- CLEANUP COMPLETE
-- ============================================================================
-- All phone OTP bypass functions have been removed
-- ============================================================================
