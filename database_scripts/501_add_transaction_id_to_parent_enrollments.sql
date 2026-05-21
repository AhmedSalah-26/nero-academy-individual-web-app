-- =============================================
-- 501: ADD TRANSACTION_ID TO PARENT_ENROLLMENTS
-- =============================================
-- Add transaction_id column to store payment gateway transaction ID
-- =============================================

-- Add transaction_id column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'parent_enrollments'
      AND column_name = 'transaction_id'
  ) THEN
    ALTER TABLE public.parent_enrollments
      ADD COLUMN transaction_id TEXT;
    
    RAISE NOTICE '✅ Added transaction_id column to parent_enrollments';
  ELSE
    RAISE NOTICE 'ℹ️ transaction_id column already exists';
  END IF;
END $$;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_parent_enrollments_transaction_id 
  ON public.parent_enrollments(transaction_id);

RAISE NOTICE '✅ Migration complete!';
