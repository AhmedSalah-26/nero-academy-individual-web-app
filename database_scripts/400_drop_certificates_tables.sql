-- =====================================================
-- Drop Certificates Feature Tables and Functions
-- =====================================================
-- This script removes all certificates-related tables,
-- functions, triggers, and policies from the database.
-- =====================================================

-- Drop RLS policies first
DROP POLICY IF EXISTS "Users can view their own certificates" ON certificates;
DROP POLICY IF EXISTS "Users can insert their own certificates" ON certificates;
DROP POLICY IF EXISTS "Admins can view all certificates" ON certificates;
DROP POLICY IF EXISTS "Admins can manage all certificates" ON certificates;

-- Drop triggers
DROP TRIGGER IF EXISTS update_certificates_updated_at ON certificates;

-- Drop functions
DROP FUNCTION IF EXISTS issue_certificate(uuid, uuid);
DROP FUNCTION IF EXISTS get_certificate_details(uuid);
DROP FUNCTION IF EXISTS get_certificate_full_details(uuid);
DROP FUNCTION IF EXISTS verify_certificate(text);

-- Drop tables
DROP TABLE IF EXISTS certificates CASCADE;

-- Drop any certificate-related columns from other tables
-- (if certificates were referenced in enrollments or other tables)
ALTER TABLE IF EXISTS enrollments 
  DROP COLUMN IF EXISTS certificate_id CASCADE;

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Successfully dropped all certificates-related database objects';
END $$;
