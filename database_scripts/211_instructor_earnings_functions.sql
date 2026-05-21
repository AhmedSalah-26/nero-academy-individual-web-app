-- ============================================================
-- Instructor Earnings Functions
-- Functions to automatically calculate and sync earnings
-- ============================================================

-- 1. Function to create earning record when enrollment is created
-- This trigger will automatically add earnings when a paid enrollment happens
CREATE OR REPLACE FUNCTION create_instructor_earning()
RETURNS TRIGGER AS $$
DECLARE
    v_instructor_id UUID;
    v_course_price DECIMAL(10,2);
    v_revenue_share DECIMAL(5,2) := 70.00; -- Default 70% to instructor
    v_instructor_share DECIMAL(10,2);
    v_platform_fee DECIMAL(10,2);
BEGIN
    -- Only create earning for paid enrollments with active status
    IF NEW.price > 0 AND NEW.status = 'active' THEN
        -- Get instructor_id from course if not set
        IF NEW.instructor_id IS NULL THEN
            SELECT instructor_id INTO v_instructor_id
            FROM courses WHERE id = NEW.course_id;
        ELSE
            v_instructor_id := NEW.instructor_id;
        END IF;

        -- Check if earning already exists for this enrollment
        IF NOT EXISTS (SELECT 1 FROM instructor_earnings WHERE enrollment_id = NEW.id) THEN
            -- Calculate shares
            v_instructor_share := NEW.price * (v_revenue_share / 100);
            v_platform_fee := NEW.price - v_instructor_share;

            -- Insert earning record
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
            ) VALUES (
                v_instructor_id,
                NEW.id,
                NEW.course_id,
                NEW.price,
                v_platform_fee,
                v_instructor_share,
                v_revenue_share,
                'available', -- Make available immediately
                NOW(),
                COALESCE(NEW.enrolled_at, NOW())
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on enrollments table
DROP TRIGGER IF EXISTS trigger_create_instructor_earning ON enrollments;
CREATE TRIGGER trigger_create_instructor_earning
    AFTER INSERT OR UPDATE ON enrollments
    FOR EACH ROW
    EXECUTE FUNCTION create_instructor_earning();


-- 2. Function to sync all missing earnings (for existing enrollments)
CREATE OR REPLACE FUNCTION sync_all_instructor_earnings()
RETURNS JSON AS $$
DECLARE
    v_count INTEGER := 0;
    v_enrollment RECORD;
    v_revenue_share DECIMAL(5,2) := 70.00;
    v_instructor_share DECIMAL(10,2);
    v_platform_fee DECIMAL(10,2);
BEGIN
    -- Loop through all paid enrollments without earnings
    FOR v_enrollment IN 
        SELECT 
            e.id as enrollment_id,
            e.course_id,
            e.instructor_id,
            e.price,
            e.enrolled_at,
            c.instructor_id as course_instructor_id
        FROM enrollments e
        JOIN courses c ON c.id = e.course_id
        WHERE e.price > 0
          AND e.status = 'active'
          AND NOT EXISTS (
              SELECT 1 FROM instructor_earnings ie 
              WHERE ie.enrollment_id = e.id
          )
    LOOP
        -- Calculate shares
        v_instructor_share := v_enrollment.price * (v_revenue_share / 100);
        v_platform_fee := v_enrollment.price - v_instructor_share;

        -- Insert earning record
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
        ) VALUES (
            COALESCE(v_enrollment.instructor_id, v_enrollment.course_instructor_id),
            v_enrollment.enrollment_id,
            v_enrollment.course_id,
            v_enrollment.price,
            v_platform_fee,
            v_instructor_share,
            v_revenue_share,
            'available',
            NOW(),
            COALESCE(v_enrollment.enrolled_at, NOW())
        );

        v_count := v_count + 1;
    END LOOP;

    RETURN json_build_object(
        'success', true,
        'synced_count', v_count,
        'message', format('Synced %s earnings records', v_count)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 3. Function to get instructor earnings summary
CREATE OR REPLACE FUNCTION get_instructor_earnings_summary(p_instructor_id UUID DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    v_instructor_id UUID;
    v_result JSON;
BEGIN
    -- Use provided instructor_id or current user
    v_instructor_id := COALESCE(p_instructor_id, auth.uid());

    SELECT json_build_object(
        'total_earnings', COALESCE(SUM(net_amount), 0),
        'available_balance', COALESCE(SUM(CASE WHEN status = 'available' THEN net_amount ELSE 0 END), 0),
        'pending_balance', COALESCE(SUM(CASE WHEN status = 'pending' THEN net_amount ELSE 0 END), 0),
        'paid_amount', COALESCE(SUM(CASE WHEN status = 'paid' THEN net_amount ELSE 0 END), 0),
        'total_sales', COUNT(*),
        'this_month_earnings', COALESCE(SUM(CASE WHEN created_at >= DATE_TRUNC('month', NOW()) THEN net_amount ELSE 0 END), 0),
        'last_month_earnings', COALESCE(SUM(CASE WHEN created_at >= DATE_TRUNC('month', NOW() - INTERVAL '1 month') AND created_at < DATE_TRUNC('month', NOW()) THEN net_amount ELSE 0 END), 0)
    ) INTO v_result
    FROM instructor_earnings
    WHERE instructor_id = v_instructor_id;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 4. Function to get instructor revenue chart data
CREATE OR REPLACE FUNCTION get_instructor_revenue_chart(
    p_start_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
    p_end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
    label TEXT,
    value DECIMAL(10,2)
) AS $$
DECLARE
    v_instructor_id UUID := auth.uid();
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(DATE_TRUNC('day', ie.created_at), 'MM/DD') as label,
        COALESCE(SUM(ie.net_amount), 0)::DECIMAL(10,2) as value
    FROM generate_series(
        DATE_TRUNC('day', p_start_date),
        DATE_TRUNC('day', p_end_date),
        '1 day'::INTERVAL
    ) as dates(date)
    LEFT JOIN instructor_earnings ie ON 
        DATE_TRUNC('day', ie.created_at) = dates.date
        AND ie.instructor_id = v_instructor_id
    GROUP BY dates.date
    ORDER BY dates.date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 5. Function to get instructor enrollments chart data
CREATE OR REPLACE FUNCTION get_instructor_enrollments_chart(
    p_start_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
    p_end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
    label TEXT,
    value DECIMAL(10,2)
) AS $$
DECLARE
    v_instructor_id UUID := auth.uid();
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(DATE_TRUNC('day', dates.date), 'MM/DD') as label,
        COUNT(e.id)::DECIMAL(10,2) as value
    FROM generate_series(
        DATE_TRUNC('day', p_start_date),
        DATE_TRUNC('day', p_end_date),
        '1 day'::INTERVAL
    ) as dates(date)
    LEFT JOIN enrollments e ON 
        DATE_TRUNC('day', e.enrolled_at) = dates.date
        AND e.instructor_id = v_instructor_id
    GROUP BY dates.date
    ORDER BY dates.date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 6. Update the get_instructor_dashboard_stats function to include real earnings
CREATE OR REPLACE FUNCTION get_instructor_dashboard_stats()
RETURNS JSON AS $$
DECLARE
    v_instructor_id UUID := auth.uid();
    v_stats JSON;
BEGIN
    SELECT json_build_object(
        'total_courses', (SELECT COUNT(*) FROM courses WHERE instructor_id = v_instructor_id),
        'published_courses', (SELECT COUNT(*) FROM courses WHERE instructor_id = v_instructor_id AND is_published = true),
        'total_students', (SELECT COUNT(DISTINCT e.user_id) FROM enrollments e JOIN courses c ON c.id = e.course_id WHERE c.instructor_id = v_instructor_id),
        'total_enrollments', (SELECT COUNT(*) FROM enrollments e JOIN courses c ON c.id = e.course_id WHERE c.instructor_id = v_instructor_id),
        'monthly_enrollments', (SELECT COUNT(*) FROM enrollments e JOIN courses c ON c.id = e.course_id WHERE c.instructor_id = v_instructor_id AND e.enrolled_at >= DATE_TRUNC('month', NOW())),
        'total_earnings', COALESCE((SELECT SUM(net_amount) FROM instructor_earnings WHERE instructor_id = v_instructor_id AND status IN ('available', 'paid')), 0),
        'available_balance', COALESCE((SELECT SUM(net_amount) FROM instructor_earnings WHERE instructor_id = v_instructor_id AND status = 'available'), 0),
        'pending_balance', COALESCE((SELECT SUM(net_amount) FROM instructor_earnings WHERE instructor_id = v_instructor_id AND status = 'pending'), 0),
        'this_month_earnings', COALESCE((SELECT SUM(net_amount) FROM instructor_earnings WHERE instructor_id = v_instructor_id AND created_at >= DATE_TRUNC('month', NOW())), 0),
        'average_rating', COALESCE((SELECT AVG(cr.rating) FROM course_reviews cr JOIN courses c ON c.id = cr.course_id WHERE c.instructor_id = v_instructor_id), 0),
        'total_reviews', (SELECT COUNT(*) FROM course_reviews cr JOIN courses c ON c.id = cr.course_id WHERE c.instructor_id = v_instructor_id),
        'unanswered_questions', (SELECT COUNT(*) FROM qa_questions q JOIN courses c ON c.id = q.course_id WHERE c.instructor_id = v_instructor_id AND q.is_answered = false)
    ) INTO v_stats;

    RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 7. Run sync to add earnings for existing enrollments
SELECT sync_all_instructor_earnings();

-- 8. Verify the data
SELECT 
    ie.id,
    ie.instructor_id,
    ie.course_id,
    ie.gross_amount,
    ie.net_amount,
    ie.status,
    c.title_ar as course_title,
    p.name as instructor_name
FROM instructor_earnings ie
JOIN courses c ON c.id = ie.course_id
JOIN profiles p ON p.id = ie.instructor_id
ORDER BY ie.created_at DESC
LIMIT 20;
