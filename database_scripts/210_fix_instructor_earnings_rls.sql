-- Fix RLS policy for instructor_earnings table
-- Allow inserts during checkout (when student buys a course)

-- Drop existing insert policy if any
DROP POLICY IF EXISTS "Allow insert on checkout" ON instructor_earnings;
DROP POLICY IF EXISTS "System can insert earnings" ON instructor_earnings;

-- Create policy to allow authenticated users to insert earnings
-- This is needed because the checkout process runs as the student user
-- but needs to create an earning record for the instructor
CREATE POLICY "Allow insert on checkout" ON instructor_earnings
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Alternative: If you want more restrictive policy, use a function
-- This allows insert only if the user is buying a course (has enrollment)
-- CREATE POLICY "Allow insert on checkout" ON instructor_earnings
-- FOR INSERT
-- TO authenticated
-- WITH CHECK (
--   EXISTS (
--     SELECT 1 FROM enrollments e
--     WHERE e.id = instructor_earnings.enrollment_id
--     AND e.user_id = auth.uid()
--   )
-- );

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
WHERE tablename = 'instructor_earnings';
