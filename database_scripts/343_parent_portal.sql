-- Add parent_phone to profiles for the public parent portal
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS parent_phone TEXT;

-- Create an RPC to fetch the parent dashboard data based simply on the parent phone
CREATE OR REPLACE FUNCTION get_parent_dashboard(p_phone TEXT)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_agg(
    json_build_object(
      'id', p.id,
      'name', p.name,
      'avatar_url', p.avatar_url,
      'courses', (
        SELECT COALESCE(json_agg(
          json_build_object(
            'title_ar', c.title_ar,
            'title_en', c.title_en,
            'instructor_name', i.name,
            'progress', (
              SELECT COALESCE(
                 (SELECT count(*)::float FROM lesson_progress lp 
                  JOIN lessons l2 ON l2.id = lp.lesson_id 
                  WHERE lp.user_id = p.id AND l2.section_id IN (SELECT id FROM sections WHERE course_id = c.id) AND lp.is_completed = true)
                  / NULLIF((SELECT count(*)::float FROM lessons l3 
                            WHERE l3.section_id IN (SELECT id FROM sections WHERE course_id = c.id)), 0)
                * 100, 0
              )::int
            )
          )
        ), '[]'::json)
        FROM enrollments e
        JOIN parent_enrollments pe ON e.parent_enrollment_id = pe.id
        JOIN courses c ON e.course_id = c.id
        LEFT JOIN profiles i ON c.instructor_id = i.id
        WHERE pe.user_id = p.id AND pe.payment_status IN ('completed', 'free')
      ),
      'quizzes', (
        SELECT COALESCE(json_agg(
          json_build_object(
            'course_title_ar', qc.title_ar,
            'course_title_en', qc.title_en,
            'quiz_title_ar', q.title_ar,
            'quiz_title_en', q.title_en,
            'score', qa.score,
            'total_score', qa.total_points,
            'is_passed', qa.passed,
            'completed_at', qa.completed_at
          )
        ), '[]'::json)
        FROM quiz_attempts qa
        JOIN quizzes q ON qa.quiz_id = q.id
        LEFT JOIN courses qc ON q.course_id = qc.id
        WHERE qa.user_id = p.id AND qa.completed_at IS NOT NULL
      )
    )
  ) INTO result
  FROM public.profiles p
  WHERE p.parent_phone = p_phone AND p.parent_phone IS NOT NULL AND p.parent_phone != '';
  
  RETURN COALESCE(result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
