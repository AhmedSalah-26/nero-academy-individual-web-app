-- ============================================================
-- Debug Instructor Search - Diagnostic Script
-- ============================================================

-- 1. Check total instructors in instructor_profiles
SELECT 
  '1. Total Instructors' as check_name,
  COUNT(*) as count
FROM instructor_profiles;

-- 2. Check active instructors
SELECT 
  '2. Active Instructors' as check_name,
  COUNT(*) as count
FROM instructor_profiles
WHERE is_active = TRUE;

-- 3. List all instructors with details
SELECT 
  '3. Instructor Details' as section,
  id,
  display_name,
  headline_ar,
  headline_en,
  total_students,
  total_courses,
  average_rating,
  is_active,
  created_at
FROM instructor_profiles
ORDER BY total_students DESC;

-- 4. Check instructors with Arabic names
SELECT 
  '4. Arabic Names' as section,
  display_name,
  total_students,
  is_active
FROM instructor_profiles
WHERE display_name ~ '[ء-ي]'  -- Arabic characters
ORDER BY total_students DESC;

-- 5. Check instructors with English names
SELECT 
  '5. English Names' as section,
  display_name,
  total_students,
  is_active
FROM instructor_profiles
WHERE display_name ~ '[A-Za-z]'  -- English characters
ORDER BY total_students DESC;

-- 6. Check for NULL or empty names
SELECT 
  '6. NULL/Empty Names' as section,
  id,
  display_name,
  instructor_id,
  is_active
FROM instructor_profiles
WHERE display_name IS NULL 
   OR display_name = ''
   OR TRIM(display_name) = '';

-- 7. Check RLS policies
SELECT 
  '7. RLS Policies' as section,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'instructor_profiles';

-- 8. Test search query (example: searching for 'أحمد')
SELECT 
  '8. Search Test (أحمد)' as section,
  display_name,
  total_students,
  is_active
FROM instructor_profiles
WHERE LOWER(display_name) LIKE '%أحمد%'
   OR LOWER(headline_ar) LIKE '%أحمد%'
   OR LOWER(headline_en) LIKE '%أحمد%';

-- 9. Test search query (example: searching for 'ahmed')
SELECT 
  '9. Search Test (ahmed)' as section,
  display_name,
  total_students,
  is_active
FROM instructor_profiles
WHERE LOWER(display_name) LIKE '%ahmed%'
   OR LOWER(headline_ar) LIKE '%ahmed%'
   OR LOWER(headline_en) LIKE '%ahmed%';

-- 10. Check profiles table for instructors
SELECT 
  '10. Instructors in Profiles' as section,
  COUNT(*) as count
FROM profiles
WHERE role = 'instructor';

-- 11. Compare instructor_profiles with profiles
SELECT 
  '11. Missing in instructor_profiles' as section,
  p.id,
  p.name,
  p.email,
  p.role
FROM profiles p
WHERE p.role = 'instructor'
  AND NOT EXISTS (
    SELECT 1 FROM instructor_profiles ip 
    WHERE ip.instructor_id = p.id
  );

-- 12. Sample query that the app uses
SELECT 
  '12. App Query Simulation' as section,
  id,
  display_name,
  headline_ar,
  headline_en,
  total_students,
  total_courses,
  average_rating
FROM instructor_profiles
WHERE is_active = TRUE
ORDER BY total_students DESC
LIMIT 50;
