-- Test if the trigger is working
-- This script will check if triggers exist and test them

-- Check if triggers exist
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name IN ('trigger_update_course_rating', 'trigger_update_instructor_rating');

-- Check if functions exist
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_name IN ('update_course_rating', 'update_instructor_rating')
  AND routine_schema = 'public';

-- Test: Insert a review and check if course rating updates
DO $$
DECLARE
  test_course_id UUID;
  test_user_id UUID;
  rating_before DECIMAL(3,2);
  rating_after DECIMAL(3,2);
  count_before INTEGER;
  count_after INTEGER;
BEGIN
  -- Get a test course
  SELECT id INTO test_course_id FROM courses LIMIT 1;
  
  -- Get a test user
  SELECT id INTO test_user_id FROM profiles WHERE role = 'student' LIMIT 1;
  
  IF test_course_id IS NULL OR test_user_id IS NULL THEN
    RAISE NOTICE 'No test data available';
    RETURN;
  END IF;
  
  -- Get rating before
  SELECT rating, rating_count INTO rating_before, count_before
  FROM courses WHERE id = test_course_id;
  
  RAISE NOTICE 'Before: Course % has rating=%, count=%', test_course_id, rating_before, count_before;
  
  -- Delete existing review if any
  DELETE FROM course_reviews 
  WHERE course_id = test_course_id AND user_id = test_user_id;
  
  -- Insert test review
  INSERT INTO course_reviews (course_id, user_id, rating, review)
  VALUES (test_course_id, test_user_id, 5, 'Test review from trigger test');
  
  -- Get rating after
  SELECT rating, rating_count INTO rating_after, count_after
  FROM courses WHERE id = test_course_id;
  
  RAISE NOTICE 'After: Course % has rating=%, count=%', test_course_id, rating_after, count_after;
  
  -- Check if trigger worked
  IF rating_after != rating_before OR count_after != count_before THEN
    RAISE NOTICE '✅ SUCCESS: Trigger is working! Rating changed from % to %', rating_before, rating_after;
  ELSE
    RAISE NOTICE '❌ FAILED: Trigger is NOT working! Rating stayed at %', rating_after;
  END IF;
  
  -- Cleanup
  DELETE FROM course_reviews 
  WHERE course_id = test_course_id AND user_id = test_user_id;
  
END $$;
