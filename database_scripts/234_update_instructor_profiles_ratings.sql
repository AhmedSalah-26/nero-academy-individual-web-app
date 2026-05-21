-- Update instructor_profiles table with real ratings from course_reviews
-- This script calculates instructor ratings from actual course reviews

DO $$
DECLARE
  instructor_record RECORD;
  v_total_reviews INTEGER;
  v_avg_rating DECIMAL(3,2);
BEGIN
  -- Loop through all instructor profiles
  FOR instructor_record IN 
    SELECT id, instructor_id FROM instructor_profiles
  LOOP
    -- Calculate average rating and total reviews from course_reviews
    SELECT 
      COALESCE(AVG(cr.rating), 0)::DECIMAL(3,2),
      COUNT(cr.id)
    INTO v_avg_rating, v_total_reviews
    FROM course_reviews cr
    INNER JOIN courses c ON c.id = cr.course_id
    WHERE c.instructor_id = instructor_record.instructor_id;
    
    -- Update instructor profile
    UPDATE instructor_profiles
    SET 
      average_rating = v_avg_rating,
      total_reviews = v_total_reviews,
      updated_at = NOW()
    WHERE id = instructor_record.id;
    
    RAISE NOTICE 'Updated instructor %: rating=%, reviews=%', 
      instructor_record.instructor_id, v_avg_rating, v_total_reviews;
  END LOOP;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Instructor ratings updated successfully';
  RAISE NOTICE '========================================';
END $$;
