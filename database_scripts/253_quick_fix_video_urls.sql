-- =====================================================
-- Quick Fix: Update All Video URLs with Working Video
-- =====================================================
-- This is a quick fix to replace all broken video URLs
-- with a working Flutter tutorial video

-- Update all Flutter course videos with a working YouTube video
UPDATE lessons 
SET video_url = 'https://www.youtube.com/watch?v=1xipg02Wu8s'
WHERE course_id = 'cc100000-0000-4000-a000-000000000007'
AND video_url IS NOT NULL;

-- Verify the update
SELECT 
  COUNT(*) as total_lessons,
  COUNT(CASE WHEN video_url IS NOT NULL THEN 1 END) as lessons_with_video,
  COUNT(CASE WHEN video_url = 'https://www.youtube.com/watch?v=1xipg02Wu8s' THEN 1 END) as updated_lessons
FROM lessons
WHERE course_id = 'cc100000-0000-4000-a000-000000000007';

-- Show updated lessons
SELECT 
  l.title as lesson_title,
  s.title as section_title,
  l.video_url,
  '✅ Updated' as status
FROM lessons l
JOIN sections s ON l.section_id = s.section_id
WHERE l.course_id = 'cc100000-0000-4000-a000-000000000007'
AND l.video_url IS NOT NULL
ORDER BY s.order_index, l.order_index;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Quick fix applied successfully!';
  RAISE NOTICE '📹 All lessons now use: https://www.youtube.com/watch?v=1xipg02Wu8s';
  RAISE NOTICE '💡 This is a working Flutter tutorial video';
  RAISE NOTICE '🔄 You can update individual lessons later with specific videos';
END $$;
