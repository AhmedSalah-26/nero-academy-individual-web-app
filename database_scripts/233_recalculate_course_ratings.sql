-- Reset all course ratings to zero, then recalculate from course_reviews table
-- This script removes all fake ratings and calculates real ratings from actual reviews

DO $$
DECLARE
  total_courses INTEGER;
  courses_with_reviews INTEGER;
  courses_without_reviews INTEGER;
  total_reviews INTEGER;
BEGIN
  -- Step 1: Reset all ratings to zero
  UPDATE courses
  SET 
    rating = 0,
    rating_count = 0,
    updated_at = NOW();

  RAISE NOTICE 'Step 1: All course ratings reset to zero';

  -- Step 2: Recalculate ratings from course_reviews table
  UPDATE courses
  SET 
    rating = COALESCE(
      (SELECT AVG(rating)::DECIMAL(3,2)
       FROM course_reviews
       WHERE course_reviews.course_id = courses.id),
      0
    ),
    rating_count = COALESCE(
      (SELECT COUNT(*)
       FROM course_reviews
       WHERE course_reviews.course_id = courses.id),
      0
    ),
    updated_at = NOW()
  WHERE EXISTS (
    SELECT 1 FROM course_reviews WHERE course_reviews.course_id = courses.id
  );

  -- Step 3: Get statistics
  SELECT COUNT(*) INTO total_courses FROM courses;
  SELECT COUNT(DISTINCT course_id) INTO courses_with_reviews FROM course_reviews;
  SELECT COUNT(*) INTO total_reviews FROM course_reviews;
  SELECT COUNT(*) INTO courses_without_reviews FROM courses WHERE rating_count = 0;
  
  -- Step 4: Log the results
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Rating recalculation completed:';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Total courses: %', total_courses;
  RAISE NOTICE 'Courses with reviews: %', courses_with_reviews;
  RAISE NOTICE 'Courses without reviews (rating = 0): %', courses_without_reviews;
  RAISE NOTICE 'Total reviews in database: %', total_reviews;
  RAISE NOTICE '========================================';
END $$;


