-- =============================================
-- 500: CONFIRM ENROLLMENT PAYMENT FUNCTION
-- =============================================
-- This function confirms payment and activates enrollments
-- =============================================

CREATE OR REPLACE FUNCTION public.confirm_enrollment_payment(
  p_parent_enrollment_id UUID,
  p_transaction_id TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Get user_id from parent_enrollment
  SELECT user_id INTO v_user_id
  FROM parent_enrollments
  WHERE id = p_parent_enrollment_id;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Parent enrollment not found: %', p_parent_enrollment_id;
  END IF;

  -- Update parent_enrollment to paid
  UPDATE parent_enrollments
  SET 
    payment_status = 'paid',
    paid_at = NOW(),
    transaction_id = p_transaction_id,
    updated_at = NOW()
  WHERE id = p_parent_enrollment_id;

  -- Activate all enrollments linked to this parent_enrollment
  UPDATE enrollments
  SET 
    status = 'active',
    updated_at = NOW()
  WHERE parent_enrollment_id = p_parent_enrollment_id
    AND status = 'pending';

  RETURN TRUE;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.confirm_enrollment_payment(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.confirm_enrollment_payment(UUID, TEXT) TO anon;
