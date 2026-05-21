-- Final setup for the Parent Portal RPC

CREATE OR REPLACE FUNCTION get_parent_dashboard(p_phone TEXT)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  -- We aggregate all students into a json array
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
            'enrolled_at', e.created_at,
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
        JOIN courses c ON e.course_id = c.id
        LEFT JOIN profiles i ON c.instructor_id = i.id
        WHERE e.user_id = p.id AND e.status IN ('active', 'completed')
      ),
      'quizzes', (
        SELECT COALESCE(json_agg(
          json_build_object(
            'course_title_ar', COALESCE(qc.title_ar, ''),
            'course_title_en', COALESCE(qc.title_en, ''),
            'quiz_title_ar', COALESCE(q.title_ar, ''),
            'quiz_title_en', COALESCE(q.title_en, ''),
            'score', qa.score,
            'total_score', qa.total_points,  /* Corrected column */
            'is_passed', qa.passed,          /* Corrected column */
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
