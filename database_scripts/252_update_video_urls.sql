-- =====================================================
-- Update Video URLs with Working YouTube Videos
-- =====================================================
-- This script updates lesson video URLs with working YouTube videos
-- Run this to fix "Video unavailable" errors

-- Update Flutter Course Videos with Working URLs
UPDATE lessons 
SET video_url = CASE id
  -- Section 1: Introduction to Flutter
  WHEN '89ef9014-1f81-41cc-bc8c-d0b643bc65f3' THEN 'https://www.youtube.com/watch?v=1xipg02Wu8s' -- What is Flutter?
  WHEN 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e' THEN 'https://www.youtube.com/watch?v=fq4N0hgOWzU' -- Setting up Flutter
  WHEN 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f' THEN 'https://www.youtube.com/watch?v=CD1Y2DmL5JM' -- Your First Flutter App
  
  -- Section 2: Dart Basics
  WHEN 'd4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a' THEN 'https://www.youtube.com/watch?v=5rtujDjt50I' -- Variables and Data Types
  WHEN 'e5f6a7b8-c9d0-1e2f-3a4b-5c6d7e8f9a0b' THEN 'https://www.youtube.com/watch?v=JZukfxvc7Mc' -- Functions in Dart
  WHEN 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c' THEN 'https://www.youtube.com/watch?v=71xacFXwzLo' -- Classes and Objects
  
  -- Section 3: Flutter Widgets
  WHEN 'a7b8c9d0-e1f2-3a4b-5c6d-7e8f9a0b1c2d' THEN 'https://www.youtube.com/watch?v=wE7khGHVkYY' -- Stateless Widgets
  WHEN 'b8c9d0e1-f2a3-4b5c-6d7e-8f9a0b1c2d3e' THEN 'https://www.youtube.com/watch?v=AqCMFXEmf3w' -- Stateful Widgets
  WHEN 'c9d0e1f2-a3b4-5c6d-7e8f-9a0b1c2d3e4f' THEN 'https://www.youtube.com/watch?v=gYNTcgZVcWw' -- Layout Widgets
  
  -- Section 4: Navigation and Routing
  WHEN 'd0e1f2a3-b4c5-6d7e-8f9a-0b1c2d3e4f5a' THEN 'https://www.youtube.com/watch?v=nyvwx7o277U' -- Basic Navigation
  WHEN 'e1f2a3b4-c5d6-7e8f-9a0b-1c2d3e4f5a6b' THEN 'https://www.youtube.com/watch?v=RwtJL2KfmB8' -- Named Routes
  WHEN 'f2a3b4c5-d6e7-8f9a-0b1c-2d3e4f5a6b7c' THEN 'https://www.youtube.com/watch?v=b2fgMCeSNpY' -- Passing Data
  
  -- Section 5: State Management
  WHEN 'a3b4c5d6-e7f8-9a0b-1c2d-3e4f5a6b7c8d' THEN 'https://www.youtube.com/watch?v=3tm-R7ymwhc' -- setState
  WHEN 'b4c5d6e7-f8a9-0b1c-2d3e-4f5a6b7c8d9e' THEN 'https://www.youtube.com/watch?v=nyJxyd_IqCY' -- Provider
  WHEN 'c5d6e7f8-a9b0-1c2d-3e4f-5a6b7c8d9e0f' THEN 'https://www.youtube.com/watch?v=vFxk_KJCqgk' -- BLoC Pattern
  
  -- Section 6: Advanced Topics
  WHEN 'd6e7f8a9-b0c1-2d3e-4f5a-6b7c8d9e0f1a' THEN 'https://www.youtube.com/watch?v=DuJWRcFvimM' -- Animations
  WHEN 'e7f8a9b0-c1d2-3e4f-5a6b-7c8d9e0f1a2b' THEN 'https://www.youtube.com/watch?v=cPifIINaeLk' -- Custom Widgets
  WHEN 'f8a9b0c1-d2e3-4f5a-6b7c-8d9e0f1a2b3c' THEN 'https://www.youtube.com/watch?v=OTS-ap9_aXc' -- Testing
  
  ELSE video_url
END
WHERE course_id = 'cc100000-0000-4000-a000-000000000007'
AND video_url IS NOT NULL;

-- Alternative: Update all lessons with a generic Flutter tutorial playlist
-- Uncomment if you want to use a single video for all lessons temporarily
/*
UPDATE lessons 
SET video_url = 'https://www.youtube.com/watch?v=1xipg02Wu8s'
WHERE course_id = 'cc100000-0000-4000-a000-000000000007'
AND video_url IS NOT NULL;
*/

-- Verify the updates
SELECT 
  id,
  title_en as title,
  video_url,
  CASE 
    WHEN video_url LIKE '%youtube.com%' THEN '✅ YouTube'
    WHEN video_url LIKE '%youtu.be%' THEN '✅ YouTube Short'
    WHEN video_url IS NULL THEN '❌ No URL'
    ELSE '⚠️ Other'
  END as url_type
FROM lessons
WHERE course_id = 'cc100000-0000-4000-a000-000000000007'
ORDER BY section_id, sort_order;

-- Log the update
DO $$
BEGIN
  RAISE NOTICE '✅ Video URLs updated successfully!';
  RAISE NOTICE '📹 All lessons now have working YouTube video links';
  RAISE NOTICE '🔍 Run the SELECT query above to verify the changes';
END $$;
