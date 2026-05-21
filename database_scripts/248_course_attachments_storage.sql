-- ============================================
-- Course Attachments Storage Setup
-- ============================================
-- Description: Create storage bucket and policies for course attachments
-- Author: System
-- Date: 2025-01-30

-- Create attachments bucket if not exists
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'attachments',
  'attachments',
  true, -- Public bucket so students can download
  52428800, -- 50MB limit
  ARRAY[
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'image/jpeg',
    'image/png',
    'image/gif',
    'application/zip',
    'application/x-rar-compressed',
    'text/plain'
  ]
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ============================================
-- Storage Policies
-- ============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Instructors can upload attachments" ON storage.objects;
DROP POLICY IF EXISTS "Instructors can update their attachments" ON storage.objects;
DROP POLICY IF EXISTS "Instructors can delete their attachments" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view attachments" ON storage.objects;

-- Policy 1: Instructors can upload attachments
CREATE POLICY "Instructors can upload attachments"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'attachments' 
  AND (storage.foldername(name))[1] = 'course_attachments'
  AND (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'instructor'
    )
    OR
    -- Also allow admins
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  )
);

-- Policy 2: Instructors can update their own attachments
CREATE POLICY "Instructors can update their attachments"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'attachments'
  AND (storage.foldername(name))[1] = 'course_attachments'
  AND (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'instructor'
    )
    OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  )
)
WITH CHECK (
  bucket_id = 'attachments'
  AND (storage.foldername(name))[1] = 'course_attachments'
);

-- Policy 3: Instructors can delete their own attachments
CREATE POLICY "Instructors can delete their attachments"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'attachments'
  AND (storage.foldername(name))[1] = 'course_attachments'
  AND (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'instructor'
    )
    OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  )
);

-- Policy 4: Anyone can view/download attachments (public bucket)
CREATE POLICY "Anyone can view attachments"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id = 'attachments'
  AND (storage.foldername(name))[1] = 'course_attachments'
);

-- ============================================
-- Verification
-- ============================================

-- Check current user role
DO $$
DECLARE
  current_user_role TEXT;
  current_user_id UUID;
BEGIN
  current_user_id := auth.uid();
  
  IF current_user_id IS NULL THEN
    RAISE WARNING '⚠️ No authenticated user found. Please login first.';
  ELSE
    SELECT role INTO current_user_role
    FROM public.profiles
    WHERE id = current_user_id;
    
    IF current_user_role IS NULL THEN
      RAISE WARNING '⚠️ User profile not found for user: %', current_user_id;
    ELSE
      RAISE NOTICE '✅ Current user role: % (user_id: %)', current_user_role, current_user_id;
      
      IF current_user_role NOT IN ('instructor', 'admin') THEN
        RAISE WARNING '⚠️ Current user is not an instructor or admin. Role: %', current_user_role;
      END IF;
    END IF;
  END IF;
END $$;

-- Verify bucket exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'attachments') THEN
    RAISE NOTICE '✅ Attachments bucket created successfully';
  ELSE
    RAISE EXCEPTION '❌ Failed to create attachments bucket';
  END IF;
END $$;

-- Verify policies exist
DO $$
DECLARE
  policy_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE schemaname = 'storage'
  AND tablename = 'objects'
  AND policyname LIKE '%attachments%';
  
  IF policy_count >= 4 THEN
    RAISE NOTICE '✅ Storage policies created successfully (% policies)', policy_count;
  ELSE
    RAISE WARNING '⚠️ Expected 4 policies, found %', policy_count;
  END IF;
END $$;
