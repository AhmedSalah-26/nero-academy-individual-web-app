-- ============================================================================
-- MAKE USER ADMIN
-- ============================================================================
-- This script changes a user's role to admin
-- ============================================================================

-- Check current user role
SELECT id, name, email, phone, role
FROM profiles
WHERE phone = '+201234566489' OR email = 'a@a.com';

-- Make the user with phone +201234566489 an admin
UPDATE profiles
SET role = 'admin',
    updated_at = NOW()
WHERE phone = '+201234566489';

-- OR make user with email a@a.com an admin
UPDATE profiles
SET role = 'admin',
    updated_at = NOW()
WHERE email = 'a@a.com';

-- Verify the update
SELECT id, name, email, phone, role
FROM profiles
WHERE role = 'admin';

-- ============================================================================
-- NOTES:
-- ============================================================================
-- Available roles: 'student', 'instructor', 'admin', 'parent'
-- This will change the user's role to admin
-- ============================================================================
