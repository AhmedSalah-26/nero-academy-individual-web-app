-- Remove target_audience from banners table
-- All banners will be shown to everyone

-- Drop the check constraint
ALTER TABLE banners 
DROP CONSTRAINT IF EXISTS banners_target_audience_check;

-- Drop the target_audience column
ALTER TABLE banners 
DROP COLUMN IF EXISTS target_audience;

-- Update any views or functions that use target_audience
-- (The get_active_banners function will be updated to not filter by target_audience)
