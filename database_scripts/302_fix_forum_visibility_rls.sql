-- ============================================================
-- 🔐 FIX: Forum Visibility for Enrolled Students
-- إصلاح: ظهور المنتديات للطلاب المسجلين
-- Version: 2.0 | February 2026
-- Safe to re-run (idempotent)
-- ============================================================
-- 
-- المشكلة: الطالب المسجل في كورس غير منشور (is_published=false)
-- مش بيقدر يشوف الكورس في قائمة المنتديات لأن RLS على جدول courses
-- بيسمح فقط برؤية الكورسات المنشورة
-- 
-- الحل: استخدام SECURITY DEFINER function لتجاوز RLS
-- ============================================================

-- Drop old RLS policy if it was applied
DROP POLICY IF EXISTS "Enrolled students can view their courses" ON courses;

-- Drop existing function (all overloads)
DROP FUNCTION IF EXISTS get_forum_courses_for_user(UUID, BOOLEAN, TEXT, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_forum_courses_for_user;

-- Create SECURITY DEFINER function to get forum courses
-- This bypasses RLS, so enrolled students can see unpublished courses
CREATE OR REPLACE FUNCTION get_forum_courses_for_user(
  p_user_id UUID,
  p_is_published BOOLEAN DEFAULT NULL,
  p_search TEXT DEFAULT NULL,
  p_page INTEGER DEFAULT 1,
  p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  title_ar TEXT,
  title_en TEXT,
  is_published BOOLEAN,
  instructor_name TEXT,
  created_at TIMESTAMPTZ
) AS $$
DECLARE
  v_offset INTEGER;
BEGIN
  v_offset := (p_page - 1) * p_limit;
  
  RETURN QUERY
  SELECT DISTINCT
    c.id,
    c.title_ar,
    c.title_en,
    c.is_published,
    p.name AS instructor_name,
    c.created_at
  FROM courses c
  LEFT JOIN profiles p ON p.id = c.instructor_id
  WHERE (
    -- User is enrolled in this course
    EXISTS (
      SELECT 1 FROM enrollments e
      WHERE e.course_id = c.id AND e.user_id = p_user_id
    )
    OR
    -- User is the instructor of this course
    c.instructor_id = p_user_id
  )
  -- Optional published filter
  AND (p_is_published IS NULL OR c.is_published = p_is_published)
  -- Optional search filter
  AND (
    p_search IS NULL 
    OR c.title_ar ILIKE '%' || p_search || '%'
    OR c.title_en ILIKE '%' || p_search || '%'
    OR p.name ILIKE '%' || p_search || '%'
  )
  ORDER BY c.created_at DESC
  LIMIT p_limit
  OFFSET v_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_forum_courses_for_user(UUID, BOOLEAN, TEXT, INTEGER, INTEGER) TO authenticated;
