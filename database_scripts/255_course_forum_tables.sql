-- =====================================================
-- Course Forum/Group Chat Feature
-- WhatsApp-like group chat for each course
-- =====================================================

-- Course Forum Messages Table
CREATE TABLE IF NOT EXISTS course_forum_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    message_text TEXT,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'reply')),
    media_url TEXT,
    file_name TEXT,
    file_size BIGINT,
    reply_to_message_id UUID REFERENCES course_forum_messages(id) ON DELETE SET NULL,
    is_edited BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_message_content CHECK (
        (message_type = 'text' AND message_text IS NOT NULL) OR
        (message_type IN ('image', 'file') AND media_url IS NOT NULL)
    )
);

-- Message Reactions Table (like WhatsApp reactions)
CREATE TABLE IF NOT EXISTS course_forum_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES course_forum_messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    reaction VARCHAR(10) NOT NULL, -- emoji
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(message_id, user_id)
);

-- Message Read Receipts (like WhatsApp blue ticks)
CREATE TABLE IF NOT EXISTS course_forum_read_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES course_forum_messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(message_id, user_id)
);

-- Pinned Messages (like WhatsApp pinned messages)
CREATE TABLE IF NOT EXISTS course_forum_pinned_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    message_id UUID NOT NULL REFERENCES course_forum_messages(id) ON DELETE CASCADE,
    pinned_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    pinned_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(course_id, message_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_forum_messages_course ON course_forum_messages(course_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_forum_messages_user ON course_forum_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_forum_messages_reply ON course_forum_messages(reply_to_message_id);
CREATE INDEX IF NOT EXISTS idx_forum_reactions_message ON course_forum_reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_forum_receipts_message ON course_forum_read_receipts(message_id);
CREATE INDEX IF NOT EXISTS idx_forum_receipts_user ON course_forum_read_receipts(user_id);

-- RLS Policies

-- Messages: Students and instructors can read messages for courses they're enrolled in or teaching
ALTER TABLE course_forum_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view messages in their courses"
ON course_forum_messages FOR SELECT
USING (
    -- Enrolled students can see messages
    EXISTS (
        SELECT 1 FROM enrollments 
        WHERE enrollments.course_id = course_forum_messages.course_id 
        AND enrollments.user_id = auth.uid()
        AND enrollments.status = 'active'
    )
    OR
    -- Course instructor can see messages
    EXISTS (
        SELECT 1 FROM courses 
        WHERE courses.id = course_forum_messages.course_id 
        AND courses.instructor_id = auth.uid()
    )
);

CREATE POLICY "Enrolled users can send messages"
ON course_forum_messages FOR INSERT
WITH CHECK (
    user_id = auth.uid()
    AND (
        -- Enrolled students can send
        EXISTS (
            SELECT 1 FROM enrollments 
            WHERE enrollments.course_id = course_forum_messages.course_id 
            AND enrollments.user_id = auth.uid()
            AND enrollments.status = 'active'
        )
        OR
        -- Course instructor can send
        EXISTS (
            SELECT 1 FROM courses 
            WHERE courses.id = course_forum_messages.course_id 
            AND courses.instructor_id = auth.uid()
        )
    )
);

CREATE POLICY "Users can update their own messages"
ON course_forum_messages FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own messages"
ON course_forum_messages FOR DELETE
USING (user_id = auth.uid());

-- Reactions policies
ALTER TABLE course_forum_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view reactions"
ON course_forum_reactions FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM course_forum_messages m
        LEFT JOIN enrollments e ON e.course_id = m.course_id AND e.user_id = auth.uid()
        LEFT JOIN courses c ON c.id = m.course_id AND c.instructor_id = auth.uid()
        WHERE m.id = course_forum_reactions.message_id
        AND (e.status = 'active' OR c.id IS NOT NULL)
    )
);

CREATE POLICY "Users can add reactions"
ON course_forum_reactions FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can remove their reactions"
ON course_forum_reactions FOR DELETE
USING (user_id = auth.uid());

-- Read receipts policies
ALTER TABLE course_forum_read_receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view read receipts"
ON course_forum_read_receipts FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM course_forum_messages m
        LEFT JOIN enrollments e ON e.course_id = m.course_id AND e.user_id = auth.uid()
        LEFT JOIN courses c ON c.id = m.course_id AND c.instructor_id = auth.uid()
        WHERE m.id = course_forum_read_receipts.message_id
        AND (e.status = 'active' OR c.id IS NOT NULL)
    )
);

CREATE POLICY "Users can mark messages as read"
ON course_forum_read_receipts FOR INSERT
WITH CHECK (user_id = auth.uid());

-- Pinned messages policies
ALTER TABLE course_forum_pinned_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view pinned messages"
ON course_forum_pinned_messages FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM courses c
        LEFT JOIN enrollments e ON e.course_id = c.id AND e.user_id = auth.uid()
        WHERE c.id = course_forum_pinned_messages.course_id
        AND (c.instructor_id = auth.uid() OR e.status = 'active')
    )
);

CREATE POLICY "Instructors can pin messages"
ON course_forum_pinned_messages FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM courses 
        WHERE courses.id = course_forum_pinned_messages.course_id 
        AND courses.instructor_id = auth.uid()
    )
);

CREATE POLICY "Instructors can unpin messages"
ON course_forum_pinned_messages FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM courses 
        WHERE courses.id = course_forum_pinned_messages.course_id 
        AND courses.instructor_id = auth.uid()
    )
);

-- Function to get unread message count for a course
CREATE OR REPLACE FUNCTION get_unread_forum_messages_count(p_course_id UUID, p_user_id UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)::INTEGER
        FROM course_forum_messages m
        WHERE m.course_id = p_course_id
        AND m.user_id != p_user_id
        AND NOT EXISTS (
            SELECT 1 FROM course_forum_read_receipts r
            WHERE r.message_id = m.id
            AND r.user_id = p_user_id
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark all messages as read
CREATE OR REPLACE FUNCTION mark_forum_messages_as_read(p_course_id UUID, p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO course_forum_read_receipts (message_id, user_id)
    SELECT m.id, p_user_id
    FROM course_forum_messages m
    WHERE m.course_id = p_course_id
    AND m.user_id != p_user_id
    AND NOT EXISTS (
        SELECT 1 FROM course_forum_read_receipts r
        WHERE r.message_id = m.id
        AND r.user_id = p_user_id
    )
    ON CONFLICT (message_id, user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Storage bucket for forum media (images, files)
INSERT INTO storage.buckets (id, name, public)
VALUES ('course-forum-media', 'course-forum-media', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "Users can upload forum media"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'course-forum-media'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Anyone can view forum media"
ON storage.objects FOR SELECT
USING (bucket_id = 'course-forum-media');

CREATE POLICY "Users can delete their forum media"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'course-forum-media'
    AND auth.uid()::text = (storage.foldername(name))[1]
);
