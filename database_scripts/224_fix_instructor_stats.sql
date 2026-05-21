-- Fix instructor dashboard stats (available balance & average rating)
-- Run this script to ensure stats are calculated correctly

-- 1. First, let's check if there are any earnings records
SELECT 
    'instructor_earnings' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN status = 'available' THEN 1 END) as available_count,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_count,
    COALESCE(SUM(CASE WHEN status = 'available' THEN net_amount END), 0) as total_available
FROM instructor_earnings;

-- 2. Check if there are any reviews
SELECT 
    'course_reviews' as table_name,
    COUNT(*) as total_reviews,
    COALESCE(AVG(rating), 0) as avg_rating
FROM course_reviews;

-- 3. Sync earnings from enrollments (if not already synced)
-- This will create earnings records for paid enrollments
DO $$
DECLARE
    v_enrollment RECORD;
    v_instructor_id UUID;
    v_platform_fee_percent NUMERIC := 0.20; -- 20% platform fee
    v_gross_amount NUMERIC;
    v_net_amount NUMERIC;
    v_synced_count INT := 0;
BEGIN
    FOR v_enrollment IN 
        SELECT 
            e.id as enrollment_id,
            e.course_id,
            e.user_id as student_id,
            e.price,
            e.enrolled_at,
            c.instructor_id
        FROM enrollments e
        JOIN courses c ON c.id = e.course_id
        WHERE e.price > 0
        AND NOT EXISTS (
            SELECT 1 FROM instructor_earnings ie 
            WHERE ie.enrollment_id = e.id
        )
    LOOP
        v_instructor_id := v_enrollment.instructor_id;
        v_gross_amount := v_enrollment.price;
        v_net_amount := v_gross_amount * (1 - v_platform_fee_percent);
        
        INSERT INTO instructor_earnings (
            instructor_id,
            course_id,
            enrollment_id,
            student_id,
            gross_amount,
            platform_fee_percent,
            platform_fee_amount,
            net_amount,
            status,
            available_at,
            created_at
        ) VALUES (
            v_instructor_id,
            v_enrollment.course_id,
            v_enrollment.enrollment_id,
            v_enrollment.student_id,
            v_gross_amount,
            v_platform_fee_percent,
            v_gross_amount * v_platform_fee_percent,
            v_net_amount,
            'available', -- Make it available immediately for testing
            NOW(),
            v_enrollment.enrolled_at
        );
        
        v_synced_count := v_synced_count + 1;
    END LOOP;
    
    RAISE NOTICE 'Synced % earnings records', v_synced_count;
END $$;

-- 4. Update the get_instructor_dashboard_stats function to handle edge cases
CREATE OR REPLACE FUNCTION get_instructor_dashboard_stats()
RETURNS JSON AS $$
DECLARE
    v_instructor_id UUID := auth.uid();
    v_stats JSON;
    v_total_courses INT;
    v_published_courses INT;
    v_total_students INT;
    v_total_enrollments INT;
    v_monthly_enrollments INT;
    v_total_earnings NUMERIC;
    v_available_balance NUMERIC;
    v_pending_balance NUMERIC;
    v_average_rating NUMERIC;
    v_total_reviews INT;
    v_unanswered_questions INT;
BEGIN
    -- Get course counts
    SELECT COUNT(*), COUNT(CASE WHEN is_published THEN 1 END)
    INTO v_total_courses, v_published_courses
    FROM courses WHERE instructor_id = v_instructor_id;
    
    -- Get student/enrollment counts
    SELECT 
        COUNT(DISTINCT e.user_id),
        COUNT(*),
        COUNT(CASE WHEN e.enrolled_at >= DATE_TRUNC('month', NOW()) THEN 1 END)
    INTO v_total_students, v_total_enrollments, v_monthly_enrollments
    FROM enrollments e 
    JOIN courses c ON c.id = e.course_id 
    WHERE c.instructor_id = v_instructor_id;
    
    -- Get earnings
    SELECT 
        COALESCE(SUM(CASE WHEN status IN ('available', 'paid') THEN net_amount END), 0),
        COALESCE(SUM(CASE WHEN status = 'available' THEN net_amount END), 0),
        COALESCE(SUM(CASE WHEN status = 'pending' THEN net_amount END), 0)
    INTO v_total_earnings, v_available_balance, v_pending_balance
    FROM instructor_earnings 
    WHERE instructor_id = v_instructor_id;
    
    -- Get ratings
    SELECT COALESCE(AVG(cr.rating), 0), COUNT(*)
    INTO v_average_rating, v_total_reviews
    FROM course_reviews cr 
    JOIN courses c ON c.id = cr.course_id 
    WHERE c.instructor_id = v_instructor_id;
    
    -- Get unanswered questions
    SELECT COUNT(*)
    INTO v_unanswered_questions
    FROM qa_questions q 
    JOIN courses c ON c.id = q.course_id 
    WHERE c.instructor_id = v_instructor_id AND q.is_answered = false;
    
    -- Build result
    v_stats := json_build_object(
        'total_courses', COALESCE(v_total_courses, 0),
        'published_courses', COALESCE(v_published_courses, 0),
        'total_students', COALESCE(v_total_students, 0),
        'total_enrollments', COALESCE(v_total_enrollments, 0),
        'monthly_enrollments', COALESCE(v_monthly_enrollments, 0),
        'total_earnings', COALESCE(v_total_earnings, 0),
        'available_balance', COALESCE(v_available_balance, 0),
        'pending_balance', COALESCE(v_pending_balance, 0),
        'average_rating', ROUND(COALESCE(v_average_rating, 0)::numeric, 1),
        'total_reviews', COALESCE(v_total_reviews, 0),
        'unanswered_questions', COALESCE(v_unanswered_questions, 0)
    );

    RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Verify the function works
-- SELECT get_instructor_dashboard_stats();

-- 6. Check final stats
SELECT 
    'After Fix' as status,
    (SELECT COUNT(*) FROM instructor_earnings) as total_earnings_records,
    (SELECT COALESCE(SUM(net_amount), 0) FROM instructor_earnings WHERE status = 'available') as available_balance,
    (SELECT COUNT(*) FROM course_reviews) as total_reviews,
    (SELECT COALESCE(AVG(rating), 0) FROM course_reviews) as avg_rating;
