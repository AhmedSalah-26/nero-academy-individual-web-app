-- ============================================================
-- Allow instructors to enroll students in their courses
-- ============================================================

-- Drop existing policy if exists
DROP POLICY IF EXISTS "Instructors can enroll students in their courses" ON enrollments;

-- Create policy for instructors to INSERT enrollments for their courses
CREATE POLICY "Instructors can enroll students in their courses" 
ON enrollments 
FOR INSERT 
WITH CHECK (
  -- The instructor_id in the enrollment must match the current user
  -- AND the course must belong to this instructor
  instructor_id = auth.uid() 
  AND EXISTS (
    SELECT 1 FROM courses 
    WHERE courses.id = course_id 
    AND courses.instructor_id = auth.uid()
  )
);

-- Also allow instructors to UPDATE enrollments for their courses
DROP POLICY IF EXISTS "Instructors can update enrollments for their courses" ON enrollments;

CREATE POLICY "Instructors can update enrollments for their courses" 
ON enrollments 
FOR UPDATE 
USING (
  EXISTS (
    SELECT 1 FROM courses 
    WHERE courses.id = enrollments.course_id 
    AND courses.instructor_id = auth.uid()
  )
);

-- Also allow instructors to DELETE enrollments for their courses
DROP POLICY IF EXISTS "Instructors can delete enrollments for their courses" ON enrollments;

CREATE POLICY "Instructors can delete enrollments for their courses" 
ON enrollments 
FOR DELETE 
USING (
  EXISTS (
    SELECT 1 FROM courses 
    WHERE courses.id = enrollments.course_id 
    AND courses.instructor_id = auth.uid()
  )
);

-- ============================================================
-- Helper functions for enrolled count
-- ============================================================

-- Increment enrolled count
CREATE OR REPLACE FUNCTION increment_enrolled_count(p_course_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE courses 
  SET enrolled_count = COALESCE(enrolled_count, 0) + 1,
      updated_at = NOW()
  WHERE id = p_course_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Decrement enrolled count
CREATE OR REPLACE FUNCTION decrement_enrolled_count(p_course_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE courses 
  SET enrolled_count = GREATEST(COALESCE(enrolled_count, 0) - 1, 0),
      updated_at = NOW()
  WHERE id = p_course_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
