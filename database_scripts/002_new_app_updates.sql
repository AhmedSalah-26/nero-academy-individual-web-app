-- ============================================================
-- 1. Create Missing Tables (Not in 001 Schema)
-- ============================================================

-- Fix: Make quizzes.lesson_id nullable to support course-level quizzes
ALTER TABLE IF EXISTS quizzes ALTER COLUMN lesson_id DROP NOT NULL;

-- Fix: Add image_url column to quiz_questions (for question images)
ALTER TABLE IF EXISTS quiz_questions ADD COLUMN IF NOT EXISTS image_url TEXT;


-- A. Instructor Earnings Table
CREATE TABLE IF NOT EXISTS instructor_earnings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  enrollment_id UUID NOT NULL REFERENCES enrollments(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  -- Amounts
  gross_amount DECIMAL(10,2) NOT NULL, -- total paid by student
  platform_fee DECIMAL(10,2) NOT NULL, -- platform's share
  net_amount DECIMAL(10,2) NOT NULL, -- instructor's share
  revenue_share DECIMAL(5,2) DEFAULT 70.00, -- percentage at time of sale
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'available', 'paid', 'refunded')),
  available_at TIMESTAMPTZ, -- when it becomes available for payout
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_earnings_instructor ON instructor_earnings(instructor_id);
CREATE INDEX IF NOT EXISTS idx_earnings_course ON instructor_earnings(course_id);
CREATE INDEX IF NOT EXISTS idx_earnings_status ON instructor_earnings(status);

-- B. Direct Messages Table
CREATE TABLE IF NOT EXISTS direct_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  message_text TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_dm_sender ON direct_messages (sender_id, created_at);
CREATE INDEX IF NOT EXISTS idx_dm_receiver ON direct_messages (receiver_id, created_at);

-- ============================================================
-- 2. App Fixes & Updates (Missing Columns and Triggers)
-- ============================================================

-- Add course statistics columns
ALTER TABLE IF EXISTS courses ADD COLUMN IF NOT EXISTS lesson_count INT DEFAULT 0;
ALTER TABLE IF EXISTS courses ADD COLUMN IF NOT EXISTS section_count INT DEFAULT 0;
ALTER TABLE IF EXISTS courses ADD COLUMN IF NOT EXISTS total_revenue DECIMAL(10,2) DEFAULT 0;

-- Function to update course stats
CREATE OR REPLACE FUNCTION update_course_stats(p_course_id UUID)
RETURNS VOID AS $$
DECLARE
    v_section_count INT;
    v_lesson_count INT;
    v_total_revenue DECIMAL(10,2);
BEGIN
    -- Count sections
    SELECT COUNT(*) INTO v_section_count
    FROM sections
    WHERE course_id = p_course_id;
    
    -- Count lessons
    SELECT COUNT(*) INTO v_lesson_count
    FROM lessons
    WHERE course_id = p_course_id;
    
    -- Sum revenue from instructor_earnings
    SELECT COALESCE(SUM(net_amount), 0) INTO v_total_revenue
    FROM instructor_earnings
    WHERE course_id = p_course_id AND status IN ('available', 'paid', 'pending');
    
    -- Update course
    UPDATE courses
    SET section_count = v_section_count,
        lesson_count = v_lesson_count,
        total_revenue = v_total_revenue
    WHERE id = p_course_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger function for sections
CREATE OR REPLACE FUNCTION trigger_update_course_stats_on_section()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM update_course_stats(OLD.course_id);
        RETURN OLD;
    ELSE
        PERFORM update_course_stats(NEW.course_id);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for lessons
CREATE OR REPLACE FUNCTION trigger_update_course_stats_on_lesson()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM update_course_stats(OLD.course_id);
        RETURN OLD;
    ELSE
        PERFORM update_course_stats(NEW.course_id);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for earnings
CREATE OR REPLACE FUNCTION trigger_update_course_stats_on_earning()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM update_course_stats(OLD.course_id);
        RETURN OLD;
    ELSE
        PERFORM update_course_stats(NEW.course_id);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS section_stats_trigger ON sections;
DROP TRIGGER IF EXISTS lesson_stats_trigger ON lessons;
DROP TRIGGER IF EXISTS earning_stats_trigger ON instructor_earnings;

-- Create triggers
CREATE TRIGGER section_stats_trigger
AFTER INSERT OR UPDATE OR DELETE ON sections
FOR EACH ROW
EXECUTE FUNCTION trigger_update_course_stats_on_section();

CREATE TRIGGER lesson_stats_trigger
AFTER INSERT OR UPDATE OR DELETE ON lessons
FOR EACH ROW
EXECUTE FUNCTION trigger_update_course_stats_on_lesson();

CREATE TRIGGER earning_stats_trigger
AFTER INSERT OR UPDATE OR DELETE ON instructor_earnings
FOR EACH ROW
EXECUTE FUNCTION trigger_update_course_stats_on_earning();

-- Update all existing courses stats immediately
DO $$
DECLARE
    course_record RECORD;
BEGIN
    FOR course_record IN SELECT id FROM courses LOOP
        PERFORM update_course_stats(course_record.id);
    END LOOP;
END $$;

GRANT EXECUTE ON FUNCTION update_course_stats(UUID) TO authenticated;

-- ============================================================
-- 3. Quiz Statistics Additions
-- ============================================================

-- Add columns to quizzes table
ALTER TABLE IF EXISTS quizzes ADD COLUMN IF NOT EXISTS attempts_count INT DEFAULT 0;
ALTER TABLE IF EXISTS quizzes ADD COLUMN IF NOT EXISTS average_score DECIMAL(5,2) DEFAULT 0;

-- Function to update quiz stats
CREATE OR REPLACE FUNCTION update_quiz_stats(p_quiz_id UUID)
RETURNS VOID AS $$
DECLARE
    v_attempts_count INT;
    v_average_score DECIMAL(5,2);
BEGIN
    SELECT 
        COUNT(*)::INT,
        COALESCE(AVG(percentage), 0)::DECIMAL(5,2)
    INTO v_attempts_count, v_average_score
    FROM quiz_attempts
    WHERE quiz_id = p_quiz_id
      AND completed_at IS NOT NULL;
    
    UPDATE quizzes
    SET attempts_count = v_attempts_count,
        average_score = v_average_score
    WHERE id = p_quiz_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update stats
CREATE OR REPLACE FUNCTION trigger_update_quiz_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.completed_at IS NOT NULL AND (OLD.completed_at IS NULL OR OLD.completed_at != NEW.completed_at) THEN
        PERFORM update_quiz_stats(NEW.quiz_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS quiz_attempt_stats_trigger ON quiz_attempts;

CREATE TRIGGER quiz_attempt_stats_trigger
AFTER INSERT OR UPDATE ON quiz_attempts
FOR EACH ROW
EXECUTE FUNCTION trigger_update_quiz_stats();

-- Update all existing quizzes
DO $$
DECLARE
    quiz_record RECORD;
BEGIN
    FOR quiz_record IN SELECT id FROM quizzes LOOP
        PERFORM update_quiz_stats(quiz_record.id);
    END LOOP;
END $$;

GRANT EXECUTE ON FUNCTION update_quiz_stats(UUID) TO authenticated;

-- ============================================================
-- 4. Direct Messages RLS Policies
-- ============================================================

ALTER TABLE IF EXISTS direct_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own DMs" ON direct_messages;
CREATE POLICY "Users can read own DMs" ON direct_messages FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can send DMs" ON direct_messages;
CREATE POLICY "Users can send DMs" ON direct_messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

SELECT 'All missing tables, columns, and triggers successfully added to 001 schema!' as status;
-- ============================================================
-- 5. Course Attachments Table
-- ============================================================

CREATE TABLE IF NOT EXISTS course_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_name_ar TEXT,
  file_url TEXT NOT NULL,
  file_type TEXT, -- pdf, zip, doc, jpg, png, etc.
  file_size INTEGER, -- in bytes
  download_count INTEGER DEFAULT 0,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_course_attachments_course ON course_attachments(course_id);
CREATE INDEX IF NOT EXISTS idx_course_attachments_sort ON course_attachments(course_id, sort_order);

-- Enable RLS
ALTER TABLE course_attachments ENABLE ROW LEVEL SECURITY;

-- Policy: Instructors can manage their course attachments
DROP POLICY IF EXISTS "Instructors can manage their course attachments" ON course_attachments;
CREATE POLICY "Instructors can manage their course attachments" ON course_attachments
FOR ALL
USING (
  course_id IN (
    SELECT id FROM courses WHERE instructor_id = auth.uid()
  )
);

-- Policy: Enrolled students can view course attachments
DROP POLICY IF EXISTS "Enrolled students can view course attachments" ON course_attachments;
CREATE POLICY "Enrolled students can view course attachments" ON course_attachments
FOR SELECT
USING (
  course_id IN (
    SELECT course_id FROM enrollments 
    WHERE user_id = auth.uid() AND status = 'active'
  )
);

-- Policy: Admins can manage all attachments
DROP POLICY IF EXISTS "Admins can manage all attachments" ON course_attachments;
CREATE POLICY "Admins can manage all attachments" ON course_attachments
FOR ALL
USING (is_admin());

SELECT 'course_attachments table added successfully!' as status;

-- ============================================================
-- 6. Quiz Submit Function
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
  v_debug_info JSONB := '[]'::jsonb;
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

    -- Get user's answer for this question (array of option IDs)
    v_user_answer := p_answers->v_question.id::text;

    -- Get correct option IDs from the question options
    SELECT jsonb_agg(opt->>'id') INTO v_correct_option_ids
    FROM jsonb_array_elements(v_question.options) AS opt
    WHERE (opt->>'is_correct')::boolean = true;

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

    v_debug_info := v_debug_info || jsonb_build_object(
      'question_id', v_question.id,
      'user_answer', v_user_answer,
      'correct_options', v_correct_option_ids,
      'is_correct', v_is_correct
    );
  END LOOP;

  -- Calculate percentage
  v_percentage := CASE
    WHEN v_total_points > 0 THEN (v_score::DECIMAL / v_total_points) * 100
    ELSE 0
  END;

  v_passed := v_percentage >= v_quiz.passing_score;

  -- Update attempt
  UPDATE quiz_attempts SET
    completed_at = NOW(),
    score        = v_score,
    total_points = v_total_points,
    percentage   = v_percentage,
    passed       = v_passed,
    time_spent   = p_time_spent,
    answers      = p_answers
  WHERE id = p_attempt_id;

  RETURN json_build_object(
    'success',       true,
    'attempt_id',    p_attempt_id,
    'score',         v_score,
    'total_points',  v_total_points,
    'percentage',    ROUND(v_percentage, 2),
    'passed',        v_passed,
    'passing_score', v_quiz.passing_score,
    'debug',         v_debug_info
  );

EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION submit_quiz_attempt(UUID, JSONB, INT) TO authenticated;

SELECT 'submit_quiz_attempt function added successfully!' as status;
