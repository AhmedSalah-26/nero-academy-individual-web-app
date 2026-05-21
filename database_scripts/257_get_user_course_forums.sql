-- =====================================================
-- Function to Get User's Course Forums
-- Returns all courses the user is enrolled in with forum info
-- =====================================================

CREATE OR REPLACE FUNCTION get_user_course_forums(p_user_id UUID)
RETURNS TABLE (
    course_id UUID,
    course_title_ar TEXT,
    course_title_en TEXT,
    course_thumbnail TEXT,
    instructor_id UUID,
    instructor_name TEXT,
    participants_count BIGINT,
    last_message_id UUID,
    last_message_text TEXT,
    last_message_user_id UUID,
    last_message_user_name TEXT,
    last_message_created_at TIMESTAMPTZ,
    unread_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id AS course_id,
        c.title_ar AS course_title_ar,
        c.title_en AS course_title_en,
        c.thumbnail_url AS course_thumbnail,
        c.instructor_id,
        p_instructor.full_name AS instructor_name,
        -- Count of enrolled students (participants)
        (SELECT COUNT(DISTINCT e.user_id)
         FROM enrollments e
         WHERE e.course_id = c.id
         AND e.status = 'active') AS participants_count,
        -- Last message info
        lm.id AS last_message_id,
        lm.message_text AS last_message_text,
        lm.user_id AS last_message_user_id,
        p_sender.full_name AS last_message_user_name,
        lm.created_at AS last_message_created_at,
        -- Unread count
        (SELECT COUNT(*)
         FROM course_forum_messages m
         WHERE m.course_id = c.id
         AND m.user_id != p_user_id
         AND NOT EXISTS (
             SELECT 1 FROM course_forum_read_receipts r
             WHERE r.message_id = m.id
             AND r.user_id = p_user_id
         )) AS unread_count
    FROM courses c
    INNER JOIN enrollments e ON e.course_id = c.id
    INNER JOIN profiles p_instructor ON p_instructor.id = c.instructor_id
    LEFT JOIN LATERAL (
        SELECT m.id, m.message_text, m.user_id, m.created_at
        FROM course_forum_messages m
        WHERE m.course_id = c.id
        AND m.is_deleted = FALSE
        ORDER BY m.created_at DESC
        LIMIT 1
    ) lm ON TRUE
    LEFT JOIN profiles p_sender ON p_sender.id = lm.user_id
    WHERE e.user_id = p_user_id
    AND e.status = 'active'
    AND c.is_published = TRUE
    ORDER BY COALESCE(lm.created_at, c.created_at) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_user_course_forums(UUID) TO authenticated;

-- Example usage:
-- SELECT * FROM get_user_course_forums(auth.uid());
