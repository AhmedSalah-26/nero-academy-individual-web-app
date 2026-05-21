-- ============================================================
-- Fix Storage Policies for Quiz Question Images
-- ============================================================
-- This script adds RLS policies to allow instructors to upload
-- images for quiz questions to the 'courses' storage bucket

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Instructors can upload quiz images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view quiz images" ON storage.objects;

-- Policy 1: Allow instructors to upload quiz question images
-- Path format: quiz_questions/quiz_{quizId}_{timestamp}.jpg
CREATE POLICY "Instructors can upload quiz images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'courses' 
  AND (storage.foldername(name))[1] = 'quiz_questions'
  AND EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('instructor', 'admin')
  )
);

-- Policy 2: Allow instructors to update their quiz images
CREATE POLICY "Instructors can update quiz images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'courses' 
  AND (storage.foldername(name))[1] = 'quiz_questions'
  AND EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('instructor', 'admin')
  )
);

-- Policy 3: Allow instructors to delete their quiz images
CREATE POLICY "Instructors can delete quiz images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'courses' 
  AND (storage.foldername(name))[1] = 'quiz_questions'
  AND EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('instructor', 'admin')
  )
);

-- Policy 4: Allow anyone (including students) to view quiz images
CREATE POLICY "Anyone can view quiz images"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'courses' 
  AND (storage.foldername(name))[1] = 'quiz_questions'
);

-- Verify policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'objects'
  AND policyname LIKE '%quiz images%'
ORDER BY policyname;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Quiz question images storage policies created successfully';
  RAISE NOTICE '📁 Instructors can now upload images to: courses/quiz_questions/';
  RAISE NOTICE '👁️ All authenticated users can view quiz images';
END $$;
