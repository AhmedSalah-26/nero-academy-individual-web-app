-- ============================================================
-- Fix course statistics columns function to use earnings_transactions
-- ============================================================

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
    
    -- Sum revenue from earnings_transactions 
    SELECT COALESCE(SUM(amount - commission), 0) INTO v_total_revenue
    FROM earnings_transactions
    WHERE course_id = p_course_id
      AND status IN ('available', 'pending', 'paid');
    
    -- Update course
    UPDATE courses
    SET section_count = v_section_count,
        lesson_count = v_lesson_count,
        total_revenue = v_total_revenue
    WHERE id = p_course_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-Trigger function for earnings
CREATE OR REPLACE FUNCTION trigger_update_course_stats_on_earning()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF OLD.course_id IS NOT NULL THEN
            PERFORM update_course_stats(OLD.course_id);
        END IF;
        RETURN OLD;
    ELSE
        IF NEW.course_id IS NOT NULL THEN
            PERFORM update_course_stats(NEW.course_id);
        END IF;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Drop from earnings_transactions if exists
DROP TRIGGER IF EXISTS earning_stats_trigger ON earnings_transactions;

-- Create trigger on earnings_transactions
CREATE TRIGGER earning_stats_trigger
AFTER INSERT OR UPDATE OR DELETE ON earnings_transactions
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
