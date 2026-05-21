-- ============================================================
-- Allow Instructors to View Quiz Attempts for Their Courses
-- Run this in Supabase SQL Editor
-- ============================================================

-- Add policy for instructors to view quiz attempts in their courses
CREATE POLICY "instructors_view_quiz_attempts" ON quiz_attempts
  FOR SELECT TO authenticated
  USING (
    -- User can see their own attempts
    user_id = auth.uid()
    OR
    -- Instructor can see attempts for quizzes in their courses
    EXISTS (
      SELECT 1 FROM quizzes q
      JOIN courses c ON q.course_id = c.id
      WHERE q.id = quiz_attempts.quiz_id
      AND c.instructor_id = auth.uid()
    )
  );

-- Drop the old select policy first (if exists)
DROP POLICY IF EXISTS "quiz_attempts_select" ON quiz_attempts;

-- Verify policies
SELECT tablename, policyname, cmd FROM pg_policies WHERE tablename = 'quiz_attempts';
