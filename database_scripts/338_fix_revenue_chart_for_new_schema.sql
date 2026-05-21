-- ============================================================
-- 338: FIX REVENUE CHART FOR NEW EARNINGS SCHEMA
-- ============================================================
-- Updates get_instructor_revenue_chart to use earnings_transactions
-- instead of the old instructor_earnings table
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
        COALESCE(SUM(et.amount - et.commission - et.coupon_discount), 0)::DECIMAL(10,2) as value
    FROM generate_series(
        DATE_TRUNC('day', p_start_date),
        DATE_TRUNC('day', p_end_date),
        '1 day'::INTERVAL
    ) as dates(date)
    LEFT JOIN earnings_transactions et ON 
        DATE_TRUNC('day', et.created_at) = dates.date
        AND et.user_id = v_instructor_id
        AND et.source_type = 'course_sale'
    GROUP BY dates.date
    ORDER BY dates.date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_instructor_revenue_chart(TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;

-- ============================================================
-- ✅ DONE: Revenue chart now uses earnings_transactions
-- ============================================================
