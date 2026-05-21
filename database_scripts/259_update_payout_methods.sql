-- =====================================================
-- Update Payout Methods to Support InstaPay and Wallet
-- =====================================================

-- First, drop the old constraints
ALTER TABLE instructor_payouts 
DROP CONSTRAINT IF EXISTS instructor_payouts_payout_method_check;

ALTER TABLE instructor_profiles 
DROP CONSTRAINT IF EXISTS instructor_profiles_payout_method_check;

-- Update existing data to use new payment methods
-- Convert old payment methods to new ones
UPDATE instructor_payouts 
SET payout_method = 'wallet'
WHERE payout_method NOT IN ('instapay', 'wallet');

-- Update instructor_profiles as well
UPDATE instructor_profiles 
SET payout_method = 'wallet'
WHERE payout_method NOT IN ('instapay', 'wallet');

-- Now add the new constraints
ALTER TABLE instructor_payouts 
ADD CONSTRAINT instructor_payouts_payout_method_check 
CHECK (payout_method IN ('instapay', 'wallet'));

ALTER TABLE instructor_profiles 
ADD CONSTRAINT instructor_profiles_payout_method_check 
CHECK (payout_method IN ('instapay', 'wallet'));

-- Add comments to explain payout_details structure
COMMENT ON COLUMN instructor_payouts.payout_details IS 
'Payment details in JSON format:
- instapay: {"instapay_id": "user@instapay"}
- wallet: {"phone_number": "01xxxxxxxxx"}';

COMMENT ON COLUMN instructor_profiles.payout_details IS 
'Default payment details in JSON format (same structure as instructor_payouts.payout_details)';

-- Example usage:
-- INSERT INTO instructor_payouts (instructor_id, amount, payout_method, payout_details)
-- VALUES (
--   'instructor-uuid',
--   1000.00,
--   'instapay',
--   '{"instapay_id": "user@instapay"}'::jsonb
-- );

-- INSERT INTO instructor_payouts (instructor_id, amount, payout_method, payout_details)
-- VALUES (
--   'instructor-uuid',
--   500.00,
--   'wallet',
--   '{"phone_number": "01012345678"}'::jsonb
-- );




