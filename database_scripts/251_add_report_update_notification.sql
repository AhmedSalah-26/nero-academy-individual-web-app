-- ============================================================
-- 🔔 ADD REPORT_UPDATE NOTIFICATION TYPE
-- إضافة نوع إشعار تحديث البلاغ
-- Version: 1.0 | January 2026
-- ============================================================

-- Drop and recreate the constraint to add 'report_update' type
ALTER TABLE notifications 
DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE notifications 
ADD CONSTRAINT notifications_type_check 
CHECK (type IN (
  'instructor_message',
  'course_update',
  'new_lesson',
  'quiz_result',
  'certificate_issued',
  'enrollment_confirmed',
  'payment_confirmed',
  'course_completed',
  'announcement',
  'promotion',
  'reminder',
  'report_update',
  'system'
));

-- ============================================================
-- Add admin_id and resolved_at columns to reports tables if not exist
-- ============================================================

-- Add columns to course_reports if they don't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'course_reports' AND column_name = 'admin_id') THEN
    ALTER TABLE course_reports ADD COLUMN admin_id UUID REFERENCES profiles(id) ON DELETE SET NULL;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'course_reports' AND column_name = 'admin_notes') THEN
    ALTER TABLE course_reports ADD COLUMN admin_notes TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'course_reports' AND column_name = 'resolved_at') THEN
    ALTER TABLE course_reports ADD COLUMN resolved_at TIMESTAMPTZ;
  END IF;
END $$;

-- Add columns to review_reports if they don't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'review_reports' AND column_name = 'admin_id') THEN
    ALTER TABLE review_reports ADD COLUMN admin_id UUID REFERENCES profiles(id) ON DELETE SET NULL;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'review_reports' AND column_name = 'admin_notes') THEN
    ALTER TABLE review_reports ADD COLUMN admin_notes TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'review_reports' AND column_name = 'resolved_at') THEN
    ALTER TABLE review_reports ADD COLUMN resolved_at TIMESTAMPTZ;
  END IF;
END $$;

-- Create indexes for the new columns
CREATE INDEX IF NOT EXISTS idx_course_reports_admin ON course_reports(admin_id);
CREATE INDEX IF NOT EXISTS idx_review_reports_admin ON review_reports(admin_id);
