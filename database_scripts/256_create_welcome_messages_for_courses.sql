-- =====================================================
-- Create Welcome Messages for All Existing Courses
-- This ensures every course has a forum group automatically
-- =====================================================

-- Function to create welcome message for a course
CREATE OR REPLACE FUNCTION create_course_welcome_message(p_course_id UUID)
RETURNS VOID AS $$
DECLARE
    v_instructor_id UUID;
    v_course_title TEXT;
BEGIN
    -- Get course instructor and title
    SELECT instructor_id, title_en INTO v_instructor_id, v_course_title
    FROM courses
    WHERE id = p_course_id;
    
    -- Check if welcome message already exists
    IF NOT EXISTS (
        SELECT 1 FROM course_forum_messages
        WHERE course_id = p_course_id
        LIMIT 1
    ) THEN
        -- Create welcome message from instructor
        INSERT INTO course_forum_messages (
            course_id,
            user_id,
            message_text,
            message_type,
            created_at
        ) VALUES (
            p_course_id,
            v_instructor_id,
            'مرحباً بكم في منتدى الكورس! 👋

هذا المكان مخصص للنقاش والتواصل بين الطلاب والمدرس. لا تتردد في طرح أسئلتك ومشاركة أفكارك.

Welcome to the course forum! 👋

This is a space for discussion and communication between students and the instructor. Feel free to ask questions and share your ideas.',
            'text',
            NOW()
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create welcome messages for all existing courses
DO $$
DECLARE
    course_record RECORD;
BEGIN
    FOR course_record IN 
        SELECT id FROM courses WHERE is_published = TRUE
    LOOP
        PERFORM create_course_welcome_message(course_record.id);
    END LOOP;
END $$;

-- Trigger to automatically create welcome message when a new course is published
CREATE OR REPLACE FUNCTION trigger_create_course_welcome_message()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create welcome message when course is published
    IF NEW.is_published = TRUE AND (OLD.is_published IS NULL OR OLD.is_published = FALSE) THEN
        PERFORM create_course_welcome_message(NEW.id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists
DROP TRIGGER IF EXISTS on_course_published_create_forum ON courses;

-- Create trigger
CREATE TRIGGER on_course_published_create_forum
    AFTER INSERT OR UPDATE ON courses
    FOR EACH ROW
    EXECUTE FUNCTION trigger_create_course_welcome_message();

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION create_course_welcome_message(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION trigger_create_course_welcome_message() TO authenticated;
