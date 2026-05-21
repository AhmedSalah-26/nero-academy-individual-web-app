-- ============================================================
-- Fix: Issue Certificate Function
-- This function creates a certificate when a course is completed
-- ============================================================

-- Drop existing function if exists
DROP FUNCTION IF EXISTS issue_certificate(UUID);

-- Create the function with correct syntax
CREATE OR REPLACE FUNCTION issue_certificate(p_course_id UUID)
RETURNS JSON AS $$$
DECLARE
  v_user_id UUID := auth.uid();
  v_enrollment RECORD;
  v_course RECORD;
  v_instructor RECORD;
  v_user RECORD;
  v_certificate_id UUID;
  v_certificate_number TEXT;
  v_verification_code TEXT;
BEGIN
  -- Get enrollment (must be completed)
  SELECT * INTO v_enrollment
  FROM enrollments
  WHERE user_id = v_user_id 
    AND course_id = p_course_id 
    AND status = 'completed';
  
  IF v_enrollment IS NULL THEN
    -- Check if enrollment exists but not completed
    SELECT * INTO v_enrollment
    FROM enrollments
    WHERE user_id = v_user_id AND course_id = p_course_id;
    
    IF v_enrollment IS NULL THEN
      RETURN json_build_object('success', false, 'error', 'Not enrolled in this course');
    ELSE
      RETURN json_build_object('success', false, 'error', 'Course not completed yet');
    END IF;
  END IF;
  
  -- Check if certificate already exists
  IF v_enrollment.certificate_id IS NOT NULL THEN
    RETURN json_build_object(
      'success', true, 
      'certificate_id', v_enrollment.certificate_id, 
      'already_issued', true
    );
  END IF;
  
  -- Get course info
  SELECT * INTO v_course FROM courses WHERE id = p_course_id;
  
  IF v_course IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Course not found');
  END IF;
  
  IF NOT v_course.has_certificate THEN
    RETURN json_build_object('success', false, 'error', 'Course does not offer certificates');
  END IF;
  
  -- Get instructor info
  SELECT name INTO v_instructor FROM profiles WHERE id = v_course.instructor_id;
  
  -- Get user info
  SELECT name INTO v_user FROM profiles WHERE id = v_user_id;
  
  -- Generate certificate number and verification code
  v_certificate_number := 'CERT-' || UPPER(SUBSTRING(gen_random_uuid()::TEXT, 1, 8));
  v_verification_code := UPPER(SUBSTRING(gen_random_uuid()::TEXT, 1, 12));
  
  -- Create certificate
  INSERT INTO certificates (
    user_id, 
    course_id, 
    enrollment_id,
    certificate_number, 
    verification_code,
    student_name, 
    course_title, 
    instructor_name,
    completion_date,
    is_valid,
    issued_at
  )
  VALUES (
    v_user_id, 
    p_course_id, 
    v_enrollment.id,
    v_certificate_number, 
    v_verification_code,
    COALESCE(v_user.name, 'Student'),
    COALESCE(v_course.title_ar, v_course.title_en, 'Course'),
    COALESCE(v_instructor.name, 'Instructor'),
    CURRENT_DATE,
    true,
    NOW()
  )
  RETURNING id INTO v_certificate_id;
  
  -- Update enrollment with certificate_id
  UPDATE enrollments 
  SET certificate_id = v_certificate_id 
  WHERE id = v_enrollment.id;
  
  -- Return success with certificate info
  RETURN json_build_object(
    'success', true,
    'certificate_id', v_certificate_id,
    'certificate_number', v_certificate_number,
    'verification_code', v_verification_code,
    'already_issued', false
  );
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false, 
    'error', SQLERRM
  );
END;
$$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION issue_certificate(UUID) TO authenticated;
