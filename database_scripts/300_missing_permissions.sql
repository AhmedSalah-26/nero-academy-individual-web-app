-- ============================================================
-- 🔐 MISSING PERMISSIONS - Admin & Instructor
-- إضافة كل الصلاحيات الناقصة للأدمن والمدرس
-- Version: 1.1 | February 2026
-- Safe to re-run (idempotent)
-- ============================================================

-- ============================================================
-- 0. MISSING COLUMNS (must run first)
-- ============================================================

-- Add is_hidden to course_reviews (admin hide review)
ALTER TABLE course_reviews
  ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN NOT NULL DEFAULT false;

-- Add is_hidden + is_pinned to qa_questions (admin/instructor hide & pin)
ALTER TABLE qa_questions
  ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE qa_questions
  ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN NOT NULL DEFAULT false;

-- ============================================================
-- 1. ADMIN RLS POLICIES
-- ============================================================

-- ---- Courses: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all courses" ON courses;
CREATE POLICY "Admins can manage all courses"
  ON courses FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Course Reviews: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all reviews" ON course_reviews;
CREATE POLICY "Admins can manage all reviews"
  ON course_reviews FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Q&A Questions: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all questions" ON qa_questions;
CREATE POLICY "Admins can manage all questions"
  ON qa_questions FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Q&A Answers: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all answers" ON qa_answers;
CREATE POLICY "Admins can manage all answers"
  ON qa_answers FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Quizzes: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all quizzes" ON quizzes;
CREATE POLICY "Admins can manage all quizzes"
  ON quizzes FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Quiz Questions: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all quiz questions" ON quiz_questions;
CREATE POLICY "Admins can manage all quiz questions"
  ON quiz_questions FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Quiz Attempts: Admin can view all ----
DROP POLICY IF EXISTS "Admins can view all quiz attempts" ON quiz_attempts;
CREATE POLICY "Admins can view all quiz attempts"
  ON quiz_attempts FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Announcements: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all announcements" ON announcements;
CREATE POLICY "Admins can manage all announcements"
  ON announcements FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Announcement Reads: Admin can view all ----
DROP POLICY IF EXISTS "Admins can view all announcement reads" ON announcement_reads;
CREATE POLICY "Admins can view all announcement reads"
  ON announcement_reads FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Notes: Admin can view all ----
DROP POLICY IF EXISTS "Admins can view all notes" ON notes;
CREATE POLICY "Admins can view all notes"
  ON notes FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Bookmarks: Admin can view all ----
DROP POLICY IF EXISTS "Admins can view all bookmarks" ON bookmarks;
CREATE POLICY "Admins can view all bookmarks"
  ON bookmarks FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Lesson Attachments: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all lesson attachments" ON lesson_attachments;
CREATE POLICY "Admins can manage all lesson attachments"
  ON lesson_attachments FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Lesson Progress: Admin can view all ----
DROP POLICY IF EXISTS "Admins can view all lesson progress" ON lesson_progress;
CREATE POLICY "Admins can view all lesson progress"
  ON lesson_progress FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Course Forum Messages: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all forum messages" ON course_forum_messages;
CREATE POLICY "Admins can manage all forum messages"
  ON course_forum_messages FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Course Forum Reactions: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all forum reactions" ON course_forum_reactions;
CREATE POLICY "Admins can manage all forum reactions"
  ON course_forum_reactions FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Course Forum Pinned Messages: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all pinned messages" ON course_forum_pinned_messages;
CREATE POLICY "Admins can manage all pinned messages"
  ON course_forum_pinned_messages FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Direct Messages: Admin can view all ----
DROP POLICY IF EXISTS "Admins can view all direct messages" ON direct_messages;
CREATE POLICY "Admins can view all direct messages"
  ON direct_messages FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ============================================================
-- 2. INSTRUCTOR FORUM MODERATION
-- ============================================================

-- Instructors can delete messages in their course forums
DROP POLICY IF EXISTS "Instructors can delete forum messages in their courses" ON course_forum_messages;
CREATE POLICY "Instructors can delete forum messages in their courses"
  ON course_forum_messages FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM courses
      WHERE courses.id = course_forum_messages.course_id
      AND courses.instructor_id = auth.uid()
    )
  );

-- ============================================================
-- 3. ADMIN HELPER FUNCTIONS
-- ============================================================

-- Function: Admin delete user (soft delete / deactivate)
CREATE OR REPLACE FUNCTION admin_delete_user(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Only admins can delete users';
  END IF;

  -- Deactivate user (soft delete)
  UPDATE profiles
  SET is_active = false,
      updated_at = NOW()
  WHERE id = p_user_id;

  RETURN FOUND;
END;
$$;

-- Function: Admin change user role
CREATE OR REPLACE FUNCTION admin_change_user_role(p_user_id UUID, p_new_role TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Only admins can change user roles';
  END IF;

  -- Validate role
  IF p_new_role NOT IN ('student', 'instructor', 'admin') THEN
    RAISE EXCEPTION 'Invalid role: %', p_new_role;
  END IF;

  -- Update role
  UPDATE profiles
  SET role = p_new_role,
      updated_at = NOW()
  WHERE id = p_user_id;

  -- If promoting to instructor, create instructor profile if not exists
  IF p_new_role = 'instructor' THEN
    INSERT INTO instructor_profiles (id, revenue_share)
    VALUES (p_user_id, 70.00)
    ON CONFLICT (id) DO NOTHING;
  END IF;

  RETURN FOUND;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION admin_delete_user TO authenticated;
GRANT EXECUTE ON FUNCTION admin_change_user_role TO authenticated;
