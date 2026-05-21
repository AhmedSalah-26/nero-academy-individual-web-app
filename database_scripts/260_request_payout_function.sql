-- ============================================================
-- Request Payout Function
-- Creates a payout request and marks earnings as processing
-- ============================================================

-- Drop existing function if exists
DROP FUNCTION IF EXISTS request_instructor_payout(UUID, DECIMAL, TEXT, JSONB);

-- Create the payout request function
CREATE OR REPLACE FUNCTION request_instructor_payout(
  p_instructor_id UUID,
  p_amount DECIMAL(10,2),
  p_payout_method TEXT,
  p_payout_details JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_available_amount DECIMAL(10,2);
  v_payout_id UUID;
  v_remaining_amount DECIMAL(10,2);
  v_earning RECORD;
  v_total_allocated DECIMAL(10,2) := 0;
BEGIN
  -- Step 1: Check available earnings
  SELECT COALESCE(SUM(net_amount), 0)
  INTO v_available_amount
  FROM instructor_earnings
  WHERE instructor_id = p_instructor_id
    AND status = 'available';

  -- Validate amount
  IF p_amount <= 0 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Invalid amount',
      'error_ar', 'مبلغ غير صالح'
    );
  END IF;

  IF p_amount > v_available_amount THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Insufficient balance',
      'error_ar', 'الرصيد غير كافي',
      'available', v_available_amount
    );
  END IF;

  -- Step 2: Create payout request
  INSERT INTO instructor_payouts (
    instructor_id,
    amount,
    currency,
    payout_method,
    payout_details,
    status,
    requested_at
  ) VALUES (
    p_instructor_id,
    p_amount,
    'EGP',
    p_payout_method,
    p_payout_details,
    'pending',
    NOW()
  )
  RETURNING id INTO v_payout_id;

  -- Step 3: Mark earnings as processing and link to payout
  v_remaining_amount := p_amount;

  FOR v_earning IN
    SELECT id, net_amount
    FROM instructor_earnings
    WHERE instructor_id = p_instructor_id
      AND status = 'available'
    ORDER BY created_at ASC
  LOOP
    EXIT WHEN v_remaining_amount <= 0;

    IF v_earning.net_amount <= v_remaining_amount THEN
      -- Use entire earning
      UPDATE instructor_earnings
      SET status = 'processing'
      WHERE id = v_earning.id;

      INSERT INTO payout_items (payout_id, earning_id, amount)
      VALUES (v_payout_id, v_earning.id, v_earning.net_amount);

      v_remaining_amount := v_remaining_amount - v_earning.net_amount;
      v_total_allocated := v_total_allocated + v_earning.net_amount;
    ELSE
      -- Partial use (shouldn't happen normally, but handle it)
      -- For now, just use the full earning
      UPDATE instructor_earnings
      SET status = 'processing'
      WHERE id = v_earning.id;

      INSERT INTO payout_items (payout_id, earning_id, amount)
      VALUES (v_payout_id, v_earning.id, v_earning.net_amount);

      v_total_allocated := v_total_allocated + v_earning.net_amount;
      v_remaining_amount := 0;
    END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'success', true,
    'payout_id', v_payout_id,
    'amount', p_amount,
    'earnings_allocated', v_total_allocated,
    'message', 'Payout request created successfully',
    'message_ar', 'تم إنشاء طلب السحب بنجاح'
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM,
    'error_ar', 'حدث خطأ أثناء إنشاء طلب السحب'
  );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION request_instructor_payout(UUID, DECIMAL, TEXT, JSONB) TO authenticated;

-- Add comment
COMMENT ON FUNCTION request_instructor_payout IS 'Creates a payout request and marks the corresponding earnings as processing';

-- ============================================================
-- Complete Payout Function (for admin use)
-- Marks payout as completed and earnings as paid
-- ============================================================

DROP FUNCTION IF EXISTS complete_instructor_payout(UUID, UUID, TEXT);

CREATE OR REPLACE FUNCTION complete_instructor_payout(
  p_payout_id UUID,
  p_admin_id UUID,
  p_transaction_id TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Update payout status
  UPDATE instructor_payouts
  SET 
    status = 'completed',
    processed_by = p_admin_id,
    processed_at = NOW(),
    transaction_id = p_transaction_id,
    updated_at = NOW()
  WHERE id = p_payout_id;

  -- Update all linked earnings to paid
  UPDATE instructor_earnings
  SET status = 'paid'
  WHERE id IN (
    SELECT earning_id FROM payout_items WHERE payout_id = p_payout_id
  );

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Payout completed successfully',
    'message_ar', 'تم إتمام السحب بنجاح'
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$;

GRANT EXECUTE ON FUNCTION complete_instructor_payout(UUID, UUID, TEXT) TO authenticated;

-- ============================================================
-- Cancel/Fail Payout Function
-- Returns earnings to available status
-- ============================================================

DROP FUNCTION IF EXISTS cancel_instructor_payout(UUID, TEXT);

CREATE OR REPLACE FUNCTION cancel_instructor_payout(
  p_payout_id UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Update payout status
  UPDATE instructor_payouts
  SET 
    status = 'failed',
    failure_reason = p_reason,
    updated_at = NOW()
  WHERE id = p_payout_id;

  -- Return all linked earnings to available
  UPDATE instructor_earnings
  SET status = 'available'
  WHERE id IN (
    SELECT earning_id FROM payout_items WHERE payout_id = p_payout_id
  );

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Payout cancelled successfully',
    'message_ar', 'تم إلغاء طلب السحب'
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$;

GRANT EXECUTE ON FUNCTION cancel_instructor_payout(UUID, TEXT) TO authenticated;

-- ============================================================
-- Get Instructor Balance Function
-- Returns available and pending amounts
-- ============================================================

DROP FUNCTION IF EXISTS get_instructor_balance(UUID);

CREATE OR REPLACE FUNCTION get_instructor_balance(p_instructor_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_available DECIMAL(10,2);
  v_pending DECIMAL(10,2);
  v_processing DECIMAL(10,2);
  v_total_earned DECIMAL(10,2);
  v_total_paid DECIMAL(10,2);
BEGIN
  -- Available earnings (can be withdrawn)
  SELECT COALESCE(SUM(net_amount), 0)
  INTO v_available
  FROM instructor_earnings
  WHERE instructor_id = p_instructor_id AND status = 'available';

  -- Pending earnings (waiting to become available)
  SELECT COALESCE(SUM(net_amount), 0)
  INTO v_pending
  FROM instructor_earnings
  WHERE instructor_id = p_instructor_id AND status = 'pending';

  -- Processing (payout in progress)
  SELECT COALESCE(SUM(net_amount), 0)
  INTO v_processing
  FROM instructor_earnings
  WHERE instructor_id = p_instructor_id AND status = 'processing';

  -- Total earned (all time)
  SELECT COALESCE(SUM(net_amount), 0)
  INTO v_total_earned
  FROM instructor_earnings
  WHERE instructor_id = p_instructor_id;

  -- Total paid out
  SELECT COALESCE(SUM(net_amount), 0)
  INTO v_total_paid
  FROM instructor_earnings
  WHERE instructor_id = p_instructor_id AND status = 'paid';

  RETURN jsonb_build_object(
    'available', v_available,
    'pending', v_pending,
    'processing', v_processing,
    'total_earned', v_total_earned,
    'total_paid', v_total_paid
  );
END;
$$;

GRANT EXECUTE ON FUNCTION get_instructor_balance(UUID) TO authenticated;
