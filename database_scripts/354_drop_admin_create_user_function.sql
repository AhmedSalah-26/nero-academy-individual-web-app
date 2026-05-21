-- Drop admin_create_user function and related trigger
-- Run this to clean up the database after switching to Admin API

-- Drop the function
DROP FUNCTION IF EXISTS public.admin_create_user(text, text, text, text);

-- Drop the trigger function if it exists
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- Note: The trigger will be automatically dropped when the function is dropped with CASCADE
