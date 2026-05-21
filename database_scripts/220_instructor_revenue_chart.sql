-- ============================================================
-- Create get_instructor_revenue_chart function
-- ============================================================

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
        TO_CHAR(DATE_TRUNC('day', dates.date), 'MM/DD') as label,
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_instructor_revenue_chart(TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;

SELECT 'Instructor revenue chart function created!' as status;
