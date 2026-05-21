-- ============================================================
-- 🔄 REBUILD: Unified Conversations Schema
-- Replace course_forum + direct_messages with conversations + messages
-- Version: 1.0 | February 2026
-- ============================================================

-- ================================
-- 1. DROP OLD TABLES & FUNCTIONS
-- ================================

-- Drop functions first (they reference old tables)
DROP FUNCTION IF EXISTS get_user_course_forums(UUID);
DROP FUNCTION IF EXISTS get_forum_courses_for_user(UUID, BOOLEAN, TEXT, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_unread_forum_messages_count(UUID, UUID);
DROP FUNCTION IF EXISTS mark_forum_messages_as_read(UUID, UUID);

-- Drop old tables (order matters due to FK constraints)
DROP TABLE IF EXISTS course_forum_pinned_messages CASCADE;
DROP TABLE IF EXISTS course_forum_read_receipts CASCADE;
DROP TABLE IF EXISTS course_forum_reactions CASCADE;
DROP TABLE IF EXISTS course_forum_messages CASCADE;
DROP TABLE IF EXISTS direct_message_reactions CASCADE;
DROP TABLE IF EXISTS direct_messages CASCADE;

-- ================================
-- 2. CREATE NEW TABLES
-- ================================

-- 2a. conversations: محادثه فرديه (single) أو جماعيه (multi)
CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(10) NOT NULL CHECK (type IN ('single', 'multi')),
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    title TEXT,
    created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2b. conversation_participants: أعضاء كل محادثة
CREATE TABLE IF NOT EXISTS conversation_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('admin', 'member')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(conversation_id, user_id)
);

-- 2c. messages: رسائل كل محادثة
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    message_text TEXT,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file')),
    media_url TEXT,
    file_name TEXT,
    file_size BIGINT,
    reply_to_message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
    is_edited BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2d. message_reactions: ريأكشن لكل رسالة
CREATE TABLE IF NOT EXISTS message_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    reaction TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(message_id, user_id)
);

-- ================================
-- 3. INDEXES
-- ================================
CREATE INDEX IF NOT EXISTS idx_conversations_course ON conversations(course_id);
CREATE INDEX IF NOT EXISTS idx_conversations_type ON conversations(type);
CREATE INDEX IF NOT EXISTS idx_conversations_created_by ON conversations(created_by);

CREATE INDEX IF NOT EXISTS idx_participants_conversation ON conversation_participants(conversation_id);
CREATE INDEX IF NOT EXISTS idx_participants_user ON conversation_participants(user_id);

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_user ON messages(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_reply ON messages(reply_to_message_id);

CREATE INDEX IF NOT EXISTS idx_reactions_message ON message_reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_reactions_user ON message_reactions(user_id);

-- ================================
-- 4. RLS POLICIES
-- ================================

-- Helper to avoid recursive RLS checks on conversation_participants
CREATE OR REPLACE FUNCTION is_conversation_participant(
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
        FROM conversation_participants cp
        WHERE cp.conversation_id = p_conversation_id
        AND cp.user_id = p_user_id
    );
$$;

REVOKE ALL ON FUNCTION is_conversation_participant(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION is_conversation_participant(UUID, UUID) TO authenticated;

-- 4a. conversations RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participants can view their conversations"
ON conversations FOR SELECT
USING (
    is_conversation_participant(conversations.id, auth.uid())
    OR
    -- Admins can see all
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
    )
);

CREATE POLICY "Authenticated users can create conversations"
ON conversations FOR INSERT
WITH CHECK (created_by = auth.uid());

CREATE POLICY "Creator can update conversation"
ON conversations FOR UPDATE
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

-- 4b. conversation_participants RLS
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participants can view members"
ON conversation_participants FOR SELECT
USING (
    is_conversation_participant(conversation_participants.conversation_id, auth.uid())
    OR
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
    )
);

CREATE POLICY "Conversation creator can add participants"
ON conversation_participants FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM conversations c
        WHERE c.id = conversation_participants.conversation_id
        AND c.created_by = auth.uid()
    )
    OR user_id = auth.uid()
);

CREATE POLICY "Creator can remove participants"
ON conversation_participants FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM conversations c
        WHERE c.id = conversation_participants.conversation_id
        AND c.created_by = auth.uid()
    )
    OR user_id = auth.uid()
);

-- 4c. messages RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participants can view messages"
ON messages FOR SELECT
USING (
    is_conversation_participant(messages.conversation_id, auth.uid())
    OR
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
    )
);

CREATE POLICY "Participants can send messages"
ON messages FOR INSERT
WITH CHECK (
    user_id = auth.uid()
    AND is_conversation_participant(messages.conversation_id, auth.uid())
);

CREATE POLICY "Users can update their own messages"
ON messages FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own messages"
ON messages FOR DELETE
USING (user_id = auth.uid());

-- 4d. message_reactions RLS
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participants can view reactions"
ON message_reactions FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM messages m
        WHERE m.id = message_reactions.message_id
        AND is_conversation_participant(m.conversation_id, auth.uid())
    )
);

CREATE POLICY "Participants can add reactions"
ON message_reactions FOR INSERT
WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
        SELECT 1 FROM messages m
        WHERE m.id = message_reactions.message_id
        AND is_conversation_participant(m.conversation_id, auth.uid())
    )
);

CREATE POLICY "Users can remove their reactions"
ON message_reactions FOR DELETE
USING (user_id = auth.uid());

-- ================================
-- 5. REALTIME
-- ================================
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE message_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;

-- ================================
-- 6. HELPER FUNCTION: Create course forum conversation
-- When a course is enrolled, auto-create a multi conversation
-- ================================
CREATE OR REPLACE FUNCTION get_or_create_course_conversation(p_course_id UUID, p_user_id UUID)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
    v_instructor_id UUID;
BEGIN
    -- Check if conversation already exists for this course
    SELECT id INTO v_conversation_id
    FROM conversations
    WHERE course_id = p_course_id AND type = 'multi'
    LIMIT 1;

    IF v_conversation_id IS NULL THEN
        -- Get instructor id
        SELECT instructor_id INTO v_instructor_id
        FROM courses WHERE id = p_course_id;

        -- Create the conversation
        INSERT INTO conversations (type, course_id, title, created_by)
        SELECT 'multi', p_course_id, COALESCE(c.title_ar, c.title_en, 'Course Forum'), COALESCE(v_instructor_id, p_user_id)
        FROM courses c WHERE c.id = p_course_id
        RETURNING id INTO v_conversation_id;

        -- Add instructor as admin participant
        IF v_instructor_id IS NOT NULL THEN
            INSERT INTO conversation_participants (conversation_id, user_id, role)
            VALUES (v_conversation_id, v_instructor_id, 'admin')
            ON CONFLICT (conversation_id, user_id) DO NOTHING;
        END IF;
    END IF;

    -- Add user as member (if not already)
    INSERT INTO conversation_participants (conversation_id, user_id, role)
    VALUES (v_conversation_id, p_user_id, 'member')
    ON CONFLICT (conversation_id, user_id) DO NOTHING;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_or_create_course_conversation(UUID, UUID) TO authenticated;

-- ================================
-- 7. HELPER FUNCTION: Get or create single conversation
-- ================================
CREATE OR REPLACE FUNCTION get_or_create_single_conversation(p_user1_id UUID, p_user2_id UUID)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
BEGIN
    -- Check if single conversation already exists between these two users
    SELECT c.id INTO v_conversation_id
    FROM conversations c
    JOIN conversation_participants cp1 ON cp1.conversation_id = c.id AND cp1.user_id = p_user1_id
    JOIN conversation_participants cp2 ON cp2.conversation_id = c.id AND cp2.user_id = p_user2_id
    WHERE c.type = 'single'
    LIMIT 1;

    IF v_conversation_id IS NULL THEN
        -- Create the conversation
        INSERT INTO conversations (type, created_by)
        VALUES ('single', p_user1_id)
        RETURNING id INTO v_conversation_id;

        -- Add both users
        INSERT INTO conversation_participants (conversation_id, user_id, role)
        VALUES
            (v_conversation_id, p_user1_id, 'member'),
            (v_conversation_id, p_user2_id, 'member');
    END IF;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_or_create_single_conversation(UUID, UUID) TO authenticated;

-- ================================
-- 8. HELPER FUNCTION: Get user conversations list
-- ================================
CREATE OR REPLACE FUNCTION get_user_conversations(p_user_id UUID, p_type TEXT DEFAULT NULL)
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
) AS $$
BEGIN
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
        (SELECT COUNT(*) FROM conversation_participants cp2 WHERE cp2.conversation_id = c.id) AS participants_count,
        -- For single conversations, get the other user's name
        CASE WHEN c.type = 'single' THEN (
            SELECT p_other.name FROM conversation_participants cp_other
            JOIN profiles p_other ON p_other.id = cp_other.user_id
            WHERE cp_other.conversation_id = c.id AND cp_other.user_id != p_user_id
            LIMIT 1
        ) ELSE NULL END AS other_user_name,
        CASE WHEN c.type = 'single' THEN (
            SELECT p_other.avatar_url FROM conversation_participants cp_other
            JOIN profiles p_other ON p_other.id = cp_other.user_id
            WHERE cp_other.conversation_id = c.id AND cp_other.user_id != p_user_id
            LIMIT 1
        ) ELSE NULL END AS other_user_avatar
    FROM conversations c
    JOIN conversation_participants cp ON cp.conversation_id = c.id AND cp.user_id = p_user_id
    LEFT JOIN LATERAL (
        SELECT m.id, m.message_text, m.user_id, m.created_at
        FROM messages m
        WHERE m.conversation_id = c.id AND m.is_deleted = FALSE
        ORDER BY m.created_at DESC
        LIMIT 1
    ) lm ON TRUE
    LEFT JOIN profiles p_sender ON p_sender.id = lm.user_id
    WHERE (p_type IS NULL OR c.type = p_type)
    ORDER BY COALESCE(lm.created_at, c.created_at) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_user_conversations(UUID, TEXT) TO authenticated;
