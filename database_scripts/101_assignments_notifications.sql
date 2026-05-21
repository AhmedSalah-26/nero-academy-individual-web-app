-- ============================================================
-- 📝 ASSIGNMENTS & NOTIFICATIONS SYSTEM
-- إضافة نظام الواجبات والإشعارات
-- Version: 1.1 | January 2026
-- ============================================================

-- ============================================================
-- PART 1: ASSIGNMENTS SYSTEM (الواجبات)
-- ============================================================

-- 1.1 ASSIGNMENTS TABLE (تفاصيل الواجب)
CREATE TABLE IF NOT EXISTS assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  -- Basic Info
  title_ar TEXT NOT NULL,
  title_en TEXT,
  instructions_ar TEXT NOT NULL, -- تعليمات الواجب
  instructions_en TEXT,
  -- Settings
  max_score INTEGER DEFAULT 100, -- الدرجة القصوى
  passing_score INTEGER DEFAULT 60, -- درجة النجاح
  -- Deadline
  due_date TIMESTAMPTZ, -- موعد التسليم (NULL = no deadline)
  allow_late_submission BOOLEAN DEFAULT FALSE, -- السماح بالتسليم المتأخر
  late_penalty_percentage INTEGER DEFAULT 0, -- نسبة الخصم للتأخير
  -- Submission Settings
  submission_type TEXT DEFAULT 'file' CHECK (submission_type IN ('file', 'text', 'url', 'mixed')),
  allowed_file_types TEXT[] DEFAULT '{pdf,doc,docx,zip,png,jpg}', -- أنواع الملفات المسموحة
  max_file_size INTEGER DEFAULT 10485760, -- 10MB بالـ bytes
  max_files INTEGER DEFAULT 5, -- عدد الملفات المسموح
  -- Resubmission
  allow_resubmission BOOLEAN DEFAULT TRUE, -- السماح بإعادة التسليم
  max_attempts INTEGER, -- NULL = unlimited
  -- Stats
  submissions_count INTEGER DEFAULT 0,
  graded_count INTEGER DEFAULT 0,
  average_score DECIMAL(5,2) DEFAULT 0,
  -- Status
  is_published BOOLEAN DEFAULT TRUE,
  is_mandatory BOOLEAN DEFAULT TRUE, -- مطلوب لإكمال الكورس
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_assignments_lesson ON assignments(lesson_id);
CREATE INDEX idx_assignments_course ON assignments(course_id);
CREATE INDEX idx_assignments_due_date ON assignments(due_date);
CREATE INDEX idx_assignments_published ON assignments(is_published) WHERE is_published = TRUE;


-- 1.2 ASSIGNMENT_SUBMISSIONS TABLE (تسليمات الطلاب)
CREATE TABLE IF NOT EXISTS assignment_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id UUID NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  enrollment_id UUID REFERENCES enrollments(id) ON DELETE SET NULL,
  -- Submission Content
  submission_text TEXT, -- للتسليم النصي
  submission_url TEXT, -- للروابط
  -- Files (JSON array)
  files JSONB DEFAULT '[]', -- [{file_name, file_url, file_type, file_size, uploaded_at}]
  -- Submission Info
  attempt_number INTEGER DEFAULT 1, -- رقم المحاولة
  is_late BOOLEAN DEFAULT FALSE, -- تسليم متأخر
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  -- Grading
  status TEXT DEFAULT 'submitted' CHECK (status IN ('draft', 'submitted', 'grading', 'graded', 'returned', 'resubmit_requested')),
  score INTEGER, -- الدرجة
  score_after_penalty INTEGER, -- الدرجة بعد خصم التأخير
  passed BOOLEAN,
  -- Feedback
  feedback_text TEXT, -- ملاحظات المدرس
  feedback_files JSONB DEFAULT '[]', -- ملفات الـ feedback
  feedback_audio_url TEXT, -- تعليق صوتي (اختياري)
  -- Grading Info
  graded_by UUID REFERENCES profiles(id), -- المدرس اللي صحح
  graded_at TIMESTAMPTZ,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_submissions_assignment ON assignment_submissions(assignment_id);
CREATE INDEX idx_submissions_user ON assignment_submissions(user_id);
CREATE INDEX idx_submissions_enrollment ON assignment_submissions(enrollment_id);
CREATE INDEX idx_submissions_status ON assignment_submissions(status);
CREATE INDEX idx_submissions_graded ON assignment_submissions(graded_at);
-- Unique constraint: one active submission per user per assignment (latest attempt)
CREATE UNIQUE INDEX idx_submissions_user_assignment_attempt ON assignment_submissions(assignment_id, user_id, attempt_number);


-- 1.3 ASSIGNMENT_RUBRICS TABLE (معايير التقييم - اختياري)
CREATE TABLE IF NOT EXISTS assignment_rubrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id UUID NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
  -- Rubric Item
  title_ar TEXT NOT NULL,
  title_en TEXT,
  description_ar TEXT,
  description_en TEXT,
  max_points INTEGER NOT NULL, -- أقصى درجة لهذا المعيار
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_rubrics_assignment ON assignment_rubrics(assignment_id);

-- 1.4 SUBMISSION_RUBRIC_SCORES TABLE (درجات كل معيار)
CREATE TABLE IF NOT EXISTS submission_rubric_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id UUID NOT NULL REFERENCES assignment_submissions(id) ON DELETE CASCADE,
  rubric_id UUID NOT NULL REFERENCES assignment_rubrics(id) ON DELETE CASCADE,
  score INTEGER NOT NULL,
  feedback TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(submission_id, rubric_id)
);

CREATE INDEX idx_rubric_scores_submission ON submission_rubric_scores(submission_id);


-- ============================================================
-- PART 2: NOTIFICATIONS SYSTEM (الإشعارات)
-- ============================================================

-- 2.1 NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  -- Notification Type
  type TEXT NOT NULL CHECK (type IN (
    'enrollment', -- تم التسجيل في كورس
    'course_update', -- تحديث في الكورس
    'new_lesson', -- درس جديد
    'announcement', -- إعلان من المدرس
    'review_reply', -- رد على تقييمك
    'qa_answer', -- إجابة على سؤالك
    'qa_accepted', -- تم قبول إجابتك
    'assignment_new', -- واجب جديد
    'assignment_graded', -- تم تصحيح الواجب
    'assignment_due', -- موعد تسليم قريب
    'quiz_result', -- نتيجة الاختبار
    'certificate', -- شهادة جديدة
    'payout', -- دفعة مالية (للمدرسين)
    'course_approved', -- تم قبول الكورس (للمدرسين)
    'course_rejected', -- تم رفض الكورس (للمدرسين)
    'new_enrollment', -- طالب جديد (للمدرسين)
    'new_review', -- تقييم جديد (للمدرسين)
    'report_resolved', -- تم حل البلاغ
    'system', -- إشعار من النظام
    'promotion' -- عروض وخصومات
  )),
  -- Content
  title_ar TEXT NOT NULL,
  title_en TEXT,
  body_ar TEXT,
  body_en TEXT,
  image_url TEXT, -- صورة الإشعار (مثلاً صورة الكورس)
  -- Action
  action_type TEXT, -- 'navigate', 'url', 'none'
  action_data JSONB DEFAULT '{}', -- {route: '/course/123', course_id: '...', lesson_id: '...'}
  -- Related Entities
  course_id UUID REFERENCES courses(id) ON DELETE SET NULL,
  lesson_id UUID REFERENCES lessons(id) ON DELETE SET NULL,
  -- Status
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  -- Priority
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ -- الإشعار ينتهي بعد فترة (اختياري)
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX idx_notifications_course ON notifications(course_id);


-- 2.2 DEVICE_TOKENS TABLE (للـ Push Notifications)
CREATE TABLE IF NOT EXISTS device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  -- Token Info
  token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
  device_name TEXT, -- اسم الجهاز
  device_model TEXT, -- موديل الجهاز
  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  last_used_at TIMESTAMPTZ DEFAULT NOW(),
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, token)
);

CREATE INDEX idx_device_tokens_user ON device_tokens(user_id);
CREATE INDEX idx_device_tokens_active ON device_tokens(is_active) WHERE is_active = TRUE;


-- 2.3 NOTIFICATION_PREFERENCES TABLE (تفضيلات الإشعارات)
CREATE TABLE IF NOT EXISTS notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
  -- Push Notifications
  push_enabled BOOLEAN DEFAULT TRUE,
  push_enrollment BOOLEAN DEFAULT TRUE,
  push_announcements BOOLEAN DEFAULT TRUE,
  push_qa BOOLEAN DEFAULT TRUE,
  push_assignments BOOLEAN DEFAULT TRUE,
  push_promotions BOOLEAN DEFAULT TRUE,
  -- Email Notifications
  email_enabled BOOLEAN DEFAULT TRUE,
  email_enrollment BOOLEAN DEFAULT TRUE,
  email_announcements BOOLEAN DEFAULT TRUE,
  email_weekly_digest BOOLEAN DEFAULT TRUE,
  email_promotions BOOLEAN DEFAULT FALSE,
  -- Quiet Hours (ساعات الهدوء)
  quiet_hours_enabled BOOLEAN DEFAULT FALSE,
  quiet_hours_start TIME, -- مثلاً 22:00
  quiet_hours_end TIME, -- مثلاً 08:00
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notification_prefs_user ON notification_preferences(user_id);


-- ============================================================
-- PART 3: HELPER FUNCTIONS
-- ============================================================

-- 3.1 Create Notification Function
CREATE OR REPLACE FUNCTION create_notification(
  p_user_id UUID,
  p_type TEXT,
  p_title_ar TEXT,
  p_title_en TEXT DEFAULT NULL,
  p_body_ar TEXT DEFAULT NULL,
  p_body_en TEXT DEFAULT NULL,
  p_image_url TEXT DEFAULT NULL,
  p_action_data JSONB DEFAULT '{}',
  p_course_id UUID DEFAULT NULL,
  p_lesson_id UUID DEFAULT NULL,
  p_priority TEXT DEFAULT 'normal'
)
RETURNS UUID AS $$
DECLARE
  v_notification_id UUID;
  v_prefs RECORD;
BEGIN
  -- Check user preferences
  SELECT * INTO v_prefs FROM notification_preferences WHERE user_id = p_user_id;
  
  -- If no preferences, create default
  IF v_prefs IS NULL THEN
    INSERT INTO notification_preferences (user_id) VALUES (p_user_id);
  END IF;
  
  -- Create notification
  INSERT INTO notifications (
    user_id, type, title_ar, title_en, body_ar, body_en,
    image_url, action_type, action_data, course_id, lesson_id, priority
  )
  VALUES (
    p_user_id, p_type, p_title_ar, p_title_en, p_body_ar, p_body_en,
    p_image_url, 'navigate', p_action_data, p_course_id, p_lesson_id, p_priority
  )
  RETURNING id INTO v_notification_id;
  
  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 3.2 Mark Notification as Read
CREATE OR REPLACE FUNCTION mark_notification_read(p_notification_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE notifications 
  SET is_read = TRUE, read_at = NOW()
  WHERE id = p_notification_id AND user_id = auth.uid();
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 3.3 Mark All Notifications as Read
CREATE OR REPLACE FUNCTION mark_all_notifications_read()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  UPDATE notifications 
  SET is_read = TRUE, read_at = NOW()
  WHERE user_id = auth.uid() AND is_read = FALSE;
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 3.4 Get Unread Notifications Count
CREATE OR REPLACE FUNCTION get_unread_notifications_count()
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*) FROM notifications 
    WHERE user_id = auth.uid() AND is_read = FALSE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 3.5 Submit Assignment Function
CREATE OR REPLACE FUNCTION submit_assignment(
  p_assignment_id UUID,
  p_submission_text TEXT DEFAULT NULL,
  p_submission_url TEXT DEFAULT NULL,
  p_files JSONB DEFAULT '[]'
)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_assignment RECORD;
  v_enrollment RECORD;
  v_existing_submission RECORD;
  v_attempt_number INTEGER;
  v_is_late BOOLEAN;
  v_submission_id UUID;
BEGIN
  -- Get assignment
  SELECT * INTO v_assignment FROM assignments WHERE id = p_assignment_id;
  
  IF v_assignment IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Assignment not found');
  END IF;
  
  -- Check enrollment
  SELECT * INTO v_enrollment 
  FROM enrollments 
  WHERE user_id = v_user_id AND course_id = v_assignment.course_id AND status = 'active';
  
  IF v_enrollment IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not enrolled in this course');
  END IF;
  
  -- Check if late
  v_is_late := v_assignment.due_date IS NOT NULL AND NOW() > v_assignment.due_date;
  
  IF v_is_late AND NOT v_assignment.allow_late_submission THEN
    RETURN json_build_object('success', false, 'error', 'Late submission not allowed');
  END IF;
  
  -- Get attempt number
  SELECT MAX(attempt_number) INTO v_attempt_number
  FROM assignment_submissions
  WHERE assignment_id = p_assignment_id AND user_id = v_user_id;
  
  v_attempt_number := COALESCE(v_attempt_number, 0) + 1;
  
  -- Check max attempts
  IF v_assignment.max_attempts IS NOT NULL AND v_attempt_number > v_assignment.max_attempts THEN
    RETURN json_build_object('success', false, 'error', 'Maximum attempts reached');
  END IF;
  
  -- Create submission
  INSERT INTO assignment_submissions (
    assignment_id, user_id, enrollment_id,
    submission_text, submission_url, files,
    attempt_number, is_late, status
  )
  VALUES (
    p_assignment_id, v_user_id, v_enrollment.id,
    p_submission_text, p_submission_url, p_files,
    v_attempt_number, v_is_late, 'submitted'
  )
  RETURNING id INTO v_submission_id;
  
  -- Update assignment stats
  UPDATE assignments SET submissions_count = submissions_count + 1 WHERE id = p_assignment_id;
  
  -- Notify instructor
  PERFORM create_notification(
    v_assignment.course_id,
    'assignment_submitted',
    'تسليم واجب جديد',
    'New assignment submission',
    NULL, NULL, NULL,
    json_build_object('assignment_id', p_assignment_id, 'submission_id', v_submission_id)::JSONB
  );
  
  RETURN json_build_object(
    'success', true,
    'submission_id', v_submission_id,
    'attempt_number', v_attempt_number,
    'is_late', v_is_late
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

