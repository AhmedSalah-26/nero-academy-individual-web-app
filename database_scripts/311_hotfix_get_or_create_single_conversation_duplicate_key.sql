-- =============================================================================
-- 311_hotfix_get_or_create_single_conversation_duplicate_key.sql
-- -----------------------------------------------------------------------------
-- Fixes duplicate key errors in get_or_create_single_conversation by:
-- 1) Serializing pair creation with advisory lock
-- 2) Upserting participants safely with ON CONFLICT
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_or_create_single_conversation(
    p_user1_id UUID,
    p_user2_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_a UUID;
    v_user_b UUID;
    v_conversation_id UUID;
BEGIN
    IF p_user1_id IS NULL OR p_user2_id IS NULL THEN
        RAISE EXCEPTION 'Both user ids are required';
    END IF;

    IF p_user1_id = p_user2_id THEN
        RAISE EXCEPTION 'Cannot create single conversation with the same user';
    END IF;

    IF p_user1_id::text < p_user2_id::text THEN
        v_user_a := p_user1_id;
        v_user_b := p_user2_id;
    ELSE
        v_user_a := p_user2_id;
        v_user_b := p_user1_id;
    END IF;

    -- Prevent race conditions for the same pair within a transaction.
    PERFORM pg_advisory_xact_lock(hashtext(v_user_a::text), hashtext(v_user_b::text));

    -- Try to find an existing 1:1 conversation that contains both users.
    SELECT c.id
      INTO v_conversation_id
      FROM public.conversations c
     WHERE c.type = 'single'
       AND EXISTS (
           SELECT 1
             FROM public.conversation_participants cp
            WHERE cp.conversation_id = c.id
              AND cp.user_id = v_user_a
       )
       AND EXISTS (
           SELECT 1
             FROM public.conversation_participants cp
            WHERE cp.conversation_id = c.id
              AND cp.user_id = v_user_b
       )
     ORDER BY c.created_at ASC
     LIMIT 1;

    IF v_conversation_id IS NULL THEN
        INSERT INTO public.conversations (type, created_by)
        VALUES ('single', p_user1_id)
        RETURNING id INTO v_conversation_id;
    END IF;

    INSERT INTO public.conversation_participants (conversation_id, user_id, role)
    VALUES
        (v_conversation_id, p_user1_id, 'member'),
        (v_conversation_id, p_user2_id, 'member')
    ON CONFLICT ON CONSTRAINT conversation_participants_conversation_id_user_id_key
    DO NOTHING;

    RETURN v_conversation_id;
END;
$$;

REVOKE ALL ON FUNCTION public.get_or_create_single_conversation(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_or_create_single_conversation(UUID, UUID) TO authenticated;
