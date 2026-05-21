-- Fix update_lesson_progress function:
-- 1. Accept ANY enrollment status (not just 'active')
-- 2. Only update watch_time if new value is greater than existing

CREATE OR REPLACE FUNCTION update_lesson_progress(
  p_lesson_id UUID,
  p_watch_time INTEGER DEFAULT 0,
  p_last_position INTEGER DEFAULT 0,
  p_is_completed BOOLEAN DEFAULT FALSE
)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_course_id UUID;
  v_enrollment_id UUID;
  v_progress_id UUID;
  v_result JSON;
BEGIN
  -- Get course_id from lesson
  SELECT course_id INTO v_course_id FROM lessons WHERE id = p_lesson_id;
  
  IF v_course_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Lesson not found');
  END IF;
  
  -- Check enrollment - accept ANY status
  SELECT id INTO v_enrollment_id
  FROM enrollments
  WHERE user_id = v_user_id AND course_id = v_course_id;
  
  IF v_enrollment_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not enrolled in this course');
  END IF;
  
  -- Upsert progress - only update watch_time if new value is greater
  INSERT INTO lesson_progress (
    user_id, lesson_id, course_id, enrollment_id,
    watch_time, last_position, is_completed, completed_at
  )
  VALUES (
    v_user_id, p_lesson_id, v_course_id, v_enrollment_id,
    p_watch_time, p_last_position, p_is_completed,
    CASE WHEN p_is_completed THEN NOW() ELSE NULL END
  )
  ON CONFLICT (user_id, lesson_id) DO UPDATE SET
    watch_time = GREATEST(lesson_progress.watch_time, EXCLUDED.watch_time),
    last_position = EXCLUDED.last_position,
    is_completed = lesson_progress.is_completed OR EXCLUDED.is_completed,
    completed_at = COALESCE(lesson_progress.completed_at, EXCLUDED.completed_at),
    last_watched_at = NOW(),
    updated_at = NOW()
  RETURNING id INTO v_progress_id;
  
  -- Get updated enrollment progress
  SELECT json_build_object(
    'success', true,
    'progress_id', v_progress_id,
    'enrollment_id', v_enrollment_id,
    'course_progress', progress_percentage,
    'completed_lessons', completed_lessons,
    'total_watch_time', total_watch_time
  ) INTO v_result
  FROM enrollments WHERE id = v_enrollment_id;
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION update_lesson_progress TO authenticated;
