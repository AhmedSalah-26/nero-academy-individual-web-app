-- ============================================
-- Simple Course Attachments Storage Setup
-- ============================================
-- Description: Simplified storage setup with permissive policies for testing
-- Author: System
-- Date: 2025-01-30

-- Create attachments bucket if not exists (public bucket)
INSERT INTO storage.buckets (id, name, public)
VALUES ('attachments', 'attachments', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- ============================================
-- Simple Policies (for testing)
-- ============================================

-- Drop all existing policies
DROP POLICY IF EXISTS "Instructors can upload attachments" ON storage.objects;
DROP POLICY IF EXISTS "Instructors can update their attachments" ON storage.objects;
DROP POLICY IF EXISTS "Instructors can delete their attachments" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view attachments" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload to attachments" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update attachments" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete attachments" ON storage.objects;
DROP POLICY IF EXISTS "Public can read attachments" ON storage.objects;

-- Policy 1: Any authenticated user can upload
CREATE POLICY "Authenticated users can upload to attachments"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'attachments');

-- Policy 2: Any authenticated user can update
CREATE POLICY "Authenticated users can update attachments"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'attachments')
WITH CHECK (bucket_id = 'attachments');

-- Policy 3: Any authenticated user can delete
CREATE POLICY "Authenticated users can delete attachments"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'attachments');

-- Policy 4: Public can read (for downloads)
CREATE POLICY "Public can read attachments"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'attachments');

-- ============================================
-- Verification
-- ============================================

-- Check current user
DO $$
DECLARE
  current_user_id UUID;
  current_user_email TEXT;
  current_user_role TEXT;
BEGIN
  current_user_id := auth.uid();
  
  IF current_user_id IS NULL THEN
    RAISE WARNING '⚠️ No authenticated user. Please login first.';
  ELSE
    SELECT email INTO current_user_email
    FROM auth.users
    WHERE id = current_user_id;
    
    SELECT role INTO current_user_role
    FROM public.profiles
    WHERE id = current_user_id;
    
    RAISE NOTICE '✅ Authenticated as: % (role: %)', current_user_email, COALESCE(current_user_role, 'no profile');
  END IF;
END $$;

-- Verify bucket
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'attachments') 
    THEN '✅ Bucket exists'
    ELSE '❌ Bucket not found'
  END as bucket_status;

-- Verify policies
SELECT 
  COUNT(*) as policy_count,
  '✅ Policies created' as status
FROM pg_policies
WHERE schemaname = 'storage'
AND tablename = 'objects'
AND policyname LIKE '%attachments%';
