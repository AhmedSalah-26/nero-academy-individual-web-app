-- ============================================================
-- Fix Instructor Search - Ensure instructor_profiles has data
-- ============================================================

-- First, ensure all instructors in profiles have entries in instructor_profiles
INSERT INTO instructor_profiles (
  instructor_id,
  display_name,
  headline_ar,
  headline_en,
  bio_ar,
  bio_en,
  is_active,
  created_at,
  updated_at
)
SELECT 
  p.id,
  COALESCE(p.name, p.email),
  'مدرس محترف',
  'Professional Instructor',
  'مدرس متخصص في مجاله',
  'Specialized instructor in their field',
  TRUE,
  NOW(),
  NOW()
FROM profiles p
WHERE p.role = 'instructor'
  AND NOT EXISTS (
    SELECT 1 FROM instructor_profiles ip 
    WHERE ip.instructor_id = p.id
  );

-- Update instructor_profiles with actual stats from courses
UPDATE instructor_profiles ip
SET 
  total_courses = (
    SELECT COUNT(*) 
    FROM courses c 
    WHERE c.instructor_id = ip.instructor_id 
      AND c.is_published = TRUE
  ),
  total_students = (
    SELECT COUNT(DISTINCT e.user_id)
    FROM enrollments e
    JOIN courses c ON c.id = e.course_id
    WHERE c.instructor_id = ip.instructor_id
  ),
  average_rating = (
    SELECT COALESCE(AVG(c.rating), 0)
    FROM courses c
    WHERE c.instructor_id = ip.instructor_id
      AND c.is_published = TRUE
      AND c.rating IS NOT NULL
  ),
  total_reviews = (
    SELECT COALESCE(SUM(c.rating_count), 0)
    FROM courses c
    WHERE c.instructor_id = ip.instructor_id
      AND c.is_published = TRUE
  ),
  updated_at = NOW()
WHERE ip.is_active = TRUE;

-- Verify the data
SELECT 
  ip.id,
  ip.display_name,
  ip.total_students,
  ip.total_courses,
  ip.average_rating,
  ip.is_active
FROM instructor_profiles ip
WHERE ip.is_active = TRUE
ORDER BY ip.total_students DESC
LIMIT 10;
