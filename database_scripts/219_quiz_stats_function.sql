-- ============================================================
-- Add quiz statistics (attempts_count, average_score) to quizzes
-- ============================================================

-- Add columns to quizzes table if not exist
ALTER TABLE quizzes ADD COLUMN IF NOT EXISTS attempts_count INT DEFAULT 0;
ALTER TABLE quizzes ADD COLUMN IF NOT EXISTS average_score DECIMAL(5,2) DEFAULT 0;

-- Function to update quiz stats
CREATE OR REPLACE FUNCTION update_quiz_stats(p_quiz_id UUID)
RETURNS VOID AS $$
DECLARE
    v_attempts_count INT;
    v_average_score DECIMAL(5,2);
BEGIN
    -- Calculate stats from completed attempts
    SELECT 
        COUNT(*)::INT,
        COALESCE(AVG(percentage), 0)::DECIMAL(5,2)
    INTO v_attempts_count, v_average_score
    FROM quiz_attempts
    WHERE quiz_id = p_quiz_id
      AND completed_at IS NOT NULL;
    
    -- Update quiz
    UPDATE quizzes
    SET attempts_count = v_attempts_count,
        average_score = v_average_score
    WHERE id = p_quiz_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update stats when attempt is completed
CREATE OR REPLACE FUNCTION trigger_update_quiz_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Only update when attempt is completed
    IF NEW.completed_at IS NOT NULL AND (OLD.completed_at IS NULL OR OLD.completed_at != NEW.completed_at) THEN
        PERFORM update_quiz_stats(NEW.quiz_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS quiz_attempt_stats_trigger ON quiz_attempts;

-- Create trigger
CREATE TRIGGER quiz_attempt_stats_trigger
AFTER INSERT OR UPDATE ON quiz_attempts
FOR EACH ROW
EXECUTE FUNCTION trigger_update_quiz_stats();

-- Update all existing quizzes stats
DO $$
DECLARE
    quiz_record RECORD;
BEGIN
    FOR quiz_record IN SELECT id FROM quizzes LOOP
        PERFORM update_quiz_stats(quiz_record.id);
    END LOOP;
END $$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION update_quiz_stats(UUID) TO authenticated;

SELECT 'Quiz stats columns and trigger created!' as status;
