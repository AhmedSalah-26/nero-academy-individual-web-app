-- =============================================
-- 335: FIX OLD EARNINGS DATA
-- =============================================
-- Problem: Old earnings_transactions records were saved with 
-- the original course price instead of the effective (discounted) price.
-- Also used hardcoded 70% commission instead of per-instructor revenue_share.
--
-- Fix:
--   1. Update each earnings_transaction to use the enrollment.price 
--      (which IS the correct effective/discounted price)
--   2. Recalculate commission using per-instructor revenue_share
--   3. Set original_price from courses.price (for reference)
--   4. Rebuild instructor_balance from scratch
-- =============================================

-- =============================================
-- STEP 1: Fix earnings_transactions — use enrollment price + instructor revenue_share
-- =============================================
-- For each earning, find the matching enrollment and use its price
-- Also apply the correct per-instructor revenue_share
DO $$
DECLARE
  r RECORD;
  v_enrollment_price NUMERIC;
  v_original_price NUMERIC;
  v_revenue_share NUMERIC;
  v_instructor_share NUMERIC;
  v_platform_fee NUMERIC;
  v_fix_count INTEGER := 0;
BEGIN
  RAISE NOTICE '🔧 Starting earnings fix...';

  FOR r IN
    SELECT et.id, et.user_id, et.course_id, et.amount, et.commission
    FROM public.earnings_transactions et
    WHERE et.source_type = 'course_sale'
  LOOP
    -- Get enrollment price (the correct effective/discounted price)
    SELECT e.price INTO v_enrollment_price
    FROM public.enrollments e
    WHERE e.course_id = r.course_id
      AND e.instructor_id = r.user_id
    ORDER BY e.enrolled_at DESC
    LIMIT 1;

    -- If no enrollment found, try matching by course_id directly
    IF v_enrollment_price IS NULL THEN
      SELECT e.price INTO v_enrollment_price
      FROM public.enrollments e
      WHERE e.course_id = r.course_id
      ORDER BY e.enrolled_at DESC
      LIMIT 1;
    END IF;

    -- Get original course price (for reference)
    SELECT c.price INTO v_original_price
    FROM public.courses c
    WHERE c.id = r.course_id;

    -- Get instructor's revenue_share (default 70%)
    SELECT COALESCE(ip.revenue_share, 70.00) INTO v_revenue_share
    FROM public.instructor_profiles ip
    WHERE ip.instructor_id = r.user_id;

    IF v_revenue_share IS NULL THEN
      v_revenue_share := 70.00;
    END IF;

    -- Use enrollment price if found, otherwise keep current amount
    IF v_enrollment_price IS NOT NULL AND v_enrollment_price > 0 THEN
      -- Recalculate with correct price and revenue_share
      v_instructor_share := ROUND(v_enrollment_price * (v_revenue_share / 100));
      v_platform_fee := v_enrollment_price - v_instructor_share;

      UPDATE public.earnings_transactions
      SET
        amount = v_enrollment_price,
        commission = v_platform_fee,
        original_price = COALESCE(v_original_price, v_enrollment_price)
      WHERE id = r.id;

      v_fix_count := v_fix_count + 1;

      RAISE NOTICE '  ✅ Fixed earning %: amount % → %, commission % → %, revenue_share=%',
        r.id, r.amount, v_enrollment_price, r.commission, v_platform_fee, v_revenue_share;
    ELSE
      -- No enrollment found, just set original_price and recalculate commission
      v_instructor_share := ROUND(r.amount * (v_revenue_share / 100));
      v_platform_fee := r.amount - v_instructor_share;

      UPDATE public.earnings_transactions
      SET
        commission = v_platform_fee,
        original_price = COALESCE(v_original_price, r.amount)
      WHERE id = r.id;

      RAISE NOTICE '  ⚠️ No enrollment for earning %, kept amount=%, recalculated commission=%',
        r.id, r.amount, v_platform_fee;
    END IF;
  END LOOP;

  RAISE NOTICE '🔧 Fixed % earnings_transactions records', v_fix_count;
END $$;


-- =============================================
-- STEP 2: Rebuild instructor_balance from scratch
-- =============================================
-- Reset all balances and recalculate from earnings_transactions
-- This ensures available_balance, total_earnings are correct
DO $$
DECLARE
  r RECORD;
  v_total_net_earnings NUMERIC;
  v_total_pending NUMERIC;
  v_total_withdrawn NUMERIC;
  v_available NUMERIC;
  v_count INTEGER := 0;
BEGIN
  RAISE NOTICE '🔧 Rebuilding instructor_balance...';

  FOR r IN
    SELECT DISTINCT user_id FROM public.earnings_transactions
  LOOP
    -- Calculate total net earnings (amount - commission) for this instructor
    SELECT COALESCE(SUM(amount - commission), 0)
    INTO v_total_net_earnings
    FROM public.earnings_transactions
    WHERE user_id = r.user_id;

    -- Calculate total pending (from withdraw_requests with status=pending)
    SELECT COALESCE(SUM(amount), 0)
    INTO v_total_pending
    FROM public.withdraw_requests
    WHERE user_id = r.user_id
      AND status = 'pending';

    -- Calculate total withdrawn (approved + paid withdraw_requests)
    SELECT COALESCE(SUM(amount), 0)
    INTO v_total_withdrawn
    FROM public.withdraw_requests
    WHERE user_id = r.user_id
      AND status IN ('approved', 'paid');

    -- Available = total earnings - pending - withdrawn
    v_available := v_total_net_earnings - v_total_pending - v_total_withdrawn;
    IF v_available < 0 THEN
      v_available := 0;
    END IF;

    -- Upsert instructor_balance
    IF EXISTS (
      SELECT 1 FROM public.instructor_balance WHERE instructor_id = r.user_id
    ) THEN
      UPDATE public.instructor_balance
      SET
        available_balance = v_available,
        pending_balance = v_total_pending,
        total_withdrawn = v_total_withdrawn,
        total_earnings = v_total_net_earnings,
        updated_at = now()
      WHERE instructor_id = r.user_id;
    ELSE
      INSERT INTO public.instructor_balance (
        instructor_id,
        available_balance,
        pending_balance,
        total_withdrawn,
        total_earnings
      ) VALUES (
        r.user_id,
        v_available,
        v_total_pending,
        v_total_withdrawn,
        v_total_net_earnings
      );
    END IF;

    v_count := v_count + 1;
    RAISE NOTICE '  ✅ Instructor %: earnings=%, available=%, pending=%, withdrawn=%',
      r.user_id, v_total_net_earnings, v_available, v_total_pending, v_total_withdrawn;
  END LOOP;

  RAISE NOTICE '🔧 Rebuilt balance for % instructors', v_count;
END $$;


-- =============================================
-- STEP 3: Verify — show final state
-- =============================================
DO $$
DECLARE
  v_total_earnings_count INTEGER;
  v_total_balance_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_total_earnings_count FROM public.earnings_transactions;
  SELECT COUNT(*) INTO v_total_balance_count FROM public.instructor_balance;

  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ FIX COMPLETE!';
  RAISE NOTICE '  earnings_transactions: % records', v_total_earnings_count;
  RAISE NOTICE '  instructor_balance: % records', v_total_balance_count;
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Changes made:';
  RAISE NOTICE '  1. earnings_transactions.amount → enrollment effective price';
  RAISE NOTICE '  2. earnings_transactions.commission → recalculated with per-instructor revenue_share';
  RAISE NOTICE '  3. earnings_transactions.original_price → courses.price';
  RAISE NOTICE '  4. instructor_balance → rebuilt from earnings + withdrawals';
END $$;
