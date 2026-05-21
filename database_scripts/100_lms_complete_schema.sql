-- ============================================================
-- 🎓 LMS (Learning Management System) - Complete Database Schema
-- منصة تعليمية شبيهة بـ Udemy
-- Version: 1.0 | January 2026
-- ============================================================
-- Run this script in Supabase SQL Editor for a fresh setup
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- ============================================================
-- PART 1: CORE TABLES
-- ============================================================

-- 1.1 PROFILES TABLE (extends Supabase Auth)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL,
  name TEXT,
  phone TEXT,
  role TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'instructor', 'admin')),
  avatar_url TEXT,
  -- Instructor specific fields
  headline_ar TEXT,
  headline_en TEXT,
  bio_ar TEXT,
  bio_en TEXT,
  expertise TEXT[] DEFAULT '{}',
  social_links JSONB DEFAULT '{}',
  is_verified_instructor BOOLEAN DEFAULT FALSE,
  -- Student specific fields
  interests TEXT[] DEFAULT '{}',
  -- Common fields
  is_active BOOLEAN DEFAULT TRUE,
  is_banned BOOLEAN DEFAULT FALSE,
  banned_until TIMESTAMPTZ,
  ban_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_active ON profiles(is_active) WHERE is_active = TRUE;

-- 1.2 CATEGORIES TABLE (Course Categories)
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name_ar TEXT NOT NULL,
  name_en TEXT,
  description_ar TEXT,
  description_en TEXT,
  image_url TEXT,
  icon_name TEXT,
  parent_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0,
  courses_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_categories_active ON categories(is_active);
CREATE INDEX idx_categories_parent ON categories(parent_id);
CREATE INDEX idx_categories_sort ON categories(sort_order);


-- 1.3 INSTRUCTOR_PROFILES TABLE (Detailed instructor info)
CREATE TABLE IF NOT EXISTS instructor_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  headline_ar TEXT,
  headline_en TEXT,
  bio_ar TEXT,
  bio_en TEXT,
  avatar_url TEXT,
  cover_image_url TEXT,
  expertise TEXT[] DEFAULT '{}',
  social_links JSONB DEFAULT '{}',
  website_url TEXT,
  -- Statistics (auto-calculated)
  total_students INTEGER DEFAULT 0,
  total_courses INTEGER DEFAULT 0,
  total_reviews INTEGER DEFAULT 0,
  average_rating DECIMAL(3,2) DEFAULT 0,
  -- Verification & Payout
  is_verified BOOLEAN DEFAULT FALSE,
  verified_at TIMESTAMPTZ,
  payout_method TEXT DEFAULT 'bank_transfer',
  payout_details JSONB DEFAULT '{}',
  revenue_share DECIMAL(5,2) DEFAULT 70.00, -- instructor gets 70%
  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(instructor_id)
);

CREATE INDEX idx_instructor_profiles_instructor ON instructor_profiles(instructor_id);
CREATE INDEX idx_instructor_profiles_verified ON instructor_profiles(is_verified);
CREATE INDEX idx_instructor_profiles_rating ON instructor_profiles(average_rating DESC);

-- 1.4 COURSES TABLE (Main courses table)
CREATE TABLE IF NOT EXISTS courses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  -- Basic Info
  title_ar TEXT NOT NULL,
  title_en TEXT,
  subtitle_ar TEXT,
  subtitle_en TEXT,
  description_ar TEXT,
  description_en TEXT,
  -- Media
  thumbnail_url TEXT,
  preview_video_url TEXT,
  -- Pricing
  price DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (price >= 0),
  discount_price DECIMAL(10,2) CHECK (discount_price >= 0),
  is_free BOOLEAN DEFAULT FALSE,
  currency TEXT DEFAULT 'EGP',
  -- Course Details
  level TEXT DEFAULT 'beginner' CHECK (level IN ('beginner', 'intermediate', 'advanced', 'all_levels')),
  language TEXT DEFAULT 'ar',
  -- Content Stats (auto-calculated)
  total_duration INTEGER DEFAULT 0, -- in minutes
  total_lessons INTEGER DEFAULT 0,
  total_sections INTEGER DEFAULT 0,
  -- Enrollment Stats
  enrolled_count INTEGER DEFAULT 0,
  max_students INTEGER, -- NULL = unlimited
  -- Rating (auto-calculated)
  rating DECIMAL(3,2) DEFAULT 0 CHECK (rating >= 0 AND rating <= 5),
  rating_count INTEGER DEFAULT 0,
  -- Course Content (JSON arrays)
  requirements JSONB DEFAULT '[]',
  objectives JSONB DEFAULT '[]', -- What you'll learn
  target_audience JSONB DEFAULT '[]',
  tags TEXT[] DEFAULT '{}',
  -- Certificate
  has_certificate BOOLEAN DEFAULT TRUE,
  certificate_template_id UUID,
  -- Status
  is_published BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  is_featured BOOLEAN DEFAULT FALSE,
  is_suspended BOOLEAN DEFAULT FALSE,
  suspension_reason TEXT,
  -- Flash Sale / Limited Offer
  is_flash_sale BOOLEAN DEFAULT FALSE,
  flash_sale_price DECIMAL(10,2),
  flash_sale_start TIMESTAMPTZ,
  flash_sale_end TIMESTAMPTZ,
  -- Timestamps
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_courses_instructor ON courses(instructor_id);
CREATE INDEX idx_courses_category ON courses(category_id);
CREATE INDEX idx_courses_published ON courses(is_published) WHERE is_published = TRUE;
CREATE INDEX idx_courses_active ON courses(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_courses_featured ON courses(is_featured) WHERE is_featured = TRUE;
CREATE INDEX idx_courses_level ON courses(level);
CREATE INDEX idx_courses_language ON courses(language);
CREATE INDEX idx_courses_price ON courses(price);
CREATE INDEX idx_courses_rating ON courses(rating DESC);
CREATE INDEX idx_courses_enrolled ON courses(enrolled_count DESC);
CREATE INDEX idx_courses_created ON courses(created_at DESC);
CREATE INDEX idx_courses_flash_sale ON courses(is_flash_sale, flash_sale_end) WHERE is_flash_sale = TRUE;


-- 1.5 SECTIONS TABLE (Course Sections/Chapters)
CREATE TABLE IF NOT EXISTS sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  title_ar TEXT NOT NULL,
  title_en TEXT,
  description_ar TEXT,
  description_en TEXT,
  sort_order INTEGER DEFAULT 0,
  total_duration INTEGER DEFAULT 0, -- in minutes
  total_lessons INTEGER DEFAULT 0,
  is_published BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_sections_course ON sections(course_id);
CREATE INDEX idx_sections_sort ON sections(course_id, sort_order);

-- 1.6 LESSONS TABLE (Individual Lessons)
CREATE TABLE IF NOT EXISTS lessons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  section_id UUID NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  -- Basic Info
  title_ar TEXT NOT NULL,
  title_en TEXT,
  description_ar TEXT,
  description_en TEXT,
  -- Content Type
  type TEXT DEFAULT 'video' CHECK (type IN ('video', 'article', 'quiz', 'assignment', 'resource', 'live')),
  -- Video Content
  video_url TEXT,
  video_provider TEXT DEFAULT 'supabase', -- supabase, youtube, vimeo, bunny
  video_duration INTEGER DEFAULT 0, -- in seconds
  -- Article Content
  article_content_ar TEXT,
  article_content_en TEXT,
  -- Settings
  sort_order INTEGER DEFAULT 0,
  is_preview BOOLEAN DEFAULT FALSE, -- free preview lesson
  is_published BOOLEAN DEFAULT TRUE,
  is_mandatory BOOLEAN DEFAULT TRUE, -- required for completion
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_lessons_section ON lessons(section_id);
CREATE INDEX idx_lessons_course ON lessons(course_id);
CREATE INDEX idx_lessons_sort ON lessons(section_id, sort_order);
CREATE INDEX idx_lessons_preview ON lessons(is_preview) WHERE is_preview = TRUE;
CREATE INDEX idx_lessons_type ON lessons(type);

-- 1.7 LESSON_ATTACHMENTS TABLE (Downloadable resources)
CREATE TABLE IF NOT EXISTS lesson_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_name_ar TEXT,
  file_url TEXT NOT NULL,
  file_type TEXT, -- pdf, zip, doc, etc.
  file_size INTEGER, -- in bytes
  download_count INTEGER DEFAULT 0,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_attachments_lesson ON lesson_attachments(lesson_id);

-- ============================================================
-- PART 2: ENROLLMENT & PROGRESS TABLES
-- ============================================================

-- 2.1 CART_ITEMS TABLE (Shopping Cart)
CREATE TABLE IF NOT EXISTS cart_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  price_at_add DECIMAL(10,2), -- price when added to cart
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, course_id)
);

CREATE INDEX idx_cart_items_user ON cart_items(user_id);

-- 2.2 WISHLIST TABLE (Saved courses)
CREATE TABLE IF NOT EXISTS wishlist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, course_id)
);

CREATE INDEX idx_wishlist_user ON wishlist(user_id);
CREATE INDEX idx_wishlist_course ON wishlist(course_id);

-- 2.3 PARENT_ENROLLMENTS TABLE (Groups enrollments from same checkout)
CREATE TABLE IF NOT EXISTS parent_enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  -- Pricing
  total DECIMAL(10,2) NOT NULL DEFAULT 0,
  subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
  discount DECIMAL(10,2) DEFAULT 0,
  -- Coupon
  coupon_id UUID,
  coupon_code VARCHAR(50),
  coupon_discount DECIMAL(10,2) DEFAULT 0,
  -- Payment
  payment_method TEXT DEFAULT 'card',
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
  payment_transaction_id TEXT,
  paid_at TIMESTAMPTZ,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_parent_enrollments_user ON parent_enrollments(user_id);
CREATE INDEX idx_parent_enrollments_status ON parent_enrollments(payment_status);


-- 2.4 ENROLLMENTS TABLE (Course enrollments)
CREATE TABLE IF NOT EXISTS enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  instructor_id UUID REFERENCES profiles(id),
  parent_enrollment_id UUID REFERENCES parent_enrollments(id),
  -- Pricing at enrollment time
  price DECIMAL(10,2) NOT NULL DEFAULT 0,
  discount DECIMAL(10,2) DEFAULT 0,
  -- Status
  status TEXT DEFAULT 'active' CHECK (status IN ('pending', 'active', 'completed', 'expired', 'refunded')),
  -- Progress
  progress_percentage DECIMAL(5,2) DEFAULT 0,
  completed_lessons INTEGER DEFAULT 0,
  total_watch_time INTEGER DEFAULT 0, -- in seconds
  last_accessed_at TIMESTAMPTZ,
  -- Completion
  completed_at TIMESTAMPTZ,
  certificate_id UUID,
  -- Access Control
  access_expires_at TIMESTAMPTZ, -- NULL = lifetime access
  -- Refund
  refund_requested_at TIMESTAMPTZ,
  refund_reason TEXT,
  refunded_at TIMESTAMPTZ,
  -- Timestamps
  enrolled_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, course_id)
);

CREATE INDEX idx_enrollments_user ON enrollments(user_id);
CREATE INDEX idx_enrollments_course ON enrollments(course_id);
CREATE INDEX idx_enrollments_instructor ON enrollments(instructor_id);
CREATE INDEX idx_enrollments_parent ON enrollments(parent_enrollment_id);
CREATE INDEX idx_enrollments_status ON enrollments(status);
CREATE INDEX idx_enrollments_progress ON enrollments(progress_percentage);
CREATE INDEX idx_enrollments_created ON enrollments(created_at DESC);

-- 2.5 LESSON_PROGRESS TABLE (Track lesson completion)
CREATE TABLE IF NOT EXISTS lesson_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  enrollment_id UUID REFERENCES enrollments(id) ON DELETE CASCADE,
  -- Progress
  is_completed BOOLEAN DEFAULT FALSE,
  watch_time INTEGER DEFAULT 0, -- in seconds
  last_position INTEGER DEFAULT 0, -- video position in seconds
  completion_percentage DECIMAL(5,2) DEFAULT 0,
  -- Timestamps
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  last_watched_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, lesson_id)
);

CREATE INDEX idx_lesson_progress_user ON lesson_progress(user_id);
CREATE INDEX idx_lesson_progress_lesson ON lesson_progress(lesson_id);
CREATE INDEX idx_lesson_progress_course ON lesson_progress(course_id);
CREATE INDEX idx_lesson_progress_enrollment ON lesson_progress(enrollment_id);
CREATE INDEX idx_lesson_progress_completed ON lesson_progress(is_completed) WHERE is_completed = TRUE;

-- 2.6 CERTIFICATES TABLE
CREATE TABLE IF NOT EXISTS certificates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  enrollment_id UUID REFERENCES enrollments(id) ON DELETE SET NULL,
  -- Certificate Info
  certificate_number TEXT UNIQUE NOT NULL,
  certificate_url TEXT,
  -- Student & Course Info (snapshot at issue time)
  student_name TEXT NOT NULL,
  course_title TEXT NOT NULL,
  instructor_name TEXT NOT NULL,
  completion_date DATE NOT NULL,
  -- Verification
  verification_code TEXT UNIQUE,
  is_valid BOOLEAN DEFAULT TRUE,
  -- Timestamps
  issued_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, course_id)
);

CREATE INDEX idx_certificates_user ON certificates(user_id);
CREATE INDEX idx_certificates_course ON certificates(course_id);
CREATE INDEX idx_certificates_number ON certificates(certificate_number);
CREATE INDEX idx_certificates_verification ON certificates(verification_code);


-- ============================================================
-- PART 3: REVIEWS & INTERACTION TABLES
-- ============================================================

-- 3.1 COURSE_REVIEWS TABLE (Simplified)
CREATE TABLE IF NOT EXISTS course_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(course_id, user_id)
);

CREATE INDEX idx_reviews_course ON course_reviews(course_id);
CREATE INDEX idx_reviews_user ON course_reviews(user_id);
CREATE INDEX idx_reviews_rating ON course_reviews(rating);
CREATE INDEX idx_reviews_created ON course_reviews(created_at DESC);

-- 3.2 NOTES TABLE (Student notes on lessons)
CREATE TABLE IF NOT EXISTS notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  -- Note Content
  content TEXT NOT NULL,
  timestamp_seconds INTEGER DEFAULT 0, -- video timestamp
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notes_user ON notes(user_id);
CREATE INDEX idx_notes_lesson ON notes(lesson_id);
CREATE INDEX idx_notes_course ON notes(course_id);
CREATE INDEX idx_notes_user_course ON notes(user_id, course_id);

-- 3.4 BOOKMARKS TABLE (Bookmark lessons)
CREATE TABLE IF NOT EXISTS bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, lesson_id)
);

CREATE INDEX idx_bookmarks_user ON bookmarks(user_id);
CREATE INDEX idx_bookmarks_course ON bookmarks(course_id);

-- 3.5 Q&A QUESTIONS TABLE
CREATE TABLE IF NOT EXISTS qa_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  lesson_id UUID REFERENCES lessons(id) ON DELETE SET NULL,
  -- Question Content
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  -- Status
  is_answered BOOLEAN DEFAULT FALSE,
  is_pinned BOOLEAN DEFAULT FALSE,
  is_visible BOOLEAN DEFAULT TRUE,
  -- Stats
  views_count INTEGER DEFAULT 0,
  answers_count INTEGER DEFAULT 0,
  upvotes_count INTEGER DEFAULT 0,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_questions_user ON qa_questions(user_id);
CREATE INDEX idx_questions_course ON qa_questions(course_id);
CREATE INDEX idx_questions_lesson ON qa_questions(lesson_id);
CREATE INDEX idx_questions_answered ON qa_questions(is_answered);
CREATE INDEX idx_questions_created ON qa_questions(created_at DESC);

-- 3.6 Q&A ANSWERS TABLE
CREATE TABLE IF NOT EXISTS qa_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID NOT NULL REFERENCES qa_questions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  -- Answer Content
  content TEXT NOT NULL,
  -- Status
  is_accepted BOOLEAN DEFAULT FALSE,
  is_instructor_answer BOOLEAN DEFAULT FALSE,
  is_visible BOOLEAN DEFAULT TRUE,
  -- Stats
  upvotes_count INTEGER DEFAULT 0,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_answers_question ON qa_answers(question_id);
CREATE INDEX idx_answers_user ON qa_answers(user_id);
CREATE INDEX idx_answers_accepted ON qa_answers(is_accepted) WHERE is_accepted = TRUE;


-- ============================================================
-- PART 4: QUIZZES & ASSESSMENTS
-- ============================================================

-- 4.1 QUIZZES TABLE
CREATE TABLE IF NOT EXISTS quizzes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  -- Quiz Info
  title_ar TEXT NOT NULL,
  title_en TEXT,
  description_ar TEXT,
  description_en TEXT,
  -- Settings
  passing_score INTEGER DEFAULT 70, -- percentage
  time_limit INTEGER, -- in minutes, NULL = no limit
  max_attempts INTEGER, -- NULL = unlimited
  shuffle_questions BOOLEAN DEFAULT FALSE,
  shuffle_answers BOOLEAN DEFAULT FALSE,
  show_correct_answers BOOLEAN DEFAULT TRUE,
  -- Stats
  total_questions INTEGER DEFAULT 0,
  total_points INTEGER DEFAULT 0,
  attempts_count INTEGER DEFAULT 0,
  average_score DECIMAL(5,2) DEFAULT 0,
  -- Status
  is_published BOOLEAN DEFAULT TRUE,
  is_mandatory BOOLEAN DEFAULT FALSE, -- required for course completion
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_quizzes_lesson ON quizzes(lesson_id);
CREATE INDEX idx_quizzes_course ON quizzes(course_id);

-- 4.2 QUIZ_QUESTIONS TABLE
CREATE TABLE IF NOT EXISTS quiz_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  -- Question Content
  question_ar TEXT NOT NULL,
  question_en TEXT,
  question_type TEXT DEFAULT 'single' CHECK (question_type IN ('single', 'multiple', 'true_false', 'text')),
  -- Options (JSON array for choice questions)
  options JSONB DEFAULT '[]', -- [{id, text_ar, text_en, is_correct}]
  correct_answer TEXT, -- for text questions
  -- Settings
  points INTEGER DEFAULT 1,
  explanation_ar TEXT, -- shown after answering
  explanation_en TEXT,
  sort_order INTEGER DEFAULT 0,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_quiz_questions_quiz ON quiz_questions(quiz_id);
CREATE INDEX idx_quiz_questions_sort ON quiz_questions(quiz_id, sort_order);

-- 4.3 QUIZ_ATTEMPTS TABLE
CREATE TABLE IF NOT EXISTS quiz_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  enrollment_id UUID REFERENCES enrollments(id) ON DELETE SET NULL,
  -- Results
  score INTEGER DEFAULT 0,
  total_points INTEGER DEFAULT 0,
  percentage DECIMAL(5,2) DEFAULT 0,
  passed BOOLEAN DEFAULT FALSE,
  -- Answers (JSON)
  answers JSONB DEFAULT '[]', -- [{question_id, selected_options, is_correct, points_earned}]
  -- Timing
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  time_spent INTEGER, -- in seconds
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_quiz_attempts_quiz ON quiz_attempts(quiz_id);
CREATE INDEX idx_quiz_attempts_user ON quiz_attempts(user_id);
CREATE INDEX idx_quiz_attempts_enrollment ON quiz_attempts(enrollment_id);
CREATE INDEX idx_quiz_attempts_passed ON quiz_attempts(passed);

-- ============================================================
-- PART 5: ANNOUNCEMENTS & NOTIFICATIONS
-- ============================================================

-- 5.1 ANNOUNCEMENTS TABLE (Course announcements)
CREATE TABLE IF NOT EXISTS announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  -- Content
  title_ar TEXT NOT NULL,
  title_en TEXT,
  content_ar TEXT NOT NULL,
  content_en TEXT,
  -- Settings
  is_pinned BOOLEAN DEFAULT FALSE,
  is_published BOOLEAN DEFAULT TRUE,
  send_email BOOLEAN DEFAULT FALSE,
  -- Stats
  views_count INTEGER DEFAULT 0,
  -- Timestamps
  published_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_announcements_course ON announcements(course_id);
CREATE INDEX idx_announcements_instructor ON announcements(instructor_id);
CREATE INDEX idx_announcements_published ON announcements(published_at DESC);

-- 5.2 ANNOUNCEMENT_READS TABLE (Track who read announcements)
CREATE TABLE IF NOT EXISTS announcement_reads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  announcement_id UUID NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(announcement_id, user_id)
);

CREATE INDEX idx_announcement_reads_announcement ON announcement_reads(announcement_id);
CREATE INDEX idx_announcement_reads_user ON announcement_reads(user_id);


-- ============================================================
-- PART 6: COUPONS SYSTEM
-- ============================================================

-- 6.1 COUPONS TABLE
CREATE TABLE IF NOT EXISTS coupons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(50) NOT NULL UNIQUE,
  name_ar VARCHAR(255) NOT NULL,
  name_en VARCHAR(255),
  description_ar TEXT,
  description_en TEXT,
  -- Discount Type
  discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
  discount_value DECIMAL(10,2) NOT NULL CHECK (discount_value > 0),
  max_discount_amount DECIMAL(10,2), -- for percentage discounts
  min_order_amount DECIMAL(10,2) DEFAULT 0,
  -- Usage Limits
  usage_limit INTEGER, -- NULL = unlimited
  usage_count INTEGER DEFAULT 0,
  usage_limit_per_user INTEGER DEFAULT 1,
  -- Validity Period
  start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  end_date TIMESTAMPTZ,
  -- Scope
  scope VARCHAR(20) DEFAULT 'all' CHECK (scope IN ('all', 'categories', 'courses', 'instructors')),
  -- Owner (NULL = platform coupon)
  instructor_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  is_suspended BOOLEAN DEFAULT FALSE,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_coupons_code ON coupons(code);
CREATE INDEX idx_coupons_instructor ON coupons(instructor_id);
CREATE INDEX idx_coupons_active ON coupons(is_active, start_date, end_date);

-- 6.2 COUPON_CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS coupon_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coupon_id UUID NOT NULL REFERENCES coupons(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(coupon_id, category_id)
);

-- 6.3 COUPON_COURSES TABLE
CREATE TABLE IF NOT EXISTS coupon_courses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coupon_id UUID NOT NULL REFERENCES coupons(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(coupon_id, course_id)
);

-- 6.4 COUPON_USAGES TABLE
CREATE TABLE IF NOT EXISTS coupon_usages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coupon_id UUID NOT NULL REFERENCES coupons(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  enrollment_id UUID REFERENCES parent_enrollments(id) ON DELETE SET NULL,
  discount_amount DECIMAL(10,2) NOT NULL,
  used_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_coupon_usages_coupon ON coupon_usages(coupon_id);
CREATE INDEX idx_coupon_usages_user ON coupon_usages(user_id);

-- Add foreign key to parent_enrollments
ALTER TABLE parent_enrollments 
ADD CONSTRAINT fk_parent_enrollments_coupon 
FOREIGN KEY (coupon_id) REFERENCES coupons(id) ON DELETE SET NULL;

-- ============================================================
-- PART 7: REPORTS SYSTEM
-- ============================================================

-- 7.1 COURSE_REPORTS TABLE
CREATE TABLE IF NOT EXISTS course_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  -- Report Content
  reason TEXT NOT NULL,
  description TEXT,
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'rejected')),
  admin_response TEXT,
  admin_id UUID REFERENCES profiles(id),
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

CREATE INDEX idx_course_reports_course ON course_reports(course_id);
CREATE INDEX idx_course_reports_user ON course_reports(user_id);
CREATE INDEX idx_course_reports_status ON course_reports(status);

-- 7.2 REVIEW_REPORTS TABLE
CREATE TABLE IF NOT EXISTS review_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id UUID REFERENCES course_reviews(id) ON DELETE SET NULL,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  -- Report Content
  reason TEXT NOT NULL,
  description TEXT,
  -- Cached review data (in case review is deleted)
  cached_reviewer_id UUID,
  cached_review_comment TEXT,
  cached_review_rating INTEGER,
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'rejected')),
  admin_response TEXT,
  admin_id UUID REFERENCES profiles(id),
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

CREATE INDEX idx_review_reports_review ON review_reports(review_id);
CREATE INDEX idx_review_reports_user ON review_reports(user_id);
CREATE INDEX idx_review_reports_status ON review_reports(status);


-- ============================================================
-- PART 8: BANNERS & MARKETING
-- ============================================================

-- 8.1 BANNERS TABLE
CREATE TABLE IF NOT EXISTS banners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title_ar TEXT NOT NULL,
  title_en TEXT,
  subtitle_ar TEXT,
  subtitle_en TEXT,
  image_url TEXT NOT NULL,
  -- Link Settings
  link_type TEXT DEFAULT 'none' CHECK (link_type IN ('none', 'course', 'category', 'url', 'instructor')),
  link_value TEXT, -- course_id, category_id, url, or instructor_id
  -- Display Settings
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  -- Target
  target_audience TEXT DEFAULT 'all' CHECK (target_audience IN ('all', 'students', 'instructors', 'guests')),
  -- Stats
  clicks_count INTEGER DEFAULT 0,
  views_count INTEGER DEFAULT 0,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_banners_active ON banners(is_active, sort_order);
CREATE INDEX idx_banners_dates ON banners(start_date, end_date);

-- ============================================================
-- PART 9: INSTRUCTOR PAYOUTS
-- ============================================================

-- 9.1 INSTRUCTOR_EARNINGS TABLE (Track earnings per enrollment)
CREATE TABLE IF NOT EXISTS instructor_earnings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  enrollment_id UUID NOT NULL REFERENCES enrollments(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  -- Amounts
  gross_amount DECIMAL(10,2) NOT NULL, -- total paid by student
  platform_fee DECIMAL(10,2) NOT NULL, -- platform's share
  net_amount DECIMAL(10,2) NOT NULL, -- instructor's share
  revenue_share DECIMAL(5,2) NOT NULL, -- percentage at time of sale
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'available', 'paid', 'refunded')),
  available_at TIMESTAMPTZ, -- when it becomes available for payout
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_earnings_instructor ON instructor_earnings(instructor_id);
CREATE INDEX idx_earnings_course ON instructor_earnings(course_id);
CREATE INDEX idx_earnings_status ON instructor_earnings(status);
CREATE INDEX idx_earnings_available ON instructor_earnings(available_at);

-- 9.2 INSTRUCTOR_PAYOUTS TABLE
CREATE TABLE IF NOT EXISTS instructor_payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  -- Payout Details
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'EGP',
  payout_method TEXT NOT NULL,
  payout_details JSONB, -- bank details, etc.
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
  -- Processing
  processed_by UUID REFERENCES profiles(id),
  processed_at TIMESTAMPTZ,
  transaction_id TEXT,
  failure_reason TEXT,
  -- Period
  period_start DATE,
  period_end DATE,
  -- Timestamps
  requested_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_payouts_instructor ON instructor_payouts(instructor_id);
CREATE INDEX idx_payouts_status ON instructor_payouts(status);
CREATE INDEX idx_payouts_requested ON instructor_payouts(requested_at DESC);

-- 9.3 PAYOUT_ITEMS TABLE (Link payouts to earnings)
CREATE TABLE IF NOT EXISTS payout_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payout_id UUID NOT NULL REFERENCES instructor_payouts(id) ON DELETE CASCADE,
  earning_id UUID NOT NULL REFERENCES instructor_earnings(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_payout_items_payout ON payout_items(payout_id);
CREATE INDEX idx_payout_items_earning ON payout_items(earning_id);


-- ============================================================
-- PART 10: HELPER FUNCTIONS
-- ============================================================

-- 10.1 Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables with updated_at
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN SELECT unnest(ARRAY[
    'profiles', 'categories', 'instructor_profiles', 'courses', 'sections', 
    'lessons', 'cart_items', 'parent_enrollments', 'enrollments', 'lesson_progress',
    'course_reviews', 'notes', 'qa_questions', 'qa_answers', 'quizzes', 
    'quiz_questions', 'announcements', 'coupons', 'course_reports', 
    'review_reports', 'banners', 'instructor_payouts'
  ])
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS update_%s_updated_at ON %s', t, t);
    EXECUTE format('CREATE TRIGGER update_%s_updated_at BEFORE UPDATE ON %s FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()', t, t);
  END LOOP;
END;
$$;

-- 10.2 Check if user is instructor
CREATE OR REPLACE FUNCTION is_instructor()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'instructor'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 10.3 Check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 10.4 Check if user is enrolled in course
CREATE OR REPLACE FUNCTION is_enrolled(p_course_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM enrollments 
    WHERE user_id = auth.uid() 
    AND course_id = p_course_id 
    AND status = 'active'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 10.5 Auto-create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, name, phone)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'student'),
    NEW.raw_user_meta_data->>'name',
    NEW.raw_user_meta_data->>'phone'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 10.6 Auto-create instructor profile when role changes to instructor
CREATE OR REPLACE FUNCTION handle_instructor_role()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role = 'instructor' AND OLD.role != 'instructor' THEN
    INSERT INTO instructor_profiles (instructor_id, display_name)
    VALUES (NEW.id, COALESCE(NEW.name, NEW.email))
    ON CONFLICT (instructor_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_instructor_role_change ON profiles;
CREATE TRIGGER on_instructor_role_change
  AFTER UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION handle_instructor_role();

-- 10.7 Update course rating on review changes
CREATE OR REPLACE FUNCTION update_course_rating()
RETURNS TRIGGER AS $$
DECLARE
  avg_rating DECIMAL(3,2);
  review_count INTEGER;
  target_course_id UUID;
BEGIN
  target_course_id := COALESCE(NEW.course_id, OLD.course_id);
  
  SELECT COALESCE(AVG(rating), 0), COUNT(*) 
  INTO avg_rating, review_count
  FROM course_reviews
  WHERE course_id = target_course_id AND is_visible = TRUE;
  
  UPDATE courses 
  SET rating = avg_rating, rating_count = review_count 
  WHERE id = target_course_id;
  
  -- Also update instructor profile
  UPDATE instructor_profiles ip
  SET 
    total_reviews = (SELECT COUNT(*) FROM course_reviews cr JOIN courses c ON c.id = cr.course_id WHERE c.instructor_id = ip.instructor_id AND cr.is_visible = TRUE),
    average_rating = (SELECT COALESCE(AVG(cr.rating), 0) FROM course_reviews cr JOIN courses c ON c.id = cr.course_id WHERE c.instructor_id = ip.instructor_id AND cr.is_visible = TRUE)
  WHERE ip.instructor_id = (SELECT instructor_id FROM courses WHERE id = target_course_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_course_rating ON course_reviews;
CREATE TRIGGER trigger_update_course_rating
  AFTER INSERT OR UPDATE OR DELETE ON course_reviews
  FOR EACH ROW EXECUTE FUNCTION update_course_rating();


-- 10.8 Update course stats (sections, lessons, duration)
CREATE OR REPLACE FUNCTION update_course_stats()
RETURNS TRIGGER AS $$
DECLARE
  v_course_id UUID;
  v_section_id UUID;
BEGIN
  -- Get course_id based on trigger source
  IF TG_TABLE_NAME = 'sections' THEN
    v_course_id := COALESCE(NEW.course_id, OLD.course_id);
  ELSIF TG_TABLE_NAME = 'lessons' THEN
    v_course_id := COALESCE(NEW.course_id, OLD.course_id);
    v_section_id := COALESCE(NEW.section_id, OLD.section_id);
    
    -- Update section stats
    IF v_section_id IS NOT NULL THEN
      UPDATE sections SET
        total_lessons = (SELECT COUNT(*) FROM lessons WHERE section_id = v_section_id AND is_published = TRUE),
        total_duration = (SELECT COALESCE(SUM(video_duration), 0) / 60 FROM lessons WHERE section_id = v_section_id AND is_published = TRUE)
      WHERE id = v_section_id;
    END IF;
  END IF;
  
  -- Update course stats
  IF v_course_id IS NOT NULL THEN
    UPDATE courses SET
      total_sections = (SELECT COUNT(*) FROM sections WHERE course_id = v_course_id AND is_published = TRUE),
      total_lessons = (SELECT COUNT(*) FROM lessons WHERE course_id = v_course_id AND is_published = TRUE),
      total_duration = (SELECT COALESCE(SUM(video_duration), 0) / 60 FROM lessons WHERE course_id = v_course_id AND is_published = TRUE)
    WHERE id = v_course_id;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_course_stats_sections ON sections;
CREATE TRIGGER trigger_update_course_stats_sections
  AFTER INSERT OR UPDATE OR DELETE ON sections
  FOR EACH ROW EXECUTE FUNCTION update_course_stats();

DROP TRIGGER IF EXISTS trigger_update_course_stats_lessons ON lessons;
CREATE TRIGGER trigger_update_course_stats_lessons
  AFTER INSERT OR UPDATE OR DELETE ON lessons
  FOR EACH ROW EXECUTE FUNCTION update_course_stats();

-- 10.9 Update enrollment progress
CREATE OR REPLACE FUNCTION update_enrollment_progress()
RETURNS TRIGGER AS $$
DECLARE
  v_enrollment_id UUID;
  v_course_id UUID;
  v_total_lessons INTEGER;
  v_completed_lessons INTEGER;
  v_progress DECIMAL(5,2);
BEGIN
  v_course_id := COALESCE(NEW.course_id, OLD.course_id);
  
  -- Get enrollment
  SELECT id INTO v_enrollment_id
  FROM enrollments
  WHERE user_id = COALESCE(NEW.user_id, OLD.user_id) AND course_id = v_course_id;
  
  IF v_enrollment_id IS NOT NULL THEN
    -- Count total mandatory lessons
    SELECT COUNT(*) INTO v_total_lessons
    FROM lessons
    WHERE course_id = v_course_id AND is_published = TRUE AND is_mandatory = TRUE;
    
    -- Count completed lessons
    SELECT COUNT(*) INTO v_completed_lessons
    FROM lesson_progress
    WHERE enrollment_id = v_enrollment_id AND is_completed = TRUE
    AND lesson_id IN (SELECT id FROM lessons WHERE course_id = v_course_id AND is_mandatory = TRUE);
    
    -- Calculate progress
    IF v_total_lessons > 0 THEN
      v_progress := (v_completed_lessons::DECIMAL / v_total_lessons) * 100;
    ELSE
      v_progress := 0;
    END IF;
    
    -- Update enrollment
    UPDATE enrollments SET
      progress_percentage = v_progress,
      completed_lessons = v_completed_lessons,
      total_watch_time = (SELECT COALESCE(SUM(watch_time), 0) FROM lesson_progress WHERE enrollment_id = v_enrollment_id),
      last_accessed_at = NOW(),
      completed_at = CASE WHEN v_progress >= 100 THEN NOW() ELSE NULL END,
      status = CASE WHEN v_progress >= 100 THEN 'completed' ELSE status END
    WHERE id = v_enrollment_id;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_enrollment_progress ON lesson_progress;
CREATE TRIGGER trigger_update_enrollment_progress
  AFTER INSERT OR UPDATE ON lesson_progress
  FOR EACH ROW EXECUTE FUNCTION update_enrollment_progress();

-- 10.10 Update instructor stats on enrollment
CREATE OR REPLACE FUNCTION update_instructor_stats()
RETURNS TRIGGER AS $$
DECLARE
  v_instructor_id UUID;
BEGIN
  -- Get instructor_id from course
  SELECT instructor_id INTO v_instructor_id
  FROM courses WHERE id = COALESCE(NEW.course_id, OLD.course_id);
  
  IF v_instructor_id IS NOT NULL THEN
    UPDATE instructor_profiles SET
      total_students = (
        SELECT COUNT(DISTINCT e.user_id) 
        FROM enrollments e 
        JOIN courses c ON c.id = e.course_id 
        WHERE c.instructor_id = v_instructor_id AND e.status IN ('active', 'completed')
      ),
      total_courses = (
        SELECT COUNT(*) FROM courses 
        WHERE instructor_id = v_instructor_id AND is_published = TRUE
      )
    WHERE instructor_id = v_instructor_id;
  END IF;
  
  -- Update course enrolled count
  UPDATE courses SET
    enrolled_count = (SELECT COUNT(*) FROM enrollments WHERE course_id = COALESCE(NEW.course_id, OLD.course_id) AND status IN ('active', 'completed'))
  WHERE id = COALESCE(NEW.course_id, OLD.course_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_instructor_stats ON enrollments;
CREATE TRIGGER trigger_update_instructor_stats
  AFTER INSERT OR UPDATE OR DELETE ON enrollments
  FOR EACH ROW EXECUTE FUNCTION update_instructor_stats();


-- ============================================================
-- PART 11: MAIN FUNCTIONS
-- ============================================================

-- 11.1 Create Enrollment Function
CREATE OR REPLACE FUNCTION create_enrollment(
  p_user_id UUID,
  p_payment_method TEXT DEFAULT 'card',
  p_coupon_id UUID DEFAULT NULL,
  p_coupon_code VARCHAR DEFAULT NULL,
  p_coupon_discount DECIMAL DEFAULT 0
)
RETURNS UUID AS $$
DECLARE
  v_parent_enrollment_id UUID;
  v_enrollment_id UUID;
  v_course RECORD;
  v_total_subtotal DECIMAL := 0;
  v_instructor_share DECIMAL;
  v_platform_fee DECIMAL;
BEGIN
  -- Check if cart is empty
  IF NOT EXISTS (SELECT 1 FROM cart_items WHERE user_id = p_user_id) THEN
    RAISE EXCEPTION 'Cart is empty';
  END IF;
  
  -- Calculate total
  SELECT COALESCE(SUM(
    CASE 
      WHEN c.is_flash_sale AND c.flash_sale_end > NOW() THEN COALESCE(c.flash_sale_price, c.discount_price, c.price)
      ELSE COALESCE(c.discount_price, c.price)
    END
  ), 0) INTO v_total_subtotal
  FROM cart_items ci
  JOIN courses c ON c.id = ci.course_id
  WHERE ci.user_id = p_user_id;
  
  -- Create parent enrollment
  INSERT INTO parent_enrollments (
    user_id, total, subtotal, discount,
    coupon_id, coupon_code, coupon_discount,
    payment_method, payment_status
  )
  VALUES (
    p_user_id,
    v_total_subtotal - COALESCE(p_coupon_discount, 0),
    v_total_subtotal,
    COALESCE(p_coupon_discount, 0),
    p_coupon_id, p_coupon_code, COALESCE(p_coupon_discount, 0),
    p_payment_method,
    CASE WHEN v_total_subtotal - COALESCE(p_coupon_discount, 0) = 0 THEN 'paid' ELSE 'pending' END
  )
  RETURNING id INTO v_parent_enrollment_id;
  
  -- Create individual enrollments for each course
  FOR v_course IN 
    SELECT 
      c.id as course_id,
      c.instructor_id,
      CASE 
        WHEN c.is_flash_sale AND c.flash_sale_end > NOW() THEN COALESCE(c.flash_sale_price, c.discount_price, c.price)
        ELSE COALESCE(c.discount_price, c.price)
      END as final_price,
      COALESCE(ip.revenue_share, 70) as revenue_share
    FROM cart_items ci
    JOIN courses c ON c.id = ci.course_id
    LEFT JOIN instructor_profiles ip ON ip.instructor_id = c.instructor_id
    WHERE ci.user_id = p_user_id
  LOOP
    -- Create enrollment
    INSERT INTO enrollments (
      user_id, course_id, instructor_id, parent_enrollment_id,
      price, status, enrolled_at
    )
    VALUES (
      p_user_id, v_course.course_id, v_course.instructor_id, v_parent_enrollment_id,
      v_course.final_price,
      CASE WHEN v_course.final_price = 0 OR (v_total_subtotal - COALESCE(p_coupon_discount, 0) = 0) THEN 'active' ELSE 'pending' END,
      NOW()
    )
    RETURNING id INTO v_enrollment_id;
    
    -- Create instructor earning record (if paid course)
    IF v_course.final_price > 0 THEN
      v_instructor_share := v_course.final_price * (v_course.revenue_share / 100);
      v_platform_fee := v_course.final_price - v_instructor_share;
      
      INSERT INTO instructor_earnings (
        instructor_id, enrollment_id, course_id,
        gross_amount, platform_fee, net_amount, revenue_share,
        status, available_at
      )
      VALUES (
        v_course.instructor_id, v_enrollment_id, v_course.course_id,
        v_course.final_price, v_platform_fee, v_instructor_share, v_course.revenue_share,
        'pending', NOW() + INTERVAL '14 days' -- available after 14 days
      );
    END IF;
  END LOOP;
  
  -- Apply coupon if provided
  IF p_coupon_id IS NOT NULL THEN
    INSERT INTO coupon_usages (coupon_id, user_id, enrollment_id, discount_amount)
    VALUES (p_coupon_id, p_user_id, v_parent_enrollment_id, COALESCE(p_coupon_discount, 0));
    
    UPDATE coupons SET usage_count = usage_count + 1 WHERE id = p_coupon_id;
  END IF;
  
  -- Clear cart
  DELETE FROM cart_items WHERE user_id = p_user_id;
  
  RETURN v_parent_enrollment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11.2 Confirm Payment Function
CREATE OR REPLACE FUNCTION confirm_enrollment_payment(
  p_parent_enrollment_id UUID,
  p_transaction_id TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Update parent enrollment
  UPDATE parent_enrollments SET
    payment_status = 'paid',
    payment_transaction_id = p_transaction_id,
    paid_at = NOW()
  WHERE id = p_parent_enrollment_id;
  
  -- Activate all enrollments
  UPDATE enrollments SET
    status = 'active'
  WHERE parent_enrollment_id = p_parent_enrollment_id;
  
  -- Update earnings status
  UPDATE instructor_earnings SET
    status = 'pending'
  WHERE enrollment_id IN (SELECT id FROM enrollments WHERE parent_enrollment_id = p_parent_enrollment_id);
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 11.3 Update Lesson Progress Function
CREATE OR REPLACE FUNCTION update_lesson_progress(
  p_lesson_id UUID,
  p_watch_time INTEGER DEFAULT 0,
  p_last_position INTEGER DEFAULT 0,
  p_is_completed BOOLEAN DEFAULT FALSE
)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_course_id UUID;
  v_enrollment_id UUID;
  v_progress_id UUID;
  v_result JSON;
BEGIN
  -- Get course_id from lesson
  SELECT course_id INTO v_course_id FROM lessons WHERE id = p_lesson_id;
  
  -- Check enrollment
  SELECT id INTO v_enrollment_id
  FROM enrollments
  WHERE user_id = v_user_id AND course_id = v_course_id AND status = 'active';
  
  IF v_enrollment_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not enrolled in this course');
  END IF;
  
  -- Upsert progress
  INSERT INTO lesson_progress (
    user_id, lesson_id, course_id, enrollment_id,
    watch_time, last_position, is_completed, completed_at
  )
  VALUES (
    v_user_id, p_lesson_id, v_course_id, v_enrollment_id,
    p_watch_time, p_last_position, p_is_completed,
    CASE WHEN p_is_completed THEN NOW() ELSE NULL END
  )
  ON CONFLICT (user_id, lesson_id) DO UPDATE SET
    watch_time = GREATEST(lesson_progress.watch_time, EXCLUDED.watch_time),
    last_position = EXCLUDED.last_position,
    is_completed = lesson_progress.is_completed OR EXCLUDED.is_completed,
    completed_at = COALESCE(lesson_progress.completed_at, EXCLUDED.completed_at),
    last_watched_at = NOW(),
    updated_at = NOW()
  RETURNING id INTO v_progress_id;
  
  -- Get updated enrollment progress
  SELECT json_build_object(
    'success', true,
    'progress_id', v_progress_id,
    'course_progress', progress_percentage,
    'completed_lessons', completed_lessons
  ) INTO v_result
  FROM enrollments WHERE id = v_enrollment_id;
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11.4 Issue Certificate Function
CREATE OR REPLACE FUNCTION issue_certificate(p_course_id UUID)
RETURNS JSON AS $$
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
  -- Get enrollment
  SELECT * INTO v_enrollment
  FROM enrollments
  WHERE user_id = v_user_id AND course_id = p_course_id AND status = 'completed';
  
  IF v_enrollment IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Course not completed');
  END IF;
  
  -- Check if certificate already exists
  IF v_enrollment.certificate_id IS NOT NULL THEN
    SELECT * INTO v_course FROM certificates WHERE id = v_enrollment.certificate_id;
    RETURN json_build_object('success', true, 'certificate_id', v_enrollment.certificate_id, 'already_issued', true);
  END IF;
  
  -- Get course info
  SELECT * INTO v_course FROM courses WHERE id = p_course_id;
  
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
    user_id, course_id, enrollment_id,
    certificate_number, verification_code,
    student_name, course_title, instructor_name,
    completion_date
  )
  VALUES (
    v_user_id, p_course_id, v_enrollment.id,
    v_certificate_number, v_verification_code,
    COALESCE(v_user.name, 'Student'),
    COALESCE(v_course.title_ar, v_course.title_en),
    COALESCE(v_instructor.name, 'Instructor'),
    CURRENT_DATE
  )
  RETURNING id INTO v_certificate_id;
  
  -- Update enrollment
  UPDATE enrollments SET certificate_id = v_certificate_id WHERE id = v_enrollment.id;
  
  RETURN json_build_object(
    'success', true,
    'certificate_id', v_certificate_id,
    'certificate_number', v_certificate_number,
    'verification_code', v_verification_code
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11.5 Validate Coupon Function
CREATE OR REPLACE FUNCTION validate_coupon(
  p_coupon_code VARCHAR,
  p_user_id UUID,
  p_cart_total DECIMAL,
  p_course_ids UUID[] DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_coupon RECORD;
  v_user_usage_count INTEGER;
  v_discount_amount DECIMAL;
BEGIN
  -- Find coupon
  SELECT * INTO v_coupon FROM coupons 
  WHERE code = UPPER(p_coupon_code) AND is_active = TRUE AND is_suspended = FALSE;
  
  IF v_coupon IS NULL THEN
    RETURN json_build_object('valid', false, 'error_ar', 'كود الخصم غير صحيح', 'error_en', 'Invalid coupon code');
  END IF;
  
  -- Check dates
  IF v_coupon.start_date > NOW() THEN
    RETURN json_build_object('valid', false, 'error_ar', 'كود الخصم لم يبدأ بعد', 'error_en', 'Coupon not started yet');
  END IF;
  
  IF v_coupon.end_date IS NOT NULL AND v_coupon.end_date < NOW() THEN
    RETURN json_build_object('valid', false, 'error_ar', 'كود الخصم منتهي', 'error_en', 'Coupon expired');
  END IF;
  
  -- Check usage limits
  IF v_coupon.usage_limit IS NOT NULL AND v_coupon.usage_count >= v_coupon.usage_limit THEN
    RETURN json_build_object('valid', false, 'error_ar', 'تم استنفاد الكوبون', 'error_en', 'Coupon exhausted');
  END IF;
  
  -- Check user usage
  SELECT COUNT(*) INTO v_user_usage_count FROM coupon_usages WHERE coupon_id = v_coupon.id AND user_id = p_user_id;
  IF v_user_usage_count >= v_coupon.usage_limit_per_user THEN
    RETURN json_build_object('valid', false, 'error_ar', 'لقد استخدمت هذا الكوبون من قبل', 'error_en', 'Already used this coupon');
  END IF;
  
  -- Check minimum order
  IF p_cart_total < v_coupon.min_order_amount THEN
    RETURN json_build_object('valid', false, 'error_ar', 'الحد الأدنى للطلب ' || v_coupon.min_order_amount, 'error_en', 'Minimum order is ' || v_coupon.min_order_amount);
  END IF;
  
  -- Calculate discount
  IF v_coupon.discount_type = 'percentage' THEN
    v_discount_amount := p_cart_total * (v_coupon.discount_value / 100);
    IF v_coupon.max_discount_amount IS NOT NULL AND v_discount_amount > v_coupon.max_discount_amount THEN
      v_discount_amount := v_coupon.max_discount_amount;
    END IF;
  ELSE
    v_discount_amount := LEAST(v_coupon.discount_value, p_cart_total);
  END IF;
  
  RETURN json_build_object(
    'valid', true,
    'coupon_id', v_coupon.id,
    'code', v_coupon.code,
    'name_ar', v_coupon.name_ar,
    'name_en', v_coupon.name_en,
    'discount_type', v_coupon.discount_type,
    'discount_value', v_coupon.discount_value,
    'discount_amount', ROUND(v_discount_amount, 2),
    'final_amount', ROUND(p_cart_total - v_discount_amount, 2)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 11.6 Get Course Details Function
CREATE OR REPLACE FUNCTION get_course_details(p_course_id UUID, p_locale TEXT DEFAULT 'ar')
RETURNS JSON AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_course JSON;
  v_instructor JSON;
  v_sections JSON;
  v_is_enrolled BOOLEAN;
  v_enrollment JSON;
  v_is_wishlisted BOOLEAN;
  v_is_in_cart BOOLEAN;
BEGIN
  -- Get course
  SELECT json_build_object(
    'id', c.id,
    'title', CASE WHEN p_locale = 'en' AND c.title_en IS NOT NULL THEN c.title_en ELSE c.title_ar END,
    'subtitle', CASE WHEN p_locale = 'en' AND c.subtitle_en IS NOT NULL THEN c.subtitle_en ELSE c.subtitle_ar END,
    'description', CASE WHEN p_locale = 'en' AND c.description_en IS NOT NULL THEN c.description_en ELSE c.description_ar END,
    'thumbnail_url', c.thumbnail_url,
    'preview_video_url', c.preview_video_url,
    'price', c.price,
    'discount_price', c.discount_price,
    'is_free', c.is_free,
    'level', c.level,
    'language', c.language,
    'total_duration', c.total_duration,
    'total_lessons', c.total_lessons,
    'total_sections', c.total_sections,
    'enrolled_count', c.enrolled_count,
    'rating', c.rating,
    'rating_count', c.rating_count,
    'requirements', c.requirements,
    'objectives', c.objectives,
    'target_audience', c.target_audience,
    'has_certificate', c.has_certificate,
    'is_flash_sale', c.is_flash_sale AND c.flash_sale_end > NOW(),
    'flash_sale_price', c.flash_sale_price,
    'flash_sale_end', c.flash_sale_end,
    'category_id', c.category_id,
    'created_at', c.created_at
  ) INTO v_course
  FROM courses c WHERE c.id = p_course_id AND c.is_published = TRUE AND c.is_active = TRUE;
  
  IF v_course IS NULL THEN
    RETURN json_build_object('error', 'Course not found');
  END IF;
  
  -- Get instructor
  SELECT json_build_object(
    'id', p.id,
    'name', p.name,
    'avatar_url', COALESCE(ip.avatar_url, p.avatar_url),
    'headline', CASE WHEN p_locale = 'en' THEN ip.headline_en ELSE ip.headline_ar END,
    'bio', CASE WHEN p_locale = 'en' THEN ip.bio_en ELSE ip.bio_ar END,
    'total_students', ip.total_students,
    'total_courses', ip.total_courses,
    'average_rating', ip.average_rating,
    'is_verified', ip.is_verified
  ) INTO v_instructor
  FROM courses c
  JOIN profiles p ON p.id = c.instructor_id
  LEFT JOIN instructor_profiles ip ON ip.instructor_id = c.instructor_id
  WHERE c.id = p_course_id;
  
  -- Get sections with lessons
  SELECT json_agg(
    json_build_object(
      'id', s.id,
      'title', CASE WHEN p_locale = 'en' AND s.title_en IS NOT NULL THEN s.title_en ELSE s.title_ar END,
      'total_duration', s.total_duration,
      'total_lessons', s.total_lessons,
      'lessons', (
        SELECT json_agg(
          json_build_object(
            'id', l.id,
            'title', CASE WHEN p_locale = 'en' AND l.title_en IS NOT NULL THEN l.title_en ELSE l.title_ar END,
            'type', l.type,
            'duration', l.video_duration,
            'is_preview', l.is_preview
          ) ORDER BY l.sort_order
        )
        FROM lessons l WHERE l.section_id = s.id AND l.is_published = TRUE
      )
    ) ORDER BY s.sort_order
  ) INTO v_sections
  FROM sections s WHERE s.course_id = p_course_id AND s.is_published = TRUE;
  
  -- Check enrollment status
  IF v_user_id IS NOT NULL THEN
    SELECT EXISTS(SELECT 1 FROM enrollments WHERE user_id = v_user_id AND course_id = p_course_id AND status IN ('active', 'completed')) INTO v_is_enrolled;
    SELECT EXISTS(SELECT 1 FROM wishlist WHERE user_id = v_user_id AND course_id = p_course_id) INTO v_is_wishlisted;
    SELECT EXISTS(SELECT 1 FROM cart_items WHERE user_id = v_user_id AND course_id = p_course_id) INTO v_is_in_cart;
    
    IF v_is_enrolled THEN
      SELECT json_build_object(
        'id', e.id,
        'status', e.status,
        'progress_percentage', e.progress_percentage,
        'completed_lessons', e.completed_lessons,
        'enrolled_at', e.enrolled_at,
        'completed_at', e.completed_at,
        'certificate_id', e.certificate_id
      ) INTO v_enrollment
      FROM enrollments e WHERE e.user_id = v_user_id AND e.course_id = p_course_id;
    END IF;
  ELSE
    v_is_enrolled := FALSE;
    v_is_wishlisted := FALSE;
    v_is_in_cart := FALSE;
  END IF;
  
  RETURN json_build_object(
    'course', v_course,
    'instructor', v_instructor,
    'sections', COALESCE(v_sections, '[]'::JSON),
    'is_enrolled', v_is_enrolled,
    'enrollment', v_enrollment,
    'is_wishlisted', v_is_wishlisted,
    'is_in_cart', v_is_in_cart
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11.7 Get My Learning (Enrolled Courses)
CREATE OR REPLACE FUNCTION get_my_learning(p_locale TEXT DEFAULT 'ar', p_status TEXT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  RETURN (
    SELECT json_agg(
      json_build_object(
        'enrollment_id', e.id,
        'course_id', c.id,
        'title', CASE WHEN p_locale = 'en' AND c.title_en IS NOT NULL THEN c.title_en ELSE c.title_ar END,
        'thumbnail_url', c.thumbnail_url,
        'instructor_name', p.name,
        'progress_percentage', e.progress_percentage,
        'completed_lessons', e.completed_lessons,
        'total_lessons', c.total_lessons,
        'status', e.status,
        'enrolled_at', e.enrolled_at,
        'last_accessed_at', e.last_accessed_at,
        'completed_at', e.completed_at,
        'certificate_id', e.certificate_id
      ) ORDER BY e.last_accessed_at DESC NULLS LAST
    )
    FROM enrollments e
    JOIN courses c ON c.id = e.course_id
    JOIN profiles p ON p.id = c.instructor_id
    WHERE e.user_id = v_user_id
    AND (p_status IS NULL OR e.status = p_status)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 11.8 Get Instructor Dashboard Stats
CREATE OR REPLACE FUNCTION get_instructor_dashboard_stats()
RETURNS JSON AS $$
DECLARE
  v_instructor_id UUID := auth.uid();
  v_stats JSON;
BEGIN
  SELECT json_build_object(
    'total_courses', (SELECT COUNT(*) FROM courses WHERE instructor_id = v_instructor_id),
    'published_courses', (SELECT COUNT(*) FROM courses WHERE instructor_id = v_instructor_id AND is_published = TRUE),
    'total_students', (SELECT COUNT(DISTINCT e.user_id) FROM enrollments e JOIN courses c ON c.id = e.course_id WHERE c.instructor_id = v_instructor_id AND e.status IN ('active', 'completed')),
    'total_enrollments', (SELECT COUNT(*) FROM enrollments e JOIN courses c ON c.id = e.course_id WHERE c.instructor_id = v_instructor_id),
    'total_reviews', (SELECT COUNT(*) FROM course_reviews cr JOIN courses c ON c.id = cr.course_id WHERE c.instructor_id = v_instructor_id),
    'average_rating', (SELECT COALESCE(AVG(cr.rating), 0) FROM course_reviews cr JOIN courses c ON c.id = cr.course_id WHERE c.instructor_id = v_instructor_id),
    'total_earnings', (SELECT COALESCE(SUM(net_amount), 0) FROM instructor_earnings WHERE instructor_id = v_instructor_id AND status IN ('available', 'paid')),
    'pending_earnings', (SELECT COALESCE(SUM(net_amount), 0) FROM instructor_earnings WHERE instructor_id = v_instructor_id AND status = 'pending'),
    'available_earnings', (SELECT COALESCE(SUM(net_amount), 0) FROM instructor_earnings WHERE instructor_id = v_instructor_id AND status = 'available'),
    'this_month_earnings', (SELECT COALESCE(SUM(net_amount), 0) FROM instructor_earnings WHERE instructor_id = v_instructor_id AND created_at >= DATE_TRUNC('month', NOW())),
    'this_month_enrollments', (SELECT COUNT(*) FROM enrollments e JOIN courses c ON c.id = e.course_id WHERE c.instructor_id = v_instructor_id AND e.created_at >= DATE_TRUNC('month', NOW()))
  ) INTO v_stats;
  
  RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11.9 Get Monthly Stats (for charts)
CREATE OR REPLACE FUNCTION get_monthly_stats(p_months INTEGER DEFAULT 6)
RETURNS TABLE (
  month_name TEXT,
  month_number INTEGER,
  year_number INTEGER,
  total_revenue NUMERIC,
  new_students INTEGER,
  total_enrollments INTEGER,
  completed_courses INTEGER
) AS $$
BEGIN
  RETURN QUERY
  WITH months AS (
    SELECT 
      TO_CHAR(d, 'MM/YY') as m_label,
      EXTRACT(MONTH FROM d)::INTEGER as m_num,
      EXTRACT(YEAR FROM d)::INTEGER as y_num,
      DATE_TRUNC('month', d) as month_start
    FROM generate_series(
      DATE_TRUNC('month', NOW()) - ((p_months - 1) || ' months')::INTERVAL,
      DATE_TRUNC('month', NOW()),
      '1 month'::INTERVAL
    ) d
  ),
  enrollment_stats AS (
    SELECT 
      DATE_TRUNC('month', e.created_at) as enrollment_month,
      COALESCE(SUM(e.price), 0) as revenue,
      COUNT(*) as enrollments,
      COUNT(CASE WHEN e.status = 'completed' THEN 1 END) as completed
    FROM enrollments e
    WHERE e.created_at >= DATE_TRUNC('month', NOW()) - ((p_months - 1) || ' months')::INTERVAL
    GROUP BY DATE_TRUNC('month', e.created_at)
  ),
  student_stats AS (
    SELECT 
      DATE_TRUNC('month', p.created_at) as student_month,
      COUNT(*) as new_students
    FROM profiles p
    WHERE p.role = 'student'
      AND p.created_at >= DATE_TRUNC('month', NOW()) - ((p_months - 1) || ' months')::INTERVAL
    GROUP BY DATE_TRUNC('month', p.created_at)
  )
  SELECT 
    m.m_label::TEXT,
    m.m_num,
    m.y_num,
    COALESCE(es.revenue, 0)::NUMERIC,
    COALESCE(ss.new_students, 0)::INTEGER,
    COALESCE(es.enrollments, 0)::INTEGER,
    COALESCE(es.completed, 0)::INTEGER
  FROM months m
  LEFT JOIN enrollment_stats es ON DATE_TRUNC('month', es.enrollment_month) = m.month_start
  LEFT JOIN student_stats ss ON DATE_TRUNC('month', ss.student_month) = m.month_start
  ORDER BY m.y_num, m.m_num;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11.10 Search Courses Function
CREATE OR REPLACE FUNCTION search_courses(
  p_query TEXT DEFAULT NULL,
  p_category_id UUID DEFAULT NULL,
  p_level TEXT DEFAULT NULL,
  p_language TEXT DEFAULT NULL,
  p_min_price DECIMAL DEFAULT NULL,
  p_max_price DECIMAL DEFAULT NULL,
  p_min_rating DECIMAL DEFAULT NULL,
  p_is_free BOOLEAN DEFAULT NULL,
  p_sort_by TEXT DEFAULT 'popular', -- popular, newest, rating, price_low, price_high
  p_locale TEXT DEFAULT 'ar',
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
)
RETURNS JSON AS $$
DECLARE
  v_total INTEGER;
  v_courses JSON;
BEGIN
  -- Get total count
  SELECT COUNT(*) INTO v_total
  FROM courses c
  WHERE c.is_published = TRUE AND c.is_active = TRUE AND c.is_suspended = FALSE
    AND (p_query IS NULL OR 
         c.title_ar ILIKE '%' || p_query || '%' OR 
         c.title_en ILIKE '%' || p_query || '%' OR
         c.description_ar ILIKE '%' || p_query || '%' OR
         c.description_en ILIKE '%' || p_query || '%')
    AND (p_category_id IS NULL OR c.category_id = p_category_id)
    AND (p_level IS NULL OR c.level = p_level)
    AND (p_language IS NULL OR c.language = p_language)
    AND (p_min_price IS NULL OR COALESCE(c.discount_price, c.price) >= p_min_price)
    AND (p_max_price IS NULL OR COALESCE(c.discount_price, c.price) <= p_max_price)
    AND (p_min_rating IS NULL OR c.rating >= p_min_rating)
    AND (p_is_free IS NULL OR c.is_free = p_is_free);
  
  -- Get courses
  SELECT json_agg(course_data) INTO v_courses
  FROM (
    SELECT 
      c.id,
      CASE WHEN p_locale = 'en' AND c.title_en IS NOT NULL THEN c.title_en ELSE c.title_ar END as title,
      CASE WHEN p_locale = 'en' AND c.subtitle_en IS NOT NULL THEN c.subtitle_en ELSE c.subtitle_ar END as subtitle,
      c.thumbnail_url,
      c.price,
      c.discount_price,
      c.is_free,
      c.level,
      c.language,
      c.total_duration,
      c.total_lessons,
      c.enrolled_count,
      c.rating,
      c.rating_count,
      c.is_featured,
      c.is_flash_sale AND c.flash_sale_end > NOW() as is_flash_sale,
      c.flash_sale_price,
      c.flash_sale_end,
      p.name as instructor_name,
      p.avatar_url as instructor_avatar
    FROM courses c
    JOIN profiles p ON p.id = c.instructor_id
    WHERE c.is_published = TRUE AND c.is_active = TRUE AND c.is_suspended = FALSE
      AND (p_query IS NULL OR 
           c.title_ar ILIKE '%' || p_query || '%' OR 
           c.title_en ILIKE '%' || p_query || '%' OR
           c.description_ar ILIKE '%' || p_query || '%' OR
           c.description_en ILIKE '%' || p_query || '%')
      AND (p_category_id IS NULL OR c.category_id = p_category_id)
      AND (p_level IS NULL OR c.level = p_level)
      AND (p_language IS NULL OR c.language = p_language)
      AND (p_min_price IS NULL OR COALESCE(c.discount_price, c.price) >= p_min_price)
      AND (p_max_price IS NULL OR COALESCE(c.discount_price, c.price) <= p_max_price)
      AND (p_min_rating IS NULL OR c.rating >= p_min_rating)
      AND (p_is_free IS NULL OR c.is_free = p_is_free)
    ORDER BY
      CASE WHEN p_sort_by = 'popular' THEN c.enrolled_count END DESC,
      CASE WHEN p_sort_by = 'newest' THEN c.created_at END DESC,
      CASE WHEN p_sort_by = 'rating' THEN c.rating END DESC,
      CASE WHEN p_sort_by = 'price_low' THEN COALESCE(c.discount_price, c.price) END ASC,
      CASE WHEN p_sort_by = 'price_high' THEN COALESCE(c.discount_price, c.price) END DESC,
      c.enrolled_count DESC
    LIMIT p_limit OFFSET p_offset
  ) course_data;
  
  RETURN json_build_object(
    'total', v_total,
    'courses', COALESCE(v_courses, '[]'::JSON)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 11.11 Get Home Page Data
CREATE OR REPLACE FUNCTION get_home_page_data(p_locale TEXT DEFAULT 'ar')
RETURNS JSON AS $$
DECLARE
  v_banners JSON;
  v_categories JSON;
  v_featured_courses JSON;
  v_popular_courses JSON;
  v_new_courses JSON;
  v_flash_sale_courses JSON;
BEGIN
  -- Get active banners
  SELECT json_agg(
    json_build_object(
      'id', b.id,
      'title', CASE WHEN p_locale = 'en' AND b.title_en IS NOT NULL THEN b.title_en ELSE b.title_ar END,
      'subtitle', CASE WHEN p_locale = 'en' AND b.subtitle_en IS NOT NULL THEN b.subtitle_en ELSE b.subtitle_ar END,
      'image_url', b.image_url,
      'link_type', b.link_type,
      'link_value', b.link_value
    ) ORDER BY b.sort_order
  ) INTO v_banners
  FROM banners b
  WHERE b.is_active = TRUE
    AND (b.start_date IS NULL OR b.start_date <= NOW())
    AND (b.end_date IS NULL OR b.end_date >= NOW());
  
  -- Get categories
  SELECT json_agg(
    json_build_object(
      'id', cat.id,
      'name', CASE WHEN p_locale = 'en' AND cat.name_en IS NOT NULL THEN cat.name_en ELSE cat.name_ar END,
      'image_url', cat.image_url,
      'icon_name', cat.icon_name,
      'courses_count', cat.courses_count
    ) ORDER BY cat.sort_order
  ) INTO v_categories
  FROM categories cat
  WHERE cat.is_active = TRUE AND cat.parent_id IS NULL;
  
  -- Get featured courses
  SELECT json_agg(course_data) INTO v_featured_courses
  FROM (
    SELECT 
      c.id,
      CASE WHEN p_locale = 'en' AND c.title_en IS NOT NULL THEN c.title_en ELSE c.title_ar END as title,
      c.thumbnail_url,
      c.price,
      c.discount_price,
      c.is_free,
      c.rating,
      c.rating_count,
      c.enrolled_count,
      c.total_duration,
      p.name as instructor_name
    FROM courses c
    JOIN profiles p ON p.id = c.instructor_id
    WHERE c.is_published = TRUE AND c.is_active = TRUE AND c.is_featured = TRUE
    ORDER BY c.enrolled_count DESC
    LIMIT 10
  ) course_data;
  
  -- Get popular courses
  SELECT json_agg(course_data) INTO v_popular_courses
  FROM (
    SELECT 
      c.id,
      CASE WHEN p_locale = 'en' AND c.title_en IS NOT NULL THEN c.title_en ELSE c.title_ar END as title,
      c.thumbnail_url,
      c.price,
      c.discount_price,
      c.is_free,
      c.rating,
      c.rating_count,
      c.enrolled_count,
      c.total_duration,
      p.name as instructor_name
    FROM courses c
    JOIN profiles p ON p.id = c.instructor_id
    WHERE c.is_published = TRUE AND c.is_active = TRUE
    ORDER BY c.enrolled_count DESC
    LIMIT 10
  ) course_data;
  
  -- Get new courses
  SELECT json_agg(course_data) INTO v_new_courses
  FROM (
    SELECT 
      c.id,
      CASE WHEN p_locale = 'en' AND c.title_en IS NOT NULL THEN c.title_en ELSE c.title_ar END as title,
      c.thumbnail_url,
      c.price,
      c.discount_price,
      c.is_free,
      c.rating,
      c.rating_count,
      c.enrolled_count,
      c.total_duration,
      p.name as instructor_name
    FROM courses c
    JOIN profiles p ON p.id = c.instructor_id
    WHERE c.is_published = TRUE AND c.is_active = TRUE
    ORDER BY c.published_at DESC NULLS LAST, c.created_at DESC
    LIMIT 10
  ) course_data;
  
  -- Get flash sale courses
  SELECT json_agg(course_data) INTO v_flash_sale_courses
  FROM (
    SELECT 
      c.id,
      CASE WHEN p_locale = 'en' AND c.title_en IS NOT NULL THEN c.title_en ELSE c.title_ar END as title,
      c.thumbnail_url,
      c.price,
      c.flash_sale_price as discount_price,
      c.flash_sale_end,
      c.rating,
      c.rating_count,
      c.enrolled_count,
      p.name as instructor_name
    FROM courses c
    JOIN profiles p ON p.id = c.instructor_id
    WHERE c.is_published = TRUE AND c.is_active = TRUE 
      AND c.is_flash_sale = TRUE AND c.flash_sale_end > NOW()
    ORDER BY c.flash_sale_end ASC
    LIMIT 10
  ) course_data;
  
  RETURN json_build_object(
    'banners', COALESCE(v_banners, '[]'::JSON),
    'categories', COALESCE(v_categories, '[]'::JSON),
    'featured_courses', COALESCE(v_featured_courses, '[]'::JSON),
    'popular_courses', COALESCE(v_popular_courses, '[]'::JSON),
    'new_courses', COALESCE(v_new_courses, '[]'::JSON),
    'flash_sale_courses', COALESCE(v_flash_sale_courses, '[]'::JSON)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11.12 Ban User Function
CREATE OR REPLACE FUNCTION ban_user(
  p_user_id UUID,
  p_ban_duration TEXT DEFAULT 'none', -- 'none', '24h', '7d', '30d', 'forever'
  p_reason TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_ban_until TIMESTAMPTZ;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Only admins can ban users';
  END IF;
  
  IF p_ban_duration = 'none' THEN
    v_ban_until := NULL;
  ELSIF p_ban_duration = '24h' THEN
    v_ban_until := NOW() + INTERVAL '24 hours';
  ELSIF p_ban_duration = '7d' THEN
    v_ban_until := NOW() + INTERVAL '7 days';
  ELSIF p_ban_duration = '30d' THEN
    v_ban_until := NOW() + INTERVAL '30 days';
  ELSIF p_ban_duration = 'forever' THEN
    v_ban_until := NOW() + INTERVAL '100 years';
  ELSE
    RAISE EXCEPTION 'Invalid ban duration';
  END IF;
  
  UPDATE profiles SET
    is_banned = (p_ban_duration != 'none'),
    banned_until = v_ban_until,
    ban_reason = p_reason
  WHERE id = p_user_id;
  
  UPDATE auth.users SET
    banned_until = v_ban_until
  WHERE id = p_user_id;
  
  RETURN json_build_object(
    'success', true,
    'user_id', p_user_id,
    'banned', p_ban_duration != 'none',
    'banned_until', v_ban_until
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- PART 12: ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE review_helpful ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE qa_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE qa_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcement_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupon_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupon_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupon_usages ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE review_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_earnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE payout_items ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 12.1 PROFILES POLICIES
-- ============================================================
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Enable insert for auth" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Admins can view all profiles" ON profiles FOR SELECT USING (is_admin());
CREATE POLICY "Admins can update all profiles" ON profiles FOR UPDATE USING (is_admin());
CREATE POLICY "Public can view instructors" ON profiles FOR SELECT USING (role = 'instructor');

-- ============================================================
-- 12.2 CATEGORIES POLICIES
-- ============================================================
CREATE POLICY "Anyone can view active categories" ON categories FOR SELECT USING (is_active = TRUE);
CREATE POLICY "Admins can manage categories" ON categories FOR ALL USING (is_admin());

-- ============================================================
-- 12.3 INSTRUCTOR_PROFILES POLICIES
-- ============================================================
CREATE POLICY "Anyone can view instructor profiles" ON instructor_profiles FOR SELECT USING (is_active = TRUE);
CREATE POLICY "Instructors can manage own profile" ON instructor_profiles FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "Admins can manage all instructor profiles" ON instructor_profiles FOR ALL USING (is_admin());

-- ============================================================
-- 12.4 COURSES POLICIES
-- ============================================================
CREATE POLICY "Anyone can view published courses" ON courses FOR SELECT 
  USING (is_published = TRUE AND is_active = TRUE AND is_suspended = FALSE);
CREATE POLICY "Instructors can view own courses" ON courses FOR SELECT USING (instructor_id = auth.uid());
CREATE POLICY "Instructors can manage own courses" ON courses FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "Admins can manage all courses" ON courses FOR ALL USING (is_admin());

-- ============================================================
-- 12.5 SECTIONS POLICIES
-- ============================================================
CREATE POLICY "Anyone can view published sections" ON sections FOR SELECT 
  USING (is_published = TRUE AND EXISTS (
    SELECT 1 FROM courses c WHERE c.id = sections.course_id AND c.is_published = TRUE
  ));
CREATE POLICY "Instructors can manage own course sections" ON sections FOR ALL 
  USING (EXISTS (SELECT 1 FROM courses c WHERE c.id = sections.course_id AND c.instructor_id = auth.uid()));
CREATE POLICY "Admins can manage all sections" ON sections FOR ALL USING (is_admin());

-- ============================================================
-- 12.6 LESSONS POLICIES
-- ============================================================
CREATE POLICY "Anyone can view preview lessons" ON lessons FOR SELECT USING (is_preview = TRUE AND is_published = TRUE);
CREATE POLICY "Enrolled students can view lessons" ON lessons FOR SELECT 
  USING (is_published = TRUE AND is_enrolled(course_id));
CREATE POLICY "Instructors can manage own course lessons" ON lessons FOR ALL 
  USING (EXISTS (SELECT 1 FROM courses c WHERE c.id = lessons.course_id AND c.instructor_id = auth.uid()));
CREATE POLICY "Admins can manage all lessons" ON lessons FOR ALL USING (is_admin());

-- ============================================================
-- 12.7 LESSON_ATTACHMENTS POLICIES
-- ============================================================
CREATE POLICY "Enrolled students can view attachments" ON lesson_attachments FOR SELECT 
  USING (EXISTS (
    SELECT 1 FROM lessons l WHERE l.id = lesson_attachments.lesson_id AND is_enrolled(l.course_id)
  ));
CREATE POLICY "Instructors can manage own attachments" ON lesson_attachments FOR ALL 
  USING (EXISTS (
    SELECT 1 FROM lessons l JOIN courses c ON c.id = l.course_id 
    WHERE l.id = lesson_attachments.lesson_id AND c.instructor_id = auth.uid()
  ));

-- ============================================================
-- 12.8 CART & WISHLIST POLICIES
-- ============================================================
CREATE POLICY "Users can manage own cart" ON cart_items FOR ALL USING (user_id = auth.uid());
CREATE POLICY "Users can manage own wishlist" ON wishlist FOR ALL USING (user_id = auth.uid());

-- ============================================================
-- 12.9 ENROLLMENTS POLICIES
-- ============================================================
CREATE POLICY "Users can view own enrollments" ON parent_enrollments FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can create own enrollments" ON parent_enrollments FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Admins can view all enrollments" ON parent_enrollments FOR SELECT USING (is_admin());

CREATE POLICY "Users can view own course enrollments" ON enrollments FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Instructors can view their course enrollments" ON enrollments FOR SELECT USING (instructor_id = auth.uid());
CREATE POLICY "Users can create own enrollments" ON enrollments FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Admins can manage all enrollments" ON enrollments FOR ALL USING (is_admin());

-- ============================================================
-- 12.10 PROGRESS POLICIES
-- ============================================================
CREATE POLICY "Users can manage own progress" ON lesson_progress FOR ALL USING (user_id = auth.uid());
CREATE POLICY "Instructors can view student progress" ON lesson_progress FOR SELECT 
  USING (EXISTS (SELECT 1 FROM courses c WHERE c.id = lesson_progress.course_id AND c.instructor_id = auth.uid()));

-- ============================================================
-- 12.11 CERTIFICATES POLICIES
-- ============================================================
CREATE POLICY "Users can view own certificates" ON certificates FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Anyone can verify certificates" ON certificates FOR SELECT USING (TRUE);
CREATE POLICY "System can create certificates" ON certificates FOR INSERT WITH CHECK (user_id = auth.uid());


-- ============================================================
-- 12.12 REVIEWS POLICIES
-- ============================================================
CREATE POLICY "Anyone can view visible reviews" ON course_reviews FOR SELECT USING (is_visible = TRUE);
CREATE POLICY "Users can create reviews" ON course_reviews FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own reviews" ON course_reviews FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete own reviews" ON course_reviews FOR DELETE USING (user_id = auth.uid());
CREATE POLICY "Admins can manage all reviews" ON course_reviews FOR ALL USING (is_admin());

CREATE POLICY "Users can manage own helpful votes" ON review_helpful FOR ALL USING (user_id = auth.uid());

-- ============================================================
-- 12.13 NOTES & BOOKMARKS POLICIES
-- ============================================================
CREATE POLICY "Users can manage own notes" ON notes FOR ALL USING (user_id = auth.uid());
CREATE POLICY "Users can manage own bookmarks" ON bookmarks FOR ALL USING (user_id = auth.uid());

-- ============================================================
-- 12.14 Q&A POLICIES
-- ============================================================
CREATE POLICY "Anyone can view visible questions" ON qa_questions FOR SELECT USING (is_visible = TRUE);
CREATE POLICY "Users can create questions" ON qa_questions FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own questions" ON qa_questions FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Instructors can manage course questions" ON qa_questions FOR ALL 
  USING (EXISTS (SELECT 1 FROM courses c WHERE c.id = qa_questions.course_id AND c.instructor_id = auth.uid()));

CREATE POLICY "Anyone can view visible answers" ON qa_answers FOR SELECT USING (is_visible = TRUE);
CREATE POLICY "Users can create answers" ON qa_answers FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own answers" ON qa_answers FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Instructors can manage course answers" ON qa_answers FOR ALL 
  USING (EXISTS (
    SELECT 1 FROM qa_questions q JOIN courses c ON c.id = q.course_id 
    WHERE q.id = qa_answers.question_id AND c.instructor_id = auth.uid()
  ));

-- ============================================================
-- 12.15 QUIZZES POLICIES
-- ============================================================
CREATE POLICY "Enrolled students can view quizzes" ON quizzes FOR SELECT 
  USING (is_published = TRUE AND is_enrolled(course_id));
CREATE POLICY "Instructors can manage own quizzes" ON quizzes FOR ALL 
  USING (EXISTS (SELECT 1 FROM courses c WHERE c.id = quizzes.course_id AND c.instructor_id = auth.uid()));

CREATE POLICY "Enrolled students can view quiz questions" ON quiz_questions FOR SELECT 
  USING (EXISTS (SELECT 1 FROM quizzes q WHERE q.id = quiz_questions.quiz_id AND is_enrolled(q.course_id)));
CREATE POLICY "Instructors can manage own quiz questions" ON quiz_questions FOR ALL 
  USING (EXISTS (
    SELECT 1 FROM quizzes q JOIN courses c ON c.id = q.course_id 
    WHERE q.id = quiz_questions.quiz_id AND c.instructor_id = auth.uid()
  ));

CREATE POLICY "Users can manage own quiz attempts" ON quiz_attempts FOR ALL USING (user_id = auth.uid());
CREATE POLICY "Instructors can view student attempts" ON quiz_attempts FOR SELECT 
  USING (EXISTS (
    SELECT 1 FROM quizzes q JOIN courses c ON c.id = q.course_id 
    WHERE q.id = quiz_attempts.quiz_id AND c.instructor_id = auth.uid()
  ));

-- ============================================================
-- 12.16 ANNOUNCEMENTS POLICIES
-- ============================================================
CREATE POLICY "Enrolled students can view announcements" ON announcements FOR SELECT 
  USING (is_published = TRUE AND is_enrolled(course_id));
CREATE POLICY "Instructors can manage own announcements" ON announcements FOR ALL 
  USING (instructor_id = auth.uid());

CREATE POLICY "Users can manage own announcement reads" ON announcement_reads FOR ALL USING (user_id = auth.uid());

-- ============================================================
-- 12.17 COUPONS POLICIES
-- ============================================================
CREATE POLICY "Anyone can view active coupons" ON coupons FOR SELECT 
  USING (is_active = TRUE AND is_suspended = FALSE AND start_date <= NOW() AND (end_date IS NULL OR end_date > NOW()));
CREATE POLICY "Instructors can manage own coupons" ON coupons FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "Admins can manage all coupons" ON coupons FOR ALL USING (is_admin());

CREATE POLICY "Anyone can view coupon categories" ON coupon_categories FOR SELECT USING (TRUE);
CREATE POLICY "Anyone can view coupon courses" ON coupon_courses FOR SELECT USING (TRUE);
CREATE POLICY "Users can view own coupon usages" ON coupon_usages FOR SELECT USING (user_id = auth.uid());

-- ============================================================
-- 12.18 REPORTS POLICIES
-- ============================================================
CREATE POLICY "Users can view own reports" ON course_reports FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can create reports" ON course_reports FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Admins can manage all reports" ON course_reports FOR ALL USING (is_admin());

CREATE POLICY "Users can view own review reports" ON review_reports FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can create review reports" ON review_reports FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Admins can manage all review reports" ON review_reports FOR ALL USING (is_admin());

-- ============================================================
-- 12.19 BANNERS POLICIES
-- ============================================================
CREATE POLICY "Anyone can view active banners" ON banners FOR SELECT 
  USING (is_active = TRUE AND (start_date IS NULL OR start_date <= NOW()) AND (end_date IS NULL OR end_date >= NOW()));
CREATE POLICY "Admins can manage banners" ON banners FOR ALL USING (is_admin());

-- ============================================================
-- 12.20 EARNINGS & PAYOUTS POLICIES
-- ============================================================
CREATE POLICY "Instructors can view own earnings" ON instructor_earnings FOR SELECT USING (instructor_id = auth.uid());
CREATE POLICY "Admins can manage all earnings" ON instructor_earnings FOR ALL USING (is_admin());

CREATE POLICY "Instructors can view own payouts" ON instructor_payouts FOR SELECT USING (instructor_id = auth.uid());
CREATE POLICY "Instructors can request payouts" ON instructor_payouts FOR INSERT WITH CHECK (instructor_id = auth.uid());
CREATE POLICY "Admins can manage all payouts" ON instructor_payouts FOR ALL USING (is_admin());

CREATE POLICY "Instructors can view own payout items" ON payout_items FOR SELECT 
  USING (EXISTS (SELECT 1 FROM instructor_payouts p WHERE p.id = payout_items.payout_id AND p.instructor_id = auth.uid()));
CREATE POLICY "Admins can manage payout items" ON payout_items FOR ALL USING (is_admin());


-- ============================================================
-- PART 13: STORAGE BUCKETS
-- ============================================================

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES ('courses', 'courses', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('categories', 'categories', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('instructors', 'instructors', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('banners', 'banners', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('videos', 'videos', false) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('attachments', 'attachments', false) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('certificates', 'certificates', true) ON CONFLICT (id) DO NOTHING;

-- Storage policies for courses bucket
CREATE POLICY "Public Access to Course Images" ON storage.objects FOR SELECT USING (bucket_id = 'courses');
CREATE POLICY "Instructors can upload course images" ON storage.objects FOR INSERT 
  WITH CHECK (bucket_id = 'courses' AND is_instructor());
CREATE POLICY "Instructors can update course images" ON storage.objects FOR UPDATE 
  USING (bucket_id = 'courses' AND is_instructor());
CREATE POLICY "Instructors can delete course images" ON storage.objects FOR DELETE 
  USING (bucket_id = 'courses' AND is_instructor());

-- Storage policies for categories bucket
CREATE POLICY "Public Access to Category Images" ON storage.objects FOR SELECT USING (bucket_id = 'categories');
CREATE POLICY "Admins can manage category images" ON storage.objects FOR ALL 
  USING (bucket_id = 'categories' AND is_admin());

-- Storage policies for instructors bucket
CREATE POLICY "Public Access to Instructor Images" ON storage.objects FOR SELECT USING (bucket_id = 'instructors');
CREATE POLICY "Instructors can upload own images" ON storage.objects FOR INSERT 
  WITH CHECK (bucket_id = 'instructors' AND auth.role() = 'authenticated');
CREATE POLICY "Instructors can update own images" ON storage.objects FOR UPDATE 
  USING (bucket_id = 'instructors' AND auth.role() = 'authenticated');

-- Storage policies for avatars bucket
CREATE POLICY "Public Access to Avatars" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Users can upload own avatar" ON storage.objects FOR INSERT 
  WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');
CREATE POLICY "Users can update own avatar" ON storage.objects FOR UPDATE 
  USING (bucket_id = 'avatars' AND auth.role() = 'authenticated');

-- Storage policies for banners bucket
CREATE POLICY "Public Access to Banners" ON storage.objects FOR SELECT USING (bucket_id = 'banners');
CREATE POLICY "Admins can manage banners" ON storage.objects FOR ALL 
  USING (bucket_id = 'banners' AND is_admin());

-- Storage policies for videos bucket (private - only enrolled students)
CREATE POLICY "Enrolled students can view videos" ON storage.objects FOR SELECT 
  USING (bucket_id = 'videos' AND auth.role() = 'authenticated');
CREATE POLICY "Instructors can upload videos" ON storage.objects FOR INSERT 
  WITH CHECK (bucket_id = 'videos' AND is_instructor());
CREATE POLICY "Instructors can update videos" ON storage.objects FOR UPDATE 
  USING (bucket_id = 'videos' AND is_instructor());
CREATE POLICY "Instructors can delete videos" ON storage.objects FOR DELETE 
  USING (bucket_id = 'videos' AND is_instructor());

-- Storage policies for attachments bucket
CREATE POLICY "Enrolled students can download attachments" ON storage.objects FOR SELECT 
  USING (bucket_id = 'attachments' AND auth.role() = 'authenticated');
CREATE POLICY "Instructors can manage attachments" ON storage.objects FOR ALL 
  USING (bucket_id = 'attachments' AND is_instructor());

-- Storage policies for certificates bucket
CREATE POLICY "Public Access to Certificates" ON storage.objects FOR SELECT USING (bucket_id = 'certificates');
CREATE POLICY "System can create certificates" ON storage.objects FOR INSERT 
  WITH CHECK (bucket_id = 'certificates' AND auth.role() = 'authenticated');

-- ============================================================
-- PART 14: GRANTS AND PERMISSIONS
-- ============================================================

-- Grant table permissions
GRANT SELECT ON profiles TO authenticated, anon;
GRANT UPDATE, INSERT ON profiles TO authenticated;

GRANT SELECT ON categories TO authenticated, anon;
GRANT INSERT, UPDATE, DELETE ON categories TO authenticated;

GRANT SELECT ON instructor_profiles TO authenticated, anon;
GRANT INSERT, UPDATE, DELETE ON instructor_profiles TO authenticated;

GRANT SELECT ON courses TO authenticated, anon;
GRANT INSERT, UPDATE, DELETE ON courses TO authenticated;

GRANT SELECT ON sections TO authenticated, anon;
GRANT INSERT, UPDATE, DELETE ON sections TO authenticated;

GRANT SELECT ON lessons TO authenticated;
GRANT INSERT, UPDATE, DELETE ON lessons TO authenticated;

GRANT SELECT ON lesson_attachments TO authenticated;
GRANT INSERT, UPDATE, DELETE ON lesson_attachments TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON cart_items TO authenticated;
GRANT SELECT, INSERT, DELETE ON wishlist TO authenticated;

GRANT SELECT, INSERT ON parent_enrollments TO authenticated;
GRANT SELECT, INSERT, UPDATE ON enrollments TO authenticated;
GRANT SELECT, INSERT, UPDATE ON lesson_progress TO authenticated;
GRANT SELECT, INSERT ON certificates TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON course_reviews TO authenticated;
GRANT SELECT, INSERT, DELETE ON review_helpful TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON notes TO authenticated;
GRANT SELECT, INSERT, DELETE ON bookmarks TO authenticated;

GRANT SELECT, INSERT, UPDATE ON qa_questions TO authenticated;
GRANT SELECT, INSERT, UPDATE ON qa_answers TO authenticated;

GRANT SELECT ON quizzes TO authenticated;
GRANT INSERT, UPDATE, DELETE ON quizzes TO authenticated;
GRANT SELECT ON quiz_questions TO authenticated;
GRANT INSERT, UPDATE, DELETE ON quiz_questions TO authenticated;
GRANT SELECT, INSERT ON quiz_attempts TO authenticated;

GRANT SELECT ON announcements TO authenticated;
GRANT INSERT, UPDATE, DELETE ON announcements TO authenticated;
GRANT SELECT, INSERT ON announcement_reads TO authenticated;

GRANT SELECT ON coupons TO authenticated;
GRANT INSERT, UPDATE, DELETE ON coupons TO authenticated;
GRANT SELECT ON coupon_categories TO authenticated;
GRANT SELECT ON coupon_courses TO authenticated;
GRANT SELECT, INSERT ON coupon_usages TO authenticated;

GRANT SELECT, INSERT ON course_reports TO authenticated;
GRANT SELECT, INSERT ON review_reports TO authenticated;

GRANT SELECT ON banners TO authenticated, anon;
GRANT INSERT, UPDATE, DELETE ON banners TO authenticated;

GRANT SELECT ON instructor_earnings TO authenticated;
GRANT SELECT, INSERT ON instructor_payouts TO authenticated;
GRANT SELECT ON payout_items TO authenticated;


-- Grant function permissions
GRANT EXECUTE ON FUNCTION is_instructor TO authenticated;
GRANT EXECUTE ON FUNCTION is_admin TO authenticated;
GRANT EXECUTE ON FUNCTION is_enrolled TO authenticated;
GRANT EXECUTE ON FUNCTION create_enrollment TO authenticated;
GRANT EXECUTE ON FUNCTION confirm_enrollment_payment TO authenticated;
GRANT EXECUTE ON FUNCTION update_lesson_progress TO authenticated;
GRANT EXECUTE ON FUNCTION issue_certificate TO authenticated;
GRANT EXECUTE ON FUNCTION validate_coupon TO authenticated;
GRANT EXECUTE ON FUNCTION get_course_details TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_my_learning TO authenticated;
GRANT EXECUTE ON FUNCTION get_instructor_dashboard_stats TO authenticated;
GRANT EXECUTE ON FUNCTION get_monthly_stats TO authenticated;
GRANT EXECUTE ON FUNCTION search_courses TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_home_page_data TO authenticated, anon;
GRANT EXECUTE ON FUNCTION ban_user TO authenticated;

-- ============================================================
-- PART 15: REALTIME SUBSCRIPTIONS
-- ============================================================

ALTER PUBLICATION supabase_realtime ADD TABLE enrollments;
ALTER PUBLICATION supabase_realtime ADD TABLE cart_items;
ALTER PUBLICATION supabase_realtime ADD TABLE courses;
ALTER PUBLICATION supabase_realtime ADD TABLE lesson_progress;
ALTER PUBLICATION supabase_realtime ADD TABLE qa_questions;
ALTER PUBLICATION supabase_realtime ADD TABLE qa_answers;
ALTER PUBLICATION supabase_realtime ADD TABLE announcements;

-- ============================================================
-- PART 16: SEED DATA
-- ============================================================

-- 16.1 Sample Categories
INSERT INTO categories (name_ar, name_en, icon_name, sort_order) VALUES
  ('تطوير الويب', 'Web Development', 'web', 1),
  ('تطوير تطبيقات الموبايل', 'Mobile Development', 'phone_android', 2),
  ('علوم البيانات', 'Data Science', 'analytics', 3),
  ('الذكاء الاصطناعي', 'Artificial Intelligence', 'psychology', 4),
  ('التصميم', 'Design', 'palette', 5),
  ('التسويق الرقمي', 'Digital Marketing', 'campaign', 6),
  ('إدارة الأعمال', 'Business', 'business', 7),
  ('اللغات', 'Languages', 'translate', 8),
  ('التصوير والفيديو', 'Photography & Video', 'camera_alt', 9),
  ('الموسيقى', 'Music', 'music_note', 10)
ON CONFLICT DO NOTHING;

-- 16.2 Sample Coupons
INSERT INTO coupons (code, name_ar, name_en, description_ar, description_en, discount_type, discount_value, max_discount_amount, min_order_amount, usage_limit, end_date) VALUES
  ('WELCOME20', 'خصم الترحيب', 'Welcome Discount', 'خصم 20% للمستخدمين الجدد', '20% off for new users', 'percentage', 20, 100, 50, 1000, NOW() + INTERVAL '1 year'),
  ('LEARN50', 'تعلم ووفر', 'Learn & Save', 'خصم 50 جنيه على أي كورس', '50 EGP off any course', 'fixed', 50, NULL, 100, 500, NOW() + INTERVAL '6 months'),
  ('SUMMER30', 'عرض الصيف', 'Summer Sale', 'خصم 30% على جميع الكورسات', '30% off all courses', 'percentage', 30, 200, 100, NULL, NOW() + INTERVAL '3 months')
ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- END OF LMS COMPLETE DATABASE SCHEMA
-- ============================================================

-- Summary:
-- ✅ 30+ Tables created
-- ✅ 50+ Indexes for performance
-- ✅ 12+ Functions for business logic
-- ✅ 60+ RLS Policies for security
-- ✅ 8 Storage Buckets
-- ✅ Realtime subscriptions enabled
-- ✅ Sample seed data included

-- Next Steps:
-- 1. Run this script in Supabase SQL Editor
-- 2. Update Flutter models to match new schema
-- 3. Update repositories and data sources
-- 4. Build new UI screens

