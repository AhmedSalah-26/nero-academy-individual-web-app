-- =====================================================
-- Course Forums Management: separate management features
-- - Rename group
-- - Set member role (admin/member)
-- - Remove member
-- - Ban / Unban member
-- =====================================================

BEGIN;

-- Persistent bans per course group
CREATE TABLE IF NOT EXISTS public.course_group_bans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    banned_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reason TEXT,
    banned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(course_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_course_group_bans_course ON public.course_group_bans(course_id);
CREATE INDEX IF NOT EXISTS idx_course_group_bans_user ON public.course_group_bans(user_id);

ALTER TABLE public.course_group_bans ENABLE ROW LEVEL SECURITY;

-- Keep table private to clients; only SECURITY DEFINER functions should access it.
REVOKE ALL ON TABLE public.course_group_bans FROM PUBLIC;
REVOKE ALL ON TABLE public.course_group_bans FROM authenticated;

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
        ON CONFLICT (conversation_id, user_id) DO UPDATE
        SET role = 'admin';

        -- Add enrolled users except banned ones.
        INSERT INTO public.conversation_participants (conversation_id, user_id, role)
        SELECT DISTINCT
            v_conversation_id,
            e.user_id,
            'member'
        FROM public.enrollments e
        WHERE e.course_id = p_course_id
          AND e.status IN ('active', 'completed')
          AND NOT EXISTS (
              SELECT 1
              FROM public.course_group_bans b
              WHERE b.course_id = p_course_id
                AND b.user_id = e.user_id
          )
        ON CONFLICT (conversation_id, user_id) DO NOTHING;

        DELETE FROM public.conversations
        WHERE course_id = p_course_id
          AND type = 'multi'
          AND id <> v_conversation_id;

        RETURN v_conversation_id;
    END IF;

    DELETE FROM public.conversations
    WHERE course_id = p_course_id
      AND type = 'multi';

    RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.set_course_group_enabled(UUID, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_course_group_enabled(UUID, BOOLEAN) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_user_conversations(
    p_user_id UUID,
    p_type TEXT DEFAULT NULL
)
RETURNS TABLE (
    conversation_id UUID,
    conversation_type VARCHAR(10),
    conversation_title TEXT,
    course_id UUID,
    created_at TIMESTAMPTZ,
    last_message_id UUID,
    last_message_text TEXT,
    last_message_user_id UUID,
    last_message_user_name TEXT,
    last_message_created_at TIMESTAMPTZ,
    participants_count BIGINT,
    other_user_name TEXT,
    other_user_avatar TEXT
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

    INSERT INTO public.conversation_participants (conversation_id, user_id, role)
    SELECT
        c.id,
        p_user_id,
        CASE
            WHEN cr.instructor_id = p_user_id THEN 'admin'
            ELSE 'member'
        END
    FROM public.conversations c
    JOIN public.courses cr ON cr.id = c.course_id
    WHERE c.type = 'multi'
      AND NOT EXISTS (
          SELECT 1
          FROM public.course_group_bans b
          WHERE b.course_id = c.course_id
            AND b.user_id = p_user_id
      )
      AND (
          cr.instructor_id = p_user_id
          OR EXISTS (
              SELECT 1
              FROM public.enrollments e
              WHERE e.course_id = c.course_id
                AND e.user_id = p_user_id
                AND e.status IN ('active', 'completed')
          )
      )
    ON CONFLICT ON CONSTRAINT conversation_participants_conversation_id_user_id_key DO UPDATE
    SET role = CASE
        WHEN EXCLUDED.role = 'admin' THEN 'admin'
        ELSE conversation_participants.role
    END;

    RETURN QUERY
    SELECT
        c.id AS conversation_id,
        c.type AS conversation_type,
        c.title AS conversation_title,
        c.course_id,
        c.created_at,
        lm.id AS last_message_id,
        lm.message_text AS last_message_text,
        lm.user_id AS last_message_user_id,
        p_sender.name AS last_message_user_name,
        lm.created_at AS last_message_created_at,
        (SELECT COUNT(*) FROM public.conversation_participants cp2 WHERE cp2.conversation_id = c.id) AS participants_count,
        CASE WHEN c.type = 'single' THEN (
            SELECT p_other.name FROM public.conversation_participants cp_other
            JOIN public.profiles p_other ON p_other.id = cp_other.user_id
            WHERE cp_other.conversation_id = c.id AND cp_other.user_id <> p_user_id
            LIMIT 1
        ) ELSE NULL END AS other_user_name,
        CASE WHEN c.type = 'single' THEN (
            SELECT p_other.avatar_url FROM public.conversation_participants cp_other
            JOIN public.profiles p_other ON p_other.id = cp_other.user_id
            WHERE cp_other.conversation_id = c.id AND cp_other.user_id <> p_user_id
            LIMIT 1
        ) ELSE NULL END AS other_user_avatar
    FROM public.conversations c
    JOIN public.conversation_participants cp ON cp.conversation_id = c.id AND cp.user_id = p_user_id
    LEFT JOIN LATERAL (
        SELECT m.id, m.message_text, m.user_id, m.created_at
        FROM public.messages m
        WHERE m.conversation_id = c.id AND m.is_deleted = FALSE
        ORDER BY m.created_at DESC
        LIMIT 1
    ) lm ON TRUE
    LEFT JOIN public.profiles p_sender ON p_sender.id = lm.user_id
    WHERE (p_type IS NULL OR c.type = p_type)
    ORDER BY COALESCE(lm.created_at, c.created_at) DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_user_conversations(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_conversations(UUID, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.update_course_group_title(
    p_course_id UUID,
    p_title TEXT
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
    v_new_title TEXT;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    v_new_title := NULLIF(BTRIM(p_title), '');
    IF v_new_title IS NULL THEN
        RAISE EXCEPTION 'Title cannot be empty';
    END IF;

    SELECT c.instructor_id
    INTO v_course_instructor
    FROM public.courses c
    WHERE c.id = p_course_id;

    IF v_course_instructor IS NULL THEN
        RAISE EXCEPTION 'Course not found';
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = v_caller AND p.role = 'admin'
    ) INTO v_is_admin;

    IF v_caller <> v_course_instructor AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    SELECT conv.id
    INTO v_conversation_id
    FROM public.conversations conv
    WHERE conv.course_id = p_course_id
      AND conv.type = 'multi'
    LIMIT 1;

    IF v_conversation_id IS NULL THEN
        RAISE EXCEPTION 'Group not enabled';
    END IF;

    UPDATE public.conversations
    SET title = v_new_title,
        updated_at = NOW()
    WHERE id = v_conversation_id;

    RETURN v_conversation_id;
END;
$$;

REVOKE ALL ON FUNCTION public.update_course_group_title(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_course_group_title(UUID, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_course_group_members(
    p_course_id UUID
)
RETURNS TABLE (
    conversation_id UUID,
    conversation_title TEXT,
    user_id UUID,
    user_name TEXT,
    user_avatar TEXT,
    role TEXT,
    is_banned BOOLEAN,
    banned_reason TEXT,
    banned_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_course_instructor UUID;
    v_is_admin BOOLEAN := FALSE;
    v_conversation_id UUID;
    v_conversation_title TEXT;
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
        SELECT 1 FROM public.profiles p
        WHERE p.id = v_caller AND p.role = 'admin'
    ) INTO v_is_admin;

    IF v_caller <> v_course_instructor AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    SELECT conv.id, conv.title
    INTO v_conversation_id, v_conversation_title
    FROM public.conversations conv
    WHERE conv.course_id = p_course_id
      AND conv.type = 'multi'
    LIMIT 1;

    RETURN QUERY
    SELECT
        v_conversation_id AS conversation_id,
        v_conversation_title AS conversation_title,
        cp.user_id,
        COALESCE(pr.name, 'Unknown') AS user_name,
        pr.avatar_url AS user_avatar,
        cp.role::TEXT,
        FALSE AS is_banned,
        NULL::TEXT AS banned_reason,
        NULL::TIMESTAMPTZ AS banned_at
    FROM public.conversation_participants cp
    LEFT JOIN public.profiles pr ON pr.id = cp.user_id
    WHERE cp.conversation_id = v_conversation_id

    UNION ALL

    SELECT
        v_conversation_id AS conversation_id,
        v_conversation_title AS conversation_title,
        b.user_id,
        COALESCE(pr.name, 'Unknown') AS user_name,
        pr.avatar_url AS user_avatar,
        'banned'::TEXT AS role,
        TRUE AS is_banned,
        b.reason AS banned_reason,
        b.banned_at
    FROM public.course_group_bans b
    LEFT JOIN public.profiles pr ON pr.id = b.user_id
    WHERE b.course_id = p_course_id
      AND NOT EXISTS (
          SELECT 1
          FROM public.conversation_participants cp
          WHERE cp.conversation_id = v_conversation_id
            AND cp.user_id = b.user_id
      )

    ORDER BY is_banned ASC, user_name ASC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_course_group_members(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_course_group_members(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.manage_course_group_member(
    p_course_id UUID,
    p_target_user_id UUID,
    p_action TEXT,
    p_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_course_instructor UUID;
    v_is_admin BOOLEAN := FALSE;
    v_conversation_id UUID;
    v_action TEXT := LOWER(COALESCE(p_action, ''));
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
        SELECT 1 FROM public.profiles p
        WHERE p.id = v_caller AND p.role = 'admin'
    ) INTO v_is_admin;

    IF v_caller <> v_course_instructor AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF p_target_user_id IS NULL THEN
        RAISE EXCEPTION 'Target user is required';
    END IF;

    IF p_target_user_id = v_course_instructor AND v_action IN ('remove', 'ban', 'member') THEN
        RAISE EXCEPTION 'Cannot change instructor core role';
    END IF;

    SELECT conv.id
    INTO v_conversation_id
    FROM public.conversations conv
    WHERE conv.course_id = p_course_id
      AND conv.type = 'multi'
    LIMIT 1;

    IF v_action IN ('admin', 'member', 'remove', 'ban') AND v_conversation_id IS NULL THEN
        RAISE EXCEPTION 'Group not enabled';
    END IF;

    IF v_action = 'admin' THEN
        DELETE FROM public.course_group_bans
        WHERE course_id = p_course_id
          AND user_id = p_target_user_id;

        INSERT INTO public.conversation_participants (conversation_id, user_id, role)
        VALUES (v_conversation_id, p_target_user_id, 'admin')
        ON CONFLICT (conversation_id, user_id) DO UPDATE
        SET role = 'admin';

        RETURN TRUE;
    ELSIF v_action = 'member' THEN
        DELETE FROM public.course_group_bans
        WHERE course_id = p_course_id
          AND user_id = p_target_user_id;

        INSERT INTO public.conversation_participants (conversation_id, user_id, role)
        VALUES (v_conversation_id, p_target_user_id, 'member')
        ON CONFLICT (conversation_id, user_id) DO UPDATE
        SET role = 'member';

        RETURN TRUE;
    ELSIF v_action = 'remove' THEN
        DELETE FROM public.conversation_participants
        WHERE conversation_id = v_conversation_id
          AND user_id = p_target_user_id;

        RETURN TRUE;
    ELSIF v_action = 'ban' THEN
        INSERT INTO public.course_group_bans (course_id, user_id, banned_by, reason, banned_at)
        VALUES (p_course_id, p_target_user_id, v_caller, NULLIF(BTRIM(p_reason), ''), NOW())
        ON CONFLICT (course_id, user_id) DO UPDATE
        SET banned_by = EXCLUDED.banned_by,
            reason = EXCLUDED.reason,
            banned_at = EXCLUDED.banned_at;

        DELETE FROM public.conversation_participants
        WHERE conversation_id = v_conversation_id
          AND user_id = p_target_user_id;

        RETURN TRUE;
    ELSIF v_action = 'unban' THEN
        DELETE FROM public.course_group_bans
        WHERE course_id = p_course_id
          AND user_id = p_target_user_id;

        IF v_conversation_id IS NOT NULL THEN
            INSERT INTO public.conversation_participants (conversation_id, user_id, role)
            SELECT
                v_conversation_id,
                p_target_user_id,
                CASE WHEN p_target_user_id = v_course_instructor THEN 'admin' ELSE 'member' END
            WHERE p_target_user_id = v_course_instructor
               OR EXISTS (
                    SELECT 1
                    FROM public.enrollments e
                    WHERE e.course_id = p_course_id
                      AND e.user_id = p_target_user_id
                      AND e.status IN ('active', 'completed')
               )
            ON CONFLICT (conversation_id, user_id) DO NOTHING;
        END IF;

        RETURN TRUE;
    END IF;

    RAISE EXCEPTION 'Unsupported action: %', p_action;
END;
$$;

REVOKE ALL ON FUNCTION public.manage_course_group_member(UUID, UUID, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.manage_course_group_member(UUID, UUID, TEXT, TEXT) TO authenticated;

COMMIT;

