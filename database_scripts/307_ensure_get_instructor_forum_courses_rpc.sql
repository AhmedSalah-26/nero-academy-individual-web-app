-- =====================================================
-- Ensure instructor forum courses RPC exists
-- =====================================================
-- Use this migration if app expects get_instructor_forum_courses RPC.

BEGIN;

CREATE OR REPLACE FUNCTION public.get_instructor_forum_courses(p_user_id UUID)
RETURNS TABLE (
    course_id UUID,
    title_ar TEXT,
    title_en TEXT,
    has_group BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_is_admin BOOLEAN := FALSE;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = v_caller AND p.role = 'admin'
    ) INTO v_is_admin;

    IF v_caller <> p_user_id AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    RETURN QUERY
    SELECT
        c.id AS course_id,
        c.title_ar,
        c.title_en,
        EXISTS (
            SELECT 1
            FROM public.conversations conv
            WHERE conv.course_id = c.id
              AND conv.type = 'multi'
        ) AS has_group
    FROM public.courses c
    WHERE c.instructor_id = p_user_id
    ORDER BY c.created_at DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_instructor_forum_courses(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_instructor_forum_courses(UUID) TO authenticated;

COMMIT;
