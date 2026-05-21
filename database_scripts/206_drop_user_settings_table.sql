-- ============================================
-- Drop User Settings Table
-- ============================================
-- Language and Theme are now stored locally only
-- This script removes the unused user_settings table
-- ============================================

-- Drop trigger first
DROP TRIGGER IF EXISTS trigger_user_settings_updated_at ON public.user_settings;
DROP TRIGGER IF EXISTS trigger_create_user_settings ON public.profiles;

-- Drop functions
DROP FUNCTION IF EXISTS update_user_settings_updated_at();
DROP FUNCTION IF EXISTS create_default_user_settings();

-- Drop table
DROP TABLE IF EXISTS public.user_settings CASCADE;

-- Verify deletion
-- SELECT * FROM information_schema.tables WHERE table_name = 'user_settings';
