-- ============================================================
-- 339: FIX DASHBOARD STATS FOR NEW EARNINGS SCHEMA
-- ============================================================
-- Updates get_instructor_dashboard_stats to use total_earnings
-- instead of total_earned (column name changed in new schema)
-- ============================================================

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
    
    -- Get earnings from instructor_balance table (using total_earnings column)
    SELECT 
        COALESCE(total_earnings, 0),
        COALESCE(available_balance, 0),
        COALESCE(pending_balance, 0)
    INTO v_total_earnings, v_available_balance, v_pending_balance
    FROM instructor_balance
    WHERE instructor_id = v_instructor_id;
    
    -- If no balance record exists, use 0
    IF v_total_earnings IS NULL THEN
        v_total_earnings := 0;
        v_available_balance := 0;
        v_pending_balance := 0;
    END IF;
    
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

GRANT EXECUTE ON FUNCTION get_instructor_dashboard_stats() TO authenticated;

COMMENT ON FUNCTION get_instructor_dashboard_stats IS 'Returns instructor dashboard statistics using new earnings schema';

-- ============================================================
-- ✅ DONE: Dashboard stats now uses total_earnings column
-- ============================================================
