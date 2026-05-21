-- =====================================================
-- Instructor Forum Group Management
-- =====================================================
-- Adds RPC functions so instructors can enable/disable a course group
-- from the forums tab in instructor dashboard.

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

CREATE OR REPLACE FUNCTION public.set_course_group_enabled(
    p_course_id UUID,
    p_enabled BOOLEAN
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_course_instructor UUID;
    v_conversation_id UUID;
    v_is_admin BOOLEAN := FALSE;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT c.instructor_id
    INTO v_course_instructor
    FROM public.courses c
    WHERE c.id = p_course_id;

    IF v_course_instructor IS NULL THEN
        RAISE EXCEPTION 'Course not found';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = v_caller AND p.role = 'admin'
    ) INTO v_is_admin;

    IF v_caller <> v_course_instructor AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF p_enabled THEN
        -- Create group conversation if missing
        SELECT conv.id
        INTO v_conversation_id
        FROM public.conversations conv
        WHERE conv.course_id = p_course_id
          AND conv.type = 'multi'
        LIMIT 1;

        IF v_conversation_id IS NULL THEN
            INSERT INTO public.conversations (type, course_id, title, created_by)
            SELECT
                'multi',
                c.id,
                COALESCE(c.title_ar, c.title_en, 'Course Forum'),
                COALESCE(c.instructor_id, v_caller)
            FROM public.courses c
            WHERE c.id = p_course_id
            RETURNING id INTO v_conversation_id;
        END IF;

        -- Ensure instructor is participant admin
        INSERT INTO public.conversation_participants (conversation_id, user_id, role)
        VALUES (v_conversation_id, v_course_instructor, 'admin')
        ON CONFLICT (conversation_id, user_id) DO UPDATE
        SET role = 'admin';

        -- Ensure caller is participant too (useful for admin operations)
        INSERT INTO public.conversation_participants (conversation_id, user_id, role)
        VALUES (v_conversation_id, v_caller, 'admin')
        ON CONFLICT (conversation_id, user_id) DO NOTHING;

        RETURN v_conversation_id;
    END IF;

    -- Disable group by deleting ALL multi conversations for this course
    -- (safety for any legacy duplicated rows)
    DELETE FROM public.conversations
    WHERE course_id = p_course_id
      AND type = 'multi';

    RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.set_course_group_enabled(UUID, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_course_group_enabled(UUID, BOOLEAN) TO authenticated;

COMMIT;
