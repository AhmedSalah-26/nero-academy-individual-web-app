-- ============================================================
-- Migration: Make quizzes course-level instead of lesson-level
-- This allows quizzes to be associated with the entire course
-- ============================================================

-- Step 1: Make lesson_id nullable (quizzes can be course-level)
ALTER TABLE quizzes 
ALTER COLUMN lesson_id DROP NOT NULL;

-- Step 2: Add comment for clarity
COMMENT ON COLUMN quizzes.lesson_id IS 'Optional: If NULL, quiz is for the entire course. If set, quiz is for specific lesson.';

-- Step 3: Update the remote data source query to filter by course_id
-- The Flutter code already queries by course_id, so no changes needed there

-- ============================================================
-- Verification Query (run to check existing data)
-- ============================================================
-- SELECT id, course_id, lesson_id, title_ar FROM quizzes;
