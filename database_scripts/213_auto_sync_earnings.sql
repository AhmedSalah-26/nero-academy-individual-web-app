-- ============================================================
-- Auto Sync Earnings - Fix Missing Earnings Records
-- Run this script in Supabase SQL Editor
-- ============================================================

-- 1. First, check if instructor_earnings table exists and has correct structure
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'instructor_earnings') THEN
        RAISE EXCEPTION 'instructor_earnings table does not exist! Run the schema script first.';
    END IF;
END $$;

-- 2. Check current state
SELECT 'Current enrollments count:' as info, COUNT(*) as count FROM enrollments WHERE price > 0;
SELECT 'Current earnings count:' as info, COUNT(*) as count FROM instructor_earnings;

-- 3. Sync all missing earnings from existing paid enrollments
INSERT INTO instructor_earnings (
    instructor_id,
    enrollment_id,
    course_id,
    gross_amount,
    platform_fee,
    net_amount,
    revenue_share,
    status,
    available_at,
    created_at
)
SELECT 
    COALESCE(e.instructor_id, c.instructor_id) as instructor_id,
    e.id as enrollment_id,
    e.course_id,
    e.price as gross_amount,
    e.price * 0.30 as platform_fee,  -- 30% platform fee
    e.price * 0.70 as net_amount,     -- 70% to instructor
    70.00 as revenue_share,
    'available' as status,
    NOW() as available_at,
    COALESCE(e.enrolled_at, e.created_at, NOW()) as created_at
FROM enrollments e
JOIN courses c ON c.id = e.course_id
WHERE e.price > 0
  AND e.status = 'active'
  AND NOT EXISTS (
      SELECT 1 FROM instructor_earnings ie 
      WHERE ie.enrollment_id = e.id
  );

-- 4. Show results after sync
SELECT 'After sync - earnings count:' as info, COUNT(*) as count FROM instructor_earnings;

-- 5. Show earnings by instructor
SELECT 
    p.name as instructor_name,
    COUNT(*) as total_sales,
    SUM(ie.gross_amount) as total_revenue,
    SUM(ie.net_amount) as total_earnings,
    SUM(ie.platform_fee) as total_platform_fee
FROM instructor_earnings ie
JOIN profiles p ON p.id = ie.instructor_id
GROUP BY p.id, p.name
ORDER BY total_earnings DESC;

-- 6. Create or replace the trigger function for auto-creating earnings
CREATE OR REPLACE FUNCTION auto_create_instructor_earning()
RETURNS TRIGGER AS $$
DECLARE
    v_instructor_id UUID;
    v_revenue_share DECIMAL(5,2) := 70.00;
    v_instructor_share DECIMAL(10,2);
    v_platform_fee DECIMAL(10,2);
BEGIN
    -- Only for paid enrollments with active status
    IF NEW.price > 0 AND NEW.status = 'active' THEN
        -- Get instructor_id
        v_instructor_id := COALESCE(NEW.instructor_id, (SELECT instructor_id FROM courses WHERE id = NEW.course_id));

        -- Check if earning already exists
        IF NOT EXISTS (SELECT 1 FROM instructor_earnings WHERE enrollment_id = NEW.id) THEN
            -- Calculate shares
            v_instructor_share := NEW.price * (v_revenue_share / 100);
            v_platform_fee := NEW.price - v_instructor_share;

            -- Insert earning
            INSERT INTO instructor_earnings (
                instructor_id, enrollment_id, course_id,
                gross_amount, platform_fee, net_amount,
                revenue_share, status, available_at, created_at
            ) VALUES (
                v_instructor_id, NEW.id, NEW.course_id,
                NEW.price, v_platform_fee, v_instructor_share,
                v_revenue_share, 'available', NOW(), COALESCE(NEW.enrolled_at, NOW())
            );
            
            RAISE NOTICE 'Created earning for enrollment %', NEW.id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Drop and recreate trigger
DROP TRIGGER IF EXISTS trigger_auto_create_earning ON enrollments;
CREATE TRIGGER trigger_auto_create_earning
    AFTER INSERT ON enrollments
    FOR EACH ROW
    EXECUTE FUNCTION auto_create_instructor_earning();

-- 8. Grant necessary permissions
GRANT EXECUTE ON FUNCTION auto_create_instructor_earning() TO authenticated;

-- 9. Verify trigger exists
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_auto_create_earning';

SELECT '✅ Earnings sync completed! Trigger created for auto-sync on new enrollments.' as status;
