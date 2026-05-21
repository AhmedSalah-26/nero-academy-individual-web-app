-- ============================================================
-- Add course statistics columns and keep them updated
-- ============================================================

-- Add columns to courses table if not exist
ALTER TABLE courses ADD COLUMN IF NOT EXISTS lesson_count INT DEFAULT 0;
ALTER TABLE courses ADD COLUMN IF NOT EXISTS section_count INT DEFAULT 0;
ALTER TABLE courses ADD COLUMN IF NOT EXISTS total_revenue DECIMAL(10,2) DEFAULT 0;

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
    WHERE course_id = p_course_id;
    
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

-- Drop existing triggers
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

-- Update all existing courses stats
DO $$
DECLARE
    course_record RECORD;
BEGIN
    FOR course_record IN SELECT id FROM courses LOOP
        PERFORM update_course_stats(course_record.id);
    END LOOP;
END $$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION update_course_stats(UUID) TO authenticated;

SELECT 'Course stats columns and triggers created!' as status;
