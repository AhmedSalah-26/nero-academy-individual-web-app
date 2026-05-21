-- =====================================================
-- Fix: disabling course group should remove all group chats
-- =====================================================
-- Use this if 305 was already applied before this fix.

BEGIN;

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
        SELECT conv.id
        INTO v_conversation_id
        FROM public.conversations conv
        WHERE conv.course_id = p_course_id
          AND conv.type = 'multi'
        ORDER BY conv.created_at ASC
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

        INSERT INTO public.conversation_participants (conversation_id, user_id, role)
        VALUES (v_conversation_id, v_course_instructor, 'admin')
        ON CONFLICT (conversation_id, user_id) DO UPDATE
        SET role = 'admin';

        INSERT INTO public.conversation_participants (conversation_id, user_id, role)
        VALUES (v_conversation_id, v_caller, 'admin')
        ON CONFLICT (conversation_id, user_id) DO NOTHING;

        -- remove any accidental duplicate multi groups for same course
        DELETE FROM public.conversations
        WHERE course_id = p_course_id
          AND type = 'multi'
          AND id <> v_conversation_id;

        RETURN v_conversation_id;
    END IF;

    -- IMPORTANT: remove all multi groups for this course
    DELETE FROM public.conversations
    WHERE course_id = p_course_id
      AND type = 'multi';

    RETURN NULL;
END;
$$;

COMMIT;
