-- Fix get_instructor_enrollments_chart function
-- The function was using single $ instead of $$ for function body delimiter

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
