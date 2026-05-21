-- ============================================================
-- Fix Submit Quiz Function v3
-- Store is_correct with each answer
-- ============================================================

DROP FUNCTION IF EXISTS submit_quiz_attempt(UUID, JSONB, INT);

CREATE OR REPLACE FUNCTION submit_quiz_attempt(
  p_attempt_id UUID,
  p_answers JSONB,
  p_time_spent INT DEFAULT 0
)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_attempt RECORD;
  v_quiz RECORD;
  v_score INT := 0;
  v_total_points INT := 0;
  v_percentage DECIMAL;
  v_passed BOOLEAN;
  v_question RECORD;
  v_user_answer JSONB;
  v_correct_option_ids JSONB;
  v_is_correct BOOLEAN;
  v_answers_with_correct JSONB := '{}'::jsonb;
BEGIN
  -- Get attempt
  SELECT * INTO v_attempt 
  FROM quiz_attempts 
  WHERE id = p_attempt_id AND user_id = v_user_id;
  
  IF v_attempt IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Attempt not found or unauthorized');
  END IF;
  
  -- Check if already completed
  IF v_attempt.completed_at IS NOT NULL THEN
    RETURN json_build_object('success', false, 'error', 'Attempt already completed');
  END IF;
  
  -- Get quiz
  SELECT * INTO v_quiz FROM quizzes WHERE id = v_attempt.quiz_id;
  
  IF v_quiz IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Quiz not found');
  END IF;
  
  -- Calculate score
  FOR v_question IN 
    SELECT id, points, options 
    FROM quiz_questions 
    WHERE quiz_id = v_attempt.quiz_id
  LOOP
    v_total_points := v_total_points + v_question.points;
    
    -- Get user's answer for this question (it's an array of option IDs)
    v_user_answer := p_answers->v_question.id::text;
    
    -- Get correct option IDs from the question options
    SELECT jsonb_agg(opt->>'id') INTO v_correct_option_ids
    FROM jsonb_array_elements(v_question.options) AS opt
    WHERE (opt->>'is_correct')::boolean = true;
    
    -- Default to empty array if no correct options found
    IF v_correct_option_ids IS NULL THEN
      v_correct_option_ids := '[]'::jsonb;
    END IF;
    
    -- Check if answer is correct
    IF v_user_answer IS NOT NULL AND jsonb_array_length(v_user_answer) > 0 THEN
      v_is_correct := (
        SELECT 
          (SELECT jsonb_agg(x ORDER BY x) FROM jsonb_array_elements_text(v_user_answer) x) =
          (SELECT jsonb_agg(x ORDER BY x) FROM jsonb_array_elements_text(v_correct_option_ids) x)
      );
      
      IF v_is_correct THEN
        v_score := v_score + v_question.points;
      END IF;
    ELSE
      v_is_correct := false;
    END IF;
    
    -- Store answer with is_correct flag
    v_answers_with_correct := v_answers_with_correct || jsonb_build_object(
      v_question.id::text,
      jsonb_build_object(
        'selected_option_ids', COALESCE(v_user_answer, '[]'::jsonb),
        'is_correct', v_is_correct,
        'points_earned', CASE WHEN v_is_correct THEN v_question.points ELSE 0 END
      )
    );
  END LOOP;
  
  -- Calculate percentage
  v_percentage := CASE 
    WHEN v_total_points > 0 THEN (v_score::DECIMAL / v_total_points) * 100 
    ELSE 0 
  END;
  
  v_passed := v_percentage >= v_quiz.passing_score;
  
  -- Update attempt with answers that include is_correct
  UPDATE quiz_attempts SET
    completed_at = NOW(),
    score = v_score,
    total_points = v_total_points,
    percentage = v_percentage,
    passed = v_passed,
    time_spent = p_time_spent,
    answers = v_answers_with_correct
  WHERE id = p_attempt_id;
  
  -- Return result
  RETURN json_build_object(
    'success', true,
    'attempt_id', p_attempt_id,
    'score', v_score,
    'total_points', v_total_points,
    'percentage', ROUND(v_percentage, 2),
    'passed', v_passed,
    'passing_score', v_quiz.passing_score
  );
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION submit_quiz_attempt(UUID, JSONB, INT) TO authenticated;

SELECT 'Submit quiz function v3 - now stores is_correct with each answer!' as status;
