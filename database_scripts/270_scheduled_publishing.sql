-- ============================================================
-- Migration: Add Scheduled Publishing for Sections and Lessons
-- Version: 2026-02-03
-- ============================================================

-- Add scheduled publish fields to sections
ALTER TABLE sections 
ADD COLUMN IF NOT EXISTS publish_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS unpublish_at TIMESTAMPTZ;

-- Add scheduled publish fields to lessons  
ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS publish_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS unpublish_at TIMESTAMPTZ;

-- Create indexes for scheduled publishing
CREATE INDEX IF NOT EXISTS idx_sections_publish_at ON sections(publish_at) WHERE publish_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_lessons_publish_at ON lessons(publish_at) WHERE publish_at IS NOT NULL;

-- ============================================================
-- Function: Auto-publish sections at scheduled time
-- ============================================================
CREATE OR REPLACE FUNCTION auto_publish_sections()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Publish sections that are scheduled
  UPDATE sections
  SET is_published = TRUE,
      updated_at = NOW()
  WHERE is_published = FALSE
    AND publish_at IS NOT NULL
    AND publish_at <= NOW();
    
  -- Unpublish sections that are scheduled to unpublish
  UPDATE sections
  SET is_published = FALSE,
      updated_at = NOW()
  WHERE is_published = TRUE
    AND unpublish_at IS NOT NULL
    AND unpublish_at <= NOW();
END;
$$;

-- ============================================================
-- Function: Auto-publish lessons at scheduled time
-- ============================================================
CREATE OR REPLACE FUNCTION auto_publish_lessons()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Publish lessons that are scheduled
  UPDATE lessons
  SET is_published = TRUE,
      updated_at = NOW()
  WHERE is_published = FALSE
    AND publish_at IS NOT NULL
    AND publish_at <= NOW();
    
  -- Unpublish lessons that are scheduled to unpublish
  UPDATE lessons
  SET is_published = FALSE,
      updated_at = NOW()
  WHERE is_published = TRUE
    AND unpublish_at IS NOT NULL
    AND unpublish_at <= NOW();
END;
$$;

-- ============================================================
-- Cron Job: Run auto-publish every minute
-- ============================================================
-- Note: Run these in Supabase Dashboard > Database > Extensions > pg_cron

-- SELECT cron.schedule('auto-publish-sections', '* * * * *', 'SELECT auto_publish_sections()');
-- SELECT cron.schedule('auto-publish-lessons', '* * * * *', 'SELECT auto_publish_lessons()');

-- ============================================================
-- RPC Function: Toggle Section Published Status
-- ============================================================
CREATE OR REPLACE FUNCTION toggle_section_published(
  p_section_id UUID,
  p_instructor_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_section RECORD;
  v_course RECORD;
BEGIN
  -- Get section
  SELECT * INTO v_section FROM sections WHERE id = p_section_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Section not found');
  END IF;
  
  -- Verify ownership
  SELECT * INTO v_course FROM courses WHERE id = v_section.course_id AND instructor_id = p_instructor_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authorized');
  END IF;
  
  -- Toggle status
  UPDATE sections
  SET is_published = NOT is_published,
      publish_at = NULL,
      unpublish_at = NULL,
      updated_at = NOW()
  WHERE id = p_section_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'is_published', NOT v_section.is_published
  );
END;
$$;

-- ============================================================
-- RPC Function: Schedule Section Publishing
-- ============================================================
CREATE OR REPLACE FUNCTION schedule_section_publish(
  p_section_id UUID,
  p_instructor_id UUID,
  p_publish_at TIMESTAMPTZ DEFAULT NULL,
  p_unpublish_at TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_section RECORD;
  v_course RECORD;
BEGIN
  -- Get section
  SELECT * INTO v_section FROM sections WHERE id = p_section_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Section not found');
  END IF;
  
  -- Verify ownership
  SELECT * INTO v_course FROM courses WHERE id = v_section.course_id AND instructor_id = p_instructor_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authorized');
  END IF;
  
  -- Update schedule
  UPDATE sections
  SET publish_at = p_publish_at,
      unpublish_at = p_unpublish_at,
      updated_at = NOW()
  WHERE id = p_section_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'publish_at', p_publish_at,
    'unpublish_at', p_unpublish_at
  );
END;
$$;

-- ============================================================
-- RPC Function: Toggle Lesson Published Status
-- ============================================================
CREATE OR REPLACE FUNCTION toggle_lesson_published(
  p_lesson_id UUID,
  p_instructor_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_lesson RECORD;
  v_course RECORD;
BEGIN
  -- Get lesson
  SELECT * INTO v_lesson FROM lessons WHERE id = p_lesson_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Lesson not found');
  END IF;
  
  -- Verify ownership
  SELECT * INTO v_course FROM courses WHERE id = v_lesson.course_id AND instructor_id = p_instructor_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authorized');
  END IF;
  
  -- Toggle status
  UPDATE lessons
  SET is_published = NOT is_published,
      publish_at = NULL,
      unpublish_at = NULL,
      updated_at = NOW()
  WHERE id = p_lesson_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'is_published', NOT v_lesson.is_published
  );
END;
$$;

-- ============================================================
-- RPC Function: Schedule Lesson Publishing
-- ============================================================
CREATE OR REPLACE FUNCTION schedule_lesson_publish(
  p_lesson_id UUID,
  p_instructor_id UUID,
  p_publish_at TIMESTAMPTZ DEFAULT NULL,
  p_unpublish_at TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_lesson RECORD;
  v_course RECORD;
BEGIN
  -- Get lesson
  SELECT * INTO v_lesson FROM lessons WHERE id = p_lesson_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Lesson not found');
  END IF;
  
  -- Verify ownership
  SELECT * INTO v_course FROM courses WHERE id = v_lesson.course_id AND instructor_id = p_instructor_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authorized');
  END IF;
  
  -- Update schedule
  UPDATE lessons
  SET publish_at = p_publish_at,
      unpublish_at = p_unpublish_at,
      updated_at = NOW()
  WHERE id = p_lesson_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'publish_at', p_publish_at,
    'unpublish_at', p_unpublish_at
  );
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION toggle_section_published TO authenticated;
GRANT EXECUTE ON FUNCTION schedule_section_publish TO authenticated;
GRANT EXECUTE ON FUNCTION toggle_lesson_published TO authenticated;
GRANT EXECUTE ON FUNCTION schedule_lesson_publish TO authenticated;
