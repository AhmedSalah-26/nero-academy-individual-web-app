-- =====================================================
-- Q&A Answers Count Trigger
-- =====================================================
-- This script creates a trigger to automatically update
-- the answers_count in qa_questions table when answers
-- are added or deleted
-- =====================================================

-- Function to update answers count
CREATE OR REPLACE FUNCTION update_qa_answers_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Increment answers count
    UPDATE qa_questions
    SET answers_count = answers_count + 1
    WHERE id = NEW.question_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    -- Decrement answers count
    UPDATE qa_questions
    SET answers_count = GREATEST(0, answers_count - 1)
    WHERE id = OLD.question_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS trigger_update_qa_answers_count ON qa_answers;

-- Create trigger
CREATE TRIGGER trigger_update_qa_answers_count
AFTER INSERT OR DELETE ON qa_answers
FOR EACH ROW
EXECUTE FUNCTION update_qa_answers_count();

-- Recalculate existing counts (one-time fix)
UPDATE qa_questions q
SET answers_count = (
  SELECT COUNT(*)
  FROM qa_answers a
  WHERE a.question_id = q.id
);

COMMENT ON FUNCTION update_qa_answers_count() IS 'Automatically updates answers_count in qa_questions when answers are added or deleted';
