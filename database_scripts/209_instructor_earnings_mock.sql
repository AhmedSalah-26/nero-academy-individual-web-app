-- Fix missing instructor_earnings for existing enrollments
-- This script adds earnings records for enrollments that don't have them

-- Insert earnings for all paid enrollments that don't have earnings yet
INSERT INTO instructor_earnings (
    instructor_id,
    enrollment_id,
    course_id,
    gross_amount,
    platform_fee,
    net_amount,
    revenue_share,
    status,
    available_at,
    created_at
)
SELECT 
    e.instructor_id,
    e.id as enrollment_id,
    e.course_id,
    e.price as gross_amount,
    e.price * 0.30 as platform_fee,  -- 30% platform fee
    e.price * 0.70 as net_amount,     -- 70% to instructor
    70.00 as revenue_share,
    'available' as status,            -- Make it available immediately for existing enrollments
    NOW() as available_at,
    e.enrolled_at as created_at
FROM enrollments e
WHERE e.price > 0                     -- Only paid enrollments
  AND e.instructor_id IS NOT NULL     -- Must have instructor
  AND e.status = 'active'             -- Only active enrollments
  AND NOT EXISTS (                    -- Don't duplicate
      SELECT 1 FROM instructor_earnings ie 
      WHERE ie.enrollment_id = e.id
  );

-- Show results
SELECT 
    ie.id,
    ie.instructor_id,
    ie.course_id,
    ie.gross_amount,
    ie.net_amount,
    ie.status,
    c.title_ar as course_title,
    p.name as instructor_name
FROM instructor_earnings ie
JOIN courses c ON c.id = ie.course_id
JOIN profiles p ON p.id = ie.instructor_id
ORDER BY ie.created_at DESC;
