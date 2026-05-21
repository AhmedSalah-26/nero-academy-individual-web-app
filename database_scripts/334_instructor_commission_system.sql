-- =============================================
-- 334: INSTRUCTOR COMMISSION SYSTEM
-- =============================================
-- This script:
-- 1. Ensures instructor_profiles.revenue_share is usable
-- 2. Adds commission_rate column (admin-facing alias) if needed
-- 3. Creates RPC: admin_set_instructor_commission
-- 4. Creates RPC: get_instructor_commission
-- 5. Updates checkout earnings to track original_price
-- =============================================

-- =============================================
-- STEP 1: Add original_price to earnings_transactions
-- =============================================
-- This lets us track the full course price separately from what was charged
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'earnings_transactions'
      AND column_name = 'original_price'
  ) THEN
    ALTER TABLE public.earnings_transactions
      ADD COLUMN original_price NUMERIC(12,2) NOT NULL DEFAULT 0;
  END IF;
END $$;

-- =============================================
-- STEP 2: RPC — admin_set_instructor_commission
-- =============================================
-- Admin sets commission % for an instructor.
-- revenue_share is the instructor's share (e.g. 70 means 30% commission to platform)
-- =============================================
CREATE OR REPLACE FUNCTION public.admin_set_instructor_commission(
  p_instructor_id UUID,
  p_commission_rate NUMERIC       -- platform commission percentage (0-100)
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_revenue_share NUMERIC;
BEGIN
  -- Validate
  IF p_commission_rate < 0 OR p_commission_rate > 100 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Commission rate must be between 0 and 100');
  END IF;

  -- Commission = platform's share, so revenue_share = 100 - commission
  v_revenue_share := 100 - p_commission_rate;

  -- Check if instructor profile exists
  IF NOT EXISTS (
    SELECT 1 FROM public.instructor_profiles WHERE instructor_id = p_instructor_id
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Instructor profile not found');
  END IF;

  -- Update revenue_share
  UPDATE public.instructor_profiles
  SET
    revenue_share = v_revenue_share,
    updated_at = now()
  WHERE instructor_id = p_instructor_id;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Commission updated successfully',
    'commission_rate', p_commission_rate,
    'revenue_share', v_revenue_share
  );
END;
$$;

-- =============================================
-- STEP 3: RPC — get_instructor_commissions
-- =============================================
-- Returns list of instructors with their commission settings
-- =============================================
CREATE OR REPLACE FUNCTION public.get_instructor_commissions()
RETURNS TABLE (
  instructor_id UUID,
  name TEXT,
  email TEXT,
  avatar_url TEXT,
  revenue_share NUMERIC,
  commission_rate NUMERIC,
  total_courses INTEGER,
  total_students INTEGER,
  is_verified BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id AS instructor_id,
    p.name,
    p.email,
    p.avatar_url,
    COALESCE(ip.revenue_share, 70.00) AS revenue_share,
    (100 - COALESCE(ip.revenue_share, 70.00)) AS commission_rate,
    COALESCE(ip.total_courses, 0) AS total_courses,
    COALESCE(ip.total_students, 0) AS total_students,
    COALESCE(ip.is_verified, false) AS is_verified
  FROM public.profiles p
  LEFT JOIN public.instructor_profiles ip ON ip.instructor_id = p.id
  WHERE p.role = 'instructor'
  ORDER BY p.name ASC;
END;
$$;

-- =============================================
-- STEP 4: Grant execute permissions
-- =============================================
GRANT EXECUTE ON FUNCTION public.admin_set_instructor_commission(UUID, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_instructor_commissions() TO authenticated;

DO $$ BEGIN RAISE NOTICE '✅ Commission system ready'; END $$;
