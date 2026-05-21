-- ============================================================
-- 🔔 NOTIFICATIONS TABLE
-- جدول الإشعارات للمستخدمين
-- Version: 1.0 | January 2026
-- ============================================================

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Notification Type
  type TEXT NOT NULL CHECK (type IN (
    'instructor_message',      -- رسالة من المدرب
    'course_update',           -- تحديث على الكورس
    'new_lesson',              -- درس جديد
    'quiz_result',             -- نتيجة اختبار
    'certificate_issued',      -- شهادة صدرت
    'enrollment_confirmed',    -- تأكيد التسجيل
    'payment_confirmed',       -- تأكيد الدفع
    'course_completed',        -- إكمال الكورس
    'announcement',            -- إعلان
    'promotion',               -- عرض ترويجي
    'reminder',                -- تذكير
    'report_update',           -- تحديث على البلاغ
    'system'                   -- إشعار نظام
  )),
  
  -- Content (Arabic & English)
  title_ar TEXT NOT NULL,
  title_en TEXT,
  body_ar TEXT,
  body_en TEXT,
  
  -- Optional Image/Icon
  image_url TEXT,
  icon_name TEXT,
  
  -- Action Link
  action_type TEXT CHECK (action_type IN ('course', 'lesson', 'certificate', 'quiz', 'url', 'screen')),
  action_value TEXT, -- course_id, lesson_id, certificate_id, url, or screen name
  
  -- Extra Data (JSON for flexibility)
  data JSONB DEFAULT '{}',
  
  -- Status
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  
  -- Sender (optional - for instructor messages)
  sender_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  
  -- Related entities (optional)
  course_id UUID REFERENCES courses(id) ON DELETE SET NULL,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX idx_notifications_sender ON notifications(sender_id);
CREATE INDEX idx_notifications_course ON notifications(course_id);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users can read their own notifications
CREATE POLICY "Users can read own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE
  USING (auth.uid() = user_id);

-- Instructors can send notifications to their students
CREATE POLICY "Instructors can create notifications for their students"
  ON notifications FOR INSERT
  WITH CHECK (
    -- System can create any notification
    auth.uid() IS NOT NULL
    AND (
      -- User creating notification for themselves
      auth.uid() = user_id
      OR
      -- Instructor creating notification for their student
      EXISTS (
        SELECT 1 FROM enrollments e
        JOIN courses c ON e.course_id = c.id
        WHERE e.user_id = notifications.user_id
        AND c.instructor_id = auth.uid()
      )
    )
  );

-- Admins have full access
CREATE POLICY "Admins have full access to notifications"
  ON notifications FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Function to mark notification as read
CREATE OR REPLACE FUNCTION mark_notification_read(p_notification_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE notifications
  SET 
    is_read = TRUE,
    read_at = NOW(),
    updated_at = NOW()
  WHERE id = p_notification_id
  AND user_id = auth.uid();
  
  RETURN FOUND;
END;
$$;

-- Function to mark all notifications as read
CREATE OR REPLACE FUNCTION mark_all_notifications_read()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  updated_count INTEGER;
BEGIN
  WITH updated AS (
    UPDATE notifications
    SET 
      is_read = TRUE,
      read_at = NOW(),
      updated_at = NOW()
    WHERE user_id = auth.uid()
    AND is_read = FALSE
    RETURNING 1
  )
  SELECT COUNT(*) INTO updated_count FROM updated;
  
  RETURN updated_count;
END;
$$;

-- Function to get unread notifications count
CREATE OR REPLACE FUNCTION get_unread_notifications_count()
RETURNS INTEGER
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT COUNT(*)::INTEGER
  FROM notifications
  WHERE user_id = auth.uid()
  AND is_read = FALSE;
$$;

-- Function to send notification (for use by triggers/functions)
CREATE OR REPLACE FUNCTION send_notification(
  p_user_id UUID,
  p_type TEXT,
  p_title_ar TEXT,
  p_title_en TEXT DEFAULT NULL,
  p_body_ar TEXT DEFAULT NULL,
  p_body_en TEXT DEFAULT NULL,
  p_data JSONB DEFAULT '{}',
  p_sender_id UUID DEFAULT NULL,
  p_course_id UUID DEFAULT NULL,
  p_action_type TEXT DEFAULT NULL,
  p_action_value TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  INSERT INTO notifications (
    user_id, type, title_ar, title_en, body_ar, body_en,
    data, sender_id, course_id, action_type, action_value
  ) VALUES (
    p_user_id, p_type, p_title_ar, p_title_en, p_body_ar, p_body_en,
    p_data, p_sender_id, p_course_id, p_action_type, p_action_value
  )
  RETURNING id INTO v_notification_id;
  
  RETURN v_notification_id;
END;
$$;

-- ============================================================
-- GRANT PERMISSIONS
-- ============================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON notifications TO authenticated;
GRANT EXECUTE ON FUNCTION mark_notification_read TO authenticated;
GRANT EXECUTE ON FUNCTION mark_all_notifications_read TO authenticated;
GRANT EXECUTE ON FUNCTION get_unread_notifications_count TO authenticated;
GRANT EXECUTE ON FUNCTION send_notification TO authenticated;
