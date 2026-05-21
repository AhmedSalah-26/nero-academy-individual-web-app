-- =============================================================================
-- 312_fix_single_chat_display_name_and_admin_send_policy.sql
-- -----------------------------------------------------------------------------
-- Fixes:
-- 1) Ensure single chat list uses the other person's real identity with fallback
--    (name -> email -> phone), and ignores placeholder names.
-- 2) Allow admins to send messages in conversations they can moderate/view.
-- =============================================================================

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
            SELECT
                CASE
                    WHEN p_other.name IS NULL
                         OR BTRIM(p_other.name) = ''
                         OR BTRIM(p_other.name) IN ('Unknown', 'Unknown user', 'Chat', 'محادثة', 'مستخدم جديد')
                    THEN COALESCE(
                        NULLIF(BTRIM(p_other.email), ''),
                        NULLIF(BTRIM(p_other.phone), ''),
                        'Unknown'
                    )
                    ELSE p_other.name
                END
            FROM public.conversation_participants cp_other
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

DROP POLICY IF EXISTS "Participants can send messages" ON public.messages;
CREATE POLICY "Participants can send messages"
ON public.messages FOR INSERT
WITH CHECK (
    user_id = auth.uid()
    AND (
        public.is_conversation_participant(messages.conversation_id, auth.uid())
        OR EXISTS (
            SELECT 1
            FROM public.profiles p
            WHERE p.id = auth.uid()
              AND p.role = 'admin'
        )
    )
);
