-- =============================================
-- 350: PROCESS REFUND FUNCTION
-- =============================================
-- Creates a function to handle refund processing
-- When a refund is processed:
-- 1. Update enrollment status to 'refunded'
-- 2. Create a negative earnings_transaction for the instructor
-- 3. Deduct from instructor's available_balance
-- =============================================

CREATE OR REPLACE FUNCTION public.process_refund(
  p_enrollment_id UUID,
  p_reason TEXT
)
RETURNS VOID AS $$
DECLARE
  v_enrollment RECORD;
  v_instructor_id UUID;
  v_course_name TEXT;
  v_amount_paid NUMERIC;
  v_instructor_share NUMERIC;
  v_commission NUMERIC;
  v_revenue_share NUMERIC;
BEGIN
  -- Get enrollment details
  SELECT 
    e.id,
    e.user_id,
    e.course_id,
    e.instructor_id,
    e.price,
    e.status,
    c.title_ar,
    70.0 as revenue_share  -- Default revenue share
  INTO v_enrollment
  FROM public.enrollments e
  JOIN public.courses c ON c.id = e.course_id
  WHERE e.id = p_enrollment_id;
  
  -- Try to get revenue_share from instructors table if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'instructors'
  ) THEN
    SELECT COALESCE(i.revenue_share, 70.0)
    INTO v_revenue_share
    FROM public.instructors i
    WHERE i.user_id = v_enrollment.instructor_id;
    
    IF v_revenue_share IS NOT NULL THEN
      v_enrollment.revenue_share := v_revenue_share;
    END IF;
  END IF;

  -- Check if enrollment exists
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Enrollment not found';
  END IF;

  -- Check if already refunded
  IF v_enrollment.status = 'refunded' THEN
    RAISE EXCEPTION 'Enrollment already refunded';
  END IF;

  -- Get values
  v_instructor_id := v_enrollment.instructor_id;
  v_course_name := v_enrollment.title_ar;
  v_amount_paid := COALESCE(v_enrollment.price, 0);
  v_revenue_share := COALESCE(v_enrollment.revenue_share, 70);

  -- Calculate instructor share and commission (as negative values)
  v_instructor_share := -(v_amount_paid * v_revenue_share / 100);
  v_commission := -(v_amount_paid * (100 - v_revenue_share) / 100);

  -- Delete enrollment instead of updating status
  DELETE FROM public.enrollments
  WHERE id = p_enrollment_id;

  -- Create negative earnings transaction for instructor
  INSERT INTO public.earnings_transactions (
    user_id,
    course_id,
    course_name,
    amount,
    commission,
    status,
    source_type,
    created_at
  ) VALUES (
    v_instructor_id,
    v_enrollment.course_id,
    v_course_name,
    v_amount_paid,  -- Full amount as negative
    v_commission,   -- Commission as negative
    'available',
    'refund',
    NOW()
  );

  -- Update instructor balance (deduct the refunded amount)
  UPDATE public.instructor_balance
  SET 
    available_balance = available_balance + v_instructor_share,  -- Adding negative = subtracting
    total_earnings = total_earnings + v_instructor_share,
    updated_at = NOW()
  WHERE instructor_id = v_instructor_id;

  -- Create balance record if doesn't exist
  INSERT INTO public.instructor_balance (instructor_id, available_balance, total_earnings)
  VALUES (v_instructor_id, v_instructor_share, v_instructor_share)
  ON CONFLICT (instructor_id) DO NOTHING;

  RAISE NOTICE 'Refund processed: enrollment=%, instructor=%, amount=%', 
    p_enrollment_id, v_instructor_id, v_instructor_share;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.process_refund(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.process_refund(UUID, TEXT) TO service_role;

-- =============================================
-- ✅ DONE: Refund processing function created
-- =============================================
