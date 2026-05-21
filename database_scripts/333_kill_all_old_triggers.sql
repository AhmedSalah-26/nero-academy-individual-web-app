-- =============================================
-- 333: KILL ALL OLD EARNINGS TRIGGERS
-- Run this FIRST before anything else
-- =============================================

-- Drop ALL possible trigger names on enrollments
DROP TRIGGER IF EXISTS trigger_create_instructor_earning ON public.enrollments;
DROP TRIGGER IF EXISTS create_instructor_earning_trigger ON public.enrollments;
DROP TRIGGER IF EXISTS trigger_auto_create_earning ON public.enrollments;
DROP TRIGGER IF EXISTS auto_create_earning_trigger ON public.enrollments;
DROP TRIGGER IF EXISTS trigger_handle_enrollment_earning ON public.enrollments;
DROP TRIGGER IF EXISTS handle_enrollment_earning_trigger ON public.enrollments;
DROP TRIGGER IF EXISTS trg_instructor_earning ON public.enrollments;
DROP TRIGGER IF EXISTS trigger_instructor_earning ON public.enrollments;

-- Drop ALL possible trigger functions
DROP FUNCTION IF EXISTS public.create_instructor_earning() CASCADE;
DROP FUNCTION IF EXISTS public.auto_create_earning() CASCADE;
DROP FUNCTION IF EXISTS public.handle_enrollment_earning() CASCADE;
DROP FUNCTION IF EXISTS public.update_instructor_balance_on_earning() CASCADE;
DROP FUNCTION IF EXISTS public.update_balance_on_payout() CASCADE;

-- Drop ALL triggers on instructor_earnings (if table somehow still exists)
DO $$
DECLARE r RECORD;
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'instructor_earnings') THEN
    FOR r IN (
      SELECT trigger_name FROM information_schema.triggers
      WHERE event_object_table = 'instructor_earnings' AND event_object_schema = 'public'
    ) LOOP
      EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.instructor_earnings CASCADE', r.trigger_name);
      RAISE NOTICE 'Dropped trigger on instructor_earnings: %', r.trigger_name;
    END LOOP;
  END IF;
  
  -- Also drop any remaining triggers on enrollments that have 'earning' in the name
  FOR r IN (
    SELECT trigger_name FROM information_schema.triggers
    WHERE event_object_table = 'enrollments' 
    AND event_object_schema = 'public'
    AND (
      trigger_name ILIKE '%earning%' 
      OR trigger_name ILIKE '%payout%'
      OR trigger_name ILIKE '%instructor_earn%'
    )
  ) LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.enrollments CASCADE', r.trigger_name);
    RAISE NOTICE 'Dropped trigger on enrollments: %', r.trigger_name;
  END LOOP;
END $$;

-- Verify: Show remaining triggers on enrollments
SELECT trigger_name, event_manipulation, action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'enrollments' 
AND event_object_schema = 'public';
