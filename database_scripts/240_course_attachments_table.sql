-- ============================================================
-- Course Attachments Table
-- مرفقات الكورس (على مستوى الكورس وليس الدرس)
-- ============================================================

-- Create course_attachments table
CREATE TABLE IF NOT EXISTS course_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_name_ar TEXT,
  file_url TEXT NOT NULL,
  file_type TEXT, -- pdf, zip, doc, jpg, png, etc.
  file_size INTEGER, -- in bytes
  download_count INTEGER DEFAULT 0,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_course_attachments_course ON course_attachments(course_id);
CREATE INDEX IF NOT EXISTS idx_course_attachments_sort ON course_attachments(course_id, sort_order);

-- Enable RLS
ALTER TABLE course_attachments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid errors on re-run)
DROP POLICY IF EXISTS "Instructors can manage their course attachments" ON course_attachments;
DROP POLICY IF EXISTS "Enrolled students can view course attachments" ON course_attachments;
DROP POLICY IF EXISTS "Admins can manage all attachments" ON course_attachments;

-- Policy: Instructors can manage their course attachments
CREATE POLICY "Instructors can manage their course attachments"
ON course_attachments
FOR ALL
USING (
  course_id IN (
    SELECT id FROM courses WHERE instructor_id = auth.uid()
  )
);

-- Policy: Enrolled students can view course attachments
CREATE POLICY "Enrolled students can view course attachments"
ON course_attachments
FOR SELECT
USING (
  course_id IN (
    SELECT course_id FROM enrollments 
    WHERE user_id = auth.uid() AND status = 'active'
  )
);

-- Policy: Admins can manage all attachments
CREATE POLICY "Admins can manage all attachments"
ON course_attachments
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  )
);

COMMENT ON TABLE course_attachments IS 'Course-level attachments (PDFs, images, documents) that apply to the entire course';

-- ============================================================
-- NOTE: The lessons table type constraint is NOT modified here.
-- The application code has been updated to only allow 'video' type.
-- Existing lessons with other types will remain as they are.
-- If you want to convert all existing lessons to video type, 
-- run this query manually:
-- UPDATE lessons SET type = 'video' WHERE type != 'video';
-- ============================================================
