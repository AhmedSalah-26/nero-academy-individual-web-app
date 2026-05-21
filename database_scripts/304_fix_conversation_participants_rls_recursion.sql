-- =====================================================
-- Fix RLS recursion on conversation_participants (42P17)
-- =====================================================
-- Issue:
--   Policy on conversation_participants was querying the same table
--   inside USING(), which causes infinite recursion under RLS.
--
-- This migration introduces a SECURITY DEFINER helper function and
-- rewrites policies to use it safely.

BEGIN;

CREATE OR REPLACE FUNCTION public.is_conversation_participant(
    p_conversation_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.conversation_participants cp
        WHERE cp.conversation_id = p_conversation_id
        AND cp.user_id = p_user_id
    );
$$;

REVOKE ALL ON FUNCTION public.is_conversation_participant(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_conversation_participant(UUID, UUID) TO authenticated;

-- Drop any existing SELECT policies on conversation_participants
-- to avoid keeping an old recursive policy with a different name.
DO $$
DECLARE pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'conversation_participants'
      AND cmd = 'SELECT'
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON public.conversation_participants',
      pol.policyname
    );
  END LOOP;
END$$;

-- conversations
DROP POLICY IF EXISTS "Participants can view their conversations" ON public.conversations;
CREATE POLICY "Participants can view their conversations"
ON public.conversations FOR SELECT
USING (
    public.is_conversation_participant(conversations.id, auth.uid())
    OR EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
    )
);

-- conversation_participants
DROP POLICY IF EXISTS "Participants can view members" ON public.conversation_participants;
CREATE POLICY "Participants can view members"
ON public.conversation_participants FOR SELECT
USING (
    public.is_conversation_participant(conversation_participants.conversation_id, auth.uid())
    OR EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
    )
);

-- messages
DROP POLICY IF EXISTS "Participants can view messages" ON public.messages;
CREATE POLICY "Participants can view messages"
ON public.messages FOR SELECT
USING (
    public.is_conversation_participant(messages.conversation_id, auth.uid())
    OR EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
    )
);

DROP POLICY IF EXISTS "Participants can send messages" ON public.messages;
CREATE POLICY "Participants can send messages"
ON public.messages FOR INSERT
WITH CHECK (
    user_id = auth.uid()
    AND public.is_conversation_participant(messages.conversation_id, auth.uid())
);

-- message_reactions
DROP POLICY IF EXISTS "Participants can view reactions" ON public.message_reactions;
CREATE POLICY "Participants can view reactions"
ON public.message_reactions FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.messages m
        WHERE m.id = message_reactions.message_id
        AND public.is_conversation_participant(m.conversation_id, auth.uid())
    )
);

DROP POLICY IF EXISTS "Participants can add reactions" ON public.message_reactions;
CREATE POLICY "Participants can add reactions"
ON public.message_reactions FOR INSERT
WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
        SELECT 1 FROM public.messages m
        WHERE m.id = message_reactions.message_id
        AND public.is_conversation_participant(m.conversation_id, auth.uid())
    )
);

COMMIT;

-- Optional check:
-- SELECT tablename, policyname, cmd
-- FROM pg_policies
-- WHERE tablename IN ('conversations', 'conversation_participants', 'messages', 'message_reactions')
-- ORDER BY tablename, policyname;
