-- ============================================================
-- Make quizzes work at course level (lesson_id optional)
-- ============================================================

-- Make lesson_id nullable (quiz can be for entire course)
ALTER TABLE quizzes ALTER COLUMN lesson_id DROP NOT NULL;

-- Add index for course-level quizzes
CREATE INDEX IF NOT EXISTS idx_quizzes_course_level ON quizzes(course_id) WHERE lesson_id IS NULL;

-- Verify the change
SELECT column_name, is_nullable, data_type 
FROM information_schema.columns 
WHERE table_name = 'quizzes' AND column_name = 'lesson_id';


-- Function to increment quiz questions count
CREATE OR REPLACE FUNCTION increment_quiz_questions(p_quiz_id UUID, p_points INTEGER DEFAULT 1)
RETURNS VOID AS $$
BEGIN
    UPDATE quizzes 
    SET 
        total_questions = total_questions + 1,
        total_points = total_points + p_points,
        updated_at = NOW()
    WHERE id = p_quiz_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement quiz questions count
CREATE OR REPLACE FUNCTION decrement_quiz_questions(p_quiz_id UUID, p_points INTEGER DEFAULT 1)
RETURNS VOID AS $$
BEGIN
    UPDATE quizzes 
    SET 
        total_questions = GREATEST(0, total_questions - 1),
        total_points = GREATEST(0, total_points - p_points),
        updated_at = NOW()
    WHERE id = p_quiz_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION increment_quiz_questions(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION decrement_quiz_questions(UUID, INTEGER) TO authenticated;
