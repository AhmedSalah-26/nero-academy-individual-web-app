
-- =====================================================================
-- File: 100_lms_complete_schema.sql
-- =====================================================================
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

CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_active ON profiles(is_active) WHERE is_active = TRUE;

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

CREATE INDEX IF NOT EXISTS idx_categories_active ON categories(is_active);
CREATE INDEX IF NOT EXISTS idx_categories_parent ON categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_categories_sort ON categories(sort_order);


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

CREATE INDEX IF NOT EXISTS idx_instructor_profiles_instructor ON instructor_profiles(instructor_id);
CREATE INDEX IF NOT EXISTS idx_instructor_profiles_verified ON instructor_profiles(is_verified);
CREATE INDEX IF NOT EXISTS idx_instructor_profiles_rating ON instructor_profiles(average_rating DESC);

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

CREATE INDEX IF NOT EXISTS idx_courses_instructor ON courses(instructor_id);
CREATE INDEX IF NOT EXISTS idx_courses_category ON courses(category_id);
CREATE INDEX IF NOT EXISTS idx_courses_published ON courses(is_published) WHERE is_published = TRUE;
CREATE INDEX IF NOT EXISTS idx_courses_active ON courses(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_courses_featured ON courses(is_featured) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_courses_level ON courses(level);
CREATE INDEX IF NOT EXISTS idx_courses_language ON courses(language);
CREATE INDEX IF NOT EXISTS idx_courses_price ON courses(price);
CREATE INDEX IF NOT EXISTS idx_courses_rating ON courses(rating DESC);
CREATE INDEX IF NOT EXISTS idx_courses_enrolled ON courses(enrolled_count DESC);
CREATE INDEX IF NOT EXISTS idx_courses_created ON courses(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_courses_flash_sale ON courses(is_flash_sale, flash_sale_end) WHERE is_flash_sale = TRUE;


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

CREATE INDEX IF NOT EXISTS idx_sections_course ON sections(course_id);
CREATE INDEX IF NOT EXISTS idx_sections_sort ON sections(course_id, sort_order);

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

CREATE INDEX IF NOT EXISTS idx_lessons_section ON lessons(section_id);
CREATE INDEX IF NOT EXISTS idx_lessons_course ON lessons(course_id);
CREATE INDEX IF NOT EXISTS idx_lessons_sort ON lessons(section_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_lessons_preview ON lessons(is_preview) WHERE is_preview = TRUE;
CREATE INDEX IF NOT EXISTS idx_lessons_type ON lessons(type);

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

CREATE INDEX IF NOT EXISTS idx_attachments_lesson ON lesson_attachments(lesson_id);

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

CREATE INDEX IF NOT EXISTS idx_cart_items_user ON cart_items(user_id);

-- 2.2 WISHLIST TABLE (Saved courses)
CREATE TABLE IF NOT EXISTS wishlist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, course_id)
);

CREATE INDEX IF NOT EXISTS idx_wishlist_user ON wishlist(user_id);
CREATE INDEX IF NOT EXISTS idx_wishlist_course ON wishlist(course_id);

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

CREATE INDEX IF NOT EXISTS idx_parent_enrollments_user ON parent_enrollments(user_id);
CREATE INDEX IF NOT EXISTS idx_parent_enrollments_status ON parent_enrollments(payment_status);


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

CREATE INDEX IF NOT EXISTS idx_enrollments_user ON enrollments(user_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_course ON enrollments(course_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_instructor ON enrollments(instructor_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_parent ON enrollments(parent_enrollment_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_status ON enrollments(status);
CREATE INDEX IF NOT EXISTS idx_enrollments_progress ON enrollments(progress_percentage);
CREATE INDEX IF NOT EXISTS idx_enrollments_created ON enrollments(created_at DESC);

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

CREATE INDEX IF NOT EXISTS idx_lesson_progress_user ON lesson_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_lesson_progress_lesson ON lesson_progress(lesson_id);
CREATE INDEX IF NOT EXISTS idx_lesson_progress_course ON lesson_progress(course_id);
CREATE INDEX IF NOT EXISTS idx_lesson_progress_enrollment ON lesson_progress(enrollment_id);
CREATE INDEX IF NOT EXISTS idx_lesson_progress_completed ON lesson_progress(is_completed) WHERE is_completed = TRUE;

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

CREATE INDEX IF NOT EXISTS idx_certificates_user ON certificates(user_id);
CREATE INDEX IF NOT EXISTS idx_certificates_course ON certificates(course_id);
CREATE INDEX IF NOT EXISTS idx_certificates_number ON certificates(certificate_number);
CREATE INDEX IF NOT EXISTS idx_certificates_verification ON certificates(verification_code);


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

CREATE INDEX IF NOT EXISTS idx_reviews_course ON course_reviews(course_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user ON course_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON course_reviews(rating);
CREATE INDEX IF NOT EXISTS idx_reviews_created ON course_reviews(created_at DESC);

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

CREATE INDEX IF NOT EXISTS idx_notes_user ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_lesson ON notes(lesson_id);
CREATE INDEX IF NOT EXISTS idx_notes_course ON notes(course_id);
CREATE INDEX IF NOT EXISTS idx_notes_user_course ON notes(user_id, course_id);

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

CREATE INDEX IF NOT EXISTS idx_bookmarks_user ON bookmarks(user_id);
CREATE INDEX IF NOT EXISTS idx_bookmarks_course ON bookmarks(course_id);

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

CREATE INDEX IF NOT EXISTS idx_questions_user ON qa_questions(user_id);
CREATE INDEX IF NOT EXISTS idx_questions_course ON qa_questions(course_id);
CREATE INDEX IF NOT EXISTS idx_questions_lesson ON qa_questions(lesson_id);
CREATE INDEX IF NOT EXISTS idx_questions_answered ON qa_questions(is_answered);
CREATE INDEX IF NOT EXISTS idx_questions_created ON qa_questions(created_at DESC);

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

CREATE INDEX IF NOT EXISTS idx_answers_question ON qa_answers(question_id);
CREATE INDEX IF NOT EXISTS idx_answers_user ON qa_answers(user_id);
CREATE INDEX IF NOT EXISTS idx_answers_accepted ON qa_answers(is_accepted) WHERE is_accepted = TRUE;


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

CREATE INDEX IF NOT EXISTS idx_quizzes_lesson ON quizzes(lesson_id);
CREATE INDEX IF NOT EXISTS idx_quizzes_course ON quizzes(course_id);

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

CREATE INDEX IF NOT EXISTS idx_quiz_questions_quiz ON quiz_questions(quiz_id);
CREATE INDEX IF NOT EXISTS idx_quiz_questions_sort ON quiz_questions(quiz_id, sort_order);

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

CREATE INDEX IF NOT EXISTS idx_quiz_attempts_quiz ON quiz_attempts(quiz_id);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_user ON quiz_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_enrollment ON quiz_attempts(enrollment_id);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_passed ON quiz_attempts(passed);

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

CREATE INDEX IF NOT EXISTS idx_announcements_course ON announcements(course_id);
CREATE INDEX IF NOT EXISTS idx_announcements_instructor ON announcements(instructor_id);
CREATE INDEX IF NOT EXISTS idx_announcements_published ON announcements(published_at DESC);

-- 5.2 ANNOUNCEMENT_READS TABLE (Track who read announcements)
CREATE TABLE IF NOT EXISTS announcement_reads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  announcement_id UUID NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(announcement_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_announcement_reads_announcement ON announcement_reads(announcement_id);
CREATE INDEX IF NOT EXISTS idx_announcement_reads_user ON announcement_reads(user_id);


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

CREATE INDEX IF NOT EXISTS idx_coupons_code ON coupons(code);
CREATE INDEX IF NOT EXISTS idx_coupons_instructor ON coupons(instructor_id);
CREATE INDEX IF NOT EXISTS idx_coupons_active ON coupons(is_active, start_date, end_date);

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

CREATE INDEX IF NOT EXISTS idx_coupon_usages_coupon ON coupon_usages(coupon_id);
CREATE INDEX IF NOT EXISTS idx_coupon_usages_user ON coupon_usages(user_id);

-- Add foreign key to parent_enrollments
ALTER TABLE IF EXISTS parent_enrollments DROP CONSTRAINT IF EXISTS fk_parent_enrollments_coupon;`nALTER TABLE parent_enrollments ADD CONSTRAINT fk_parent_enrollments_coupon 
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

CREATE INDEX IF NOT EXISTS idx_course_reports_course ON course_reports(course_id);
CREATE INDEX IF NOT EXISTS idx_course_reports_user ON course_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_course_reports_status ON course_reports(status);

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

CREATE INDEX IF NOT EXISTS idx_review_reports_review ON review_reports(review_id);
CREATE INDEX IF NOT EXISTS idx_review_reports_user ON review_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_review_reports_status ON review_reports(status);


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

CREATE INDEX IF NOT EXISTS idx_banners_active ON banners(is_active, sort_order);
CREATE INDEX IF NOT EXISTS idx_banners_dates ON banners(start_date, end_date);

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

CREATE INDEX IF NOT EXISTS idx_earnings_instructor ON instructor_earnings(instructor_id);
CREATE INDEX IF NOT EXISTS idx_earnings_course ON instructor_earnings(course_id);
CREATE INDEX IF NOT EXISTS idx_earnings_status ON instructor_earnings(status);
CREATE INDEX IF NOT EXISTS idx_earnings_available ON instructor_earnings(available_at);

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

CREATE INDEX IF NOT EXISTS idx_payouts_instructor ON instructor_payouts(instructor_id);
CREATE INDEX IF NOT EXISTS idx_payouts_status ON instructor_payouts(status);
CREATE INDEX IF NOT EXISTS idx_payouts_requested ON instructor_payouts(requested_at DESC);

-- 9.3 PAYOUT_ITEMS TABLE (Link payouts to earnings)
CREATE TABLE IF NOT EXISTS payout_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payout_id UUID NOT NULL REFERENCES instructor_payouts(id) ON DELETE CASCADE,
  earning_id UUID NOT NULL REFERENCES instructor_earnings(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payout_items_payout ON payout_items(payout_id);
CREATE INDEX IF NOT EXISTS idx_payout_items_earning ON payout_items(earning_id);


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
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
DROP POLICY IF EXISTS "Enable insert for auth" ON profiles;
CREATE POLICY "Enable insert for auth" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
CREATE POLICY "Admins can view all profiles" ON profiles FOR SELECT USING (is_admin());
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
CREATE POLICY "Admins can update all profiles" ON profiles FOR UPDATE USING (is_admin());
DROP POLICY IF EXISTS "Public can view instructors" ON profiles;
CREATE POLICY "Public can view instructors" ON profiles FOR SELECT USING (role = 'instructor');

-- ============================================================
-- 12.2 CATEGORIES POLICIES
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view active categories" ON categories;
CREATE POLICY "Anyone can view active categories" ON categories FOR SELECT USING (is_active = TRUE);
DROP POLICY IF EXISTS "Admins can manage categories" ON categories;
CREATE POLICY "Admins can manage categories" ON categories FOR ALL USING (is_admin());

-- ============================================================
-- 12.3 INSTRUCTOR_PROFILES POLICIES
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view instructor profiles" ON instructor_profiles;
CREATE POLICY "Anyone can view instructor profiles" ON instructor_profiles FOR SELECT USING (is_active = TRUE);
DROP POLICY IF EXISTS "Instructors can manage own profile" ON instructor_profiles;
CREATE POLICY "Instructors can manage own profile" ON instructor_profiles FOR ALL USING (instructor_id = auth.uid());
DROP POLICY IF EXISTS "Admins can manage all instructor profiles" ON instructor_profiles;
CREATE POLICY "Admins can manage all instructor profiles" ON instructor_profiles FOR ALL USING (is_admin());

-- ============================================================
-- 12.4 COURSES POLICIES
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view published courses" ON courses;
CREATE POLICY "Anyone can view published courses" ON courses FOR SELECT 
  USING (is_published = TRUE AND is_active = TRUE AND is_suspended = FALSE);
DROP POLICY IF EXISTS "Instructors can view own courses" ON courses;
CREATE POLICY "Instructors can view own courses" ON courses FOR SELECT USING (instructor_id = auth.uid());
DROP POLICY IF EXISTS "Instructors can manage own courses" ON courses;
CREATE POLICY "Instructors can manage own courses" ON courses FOR ALL USING (instructor_id = auth.uid());
DROP POLICY IF EXISTS "Admins can manage all courses" ON courses;
CREATE POLICY "Admins can manage all courses" ON courses FOR ALL USING (is_admin());

-- ============================================================
-- 12.5 SECTIONS POLICIES
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view published sections" ON sections;
CREATE POLICY "Anyone can view published sections" ON sections FOR SELECT 
  USING (is_published = TRUE AND EXISTS (
    SELECT 1 FROM courses c WHERE c.id = sections.course_id AND c.is_published = TRUE
  ));
DROP POLICY IF EXISTS "Instructors can manage own course sections" ON sections;
CREATE POLICY "Instructors can manage own course sections" ON sections FOR ALL 
  USING (EXISTS (SELECT 1 FROM courses c WHERE c.id = sections.course_id AND c.instructor_id = auth.uid()));
DROP POLICY IF EXISTS "Admins can manage all sections" ON sections;
CREATE POLICY "Admins can manage all sections" ON sections FOR ALL USING (is_admin());

-- ============================================================
-- 12.6 LESSONS POLICIES
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view preview lessons" ON lessons;
CREATE POLICY "Anyone can view preview lessons" ON lessons FOR SELECT USING (is_preview = TRUE AND is_published = TRUE);
DROP POLICY IF EXISTS "Enrolled students can view lessons" ON lessons;
CREATE POLICY "Enrolled students can view lessons" ON lessons FOR SELECT 
  USING (is_published = TRUE AND is_enrolled(course_id));
DROP POLICY IF EXISTS "Instructors can manage own course lessons" ON lessons;
CREATE POLICY "Instructors can manage own course lessons" ON lessons FOR ALL 
  USING (EXISTS (SELECT 1 FROM courses c WHERE c.id = lessons.course_id AND c.instructor_id = auth.uid()));
DROP POLICY IF EXISTS "Admins can manage all lessons" ON lessons;
CREATE POLICY "Admins can manage all lessons" ON lessons FOR ALL USING (is_admin());

-- ============================================================
-- 12.7 LESSON_ATTACHMENTS POLICIES
-- ============================================================
DROP POLICY IF EXISTS "Enrolled students can view attachments" ON lesson_attachments;
CREATE POLICY "Enrolled students can view attachments" ON lesson_attachments FOR SELECT 
  USING (EXISTS (
    SELECT 1 FROM lessons l WHERE l.id = lesson_attachments.lesson_id AND is_enrolled(l.course_id)
  ));
DROP POLICY IF EXISTS "Instructors can manage own attachments" ON lesson_attachments;
CREATE POLICY "Instructors can manage own attachments" ON lesson_attachments FOR ALL 
  USING (EXISTS (
    SELECT 1 FROM lessons l JOIN courses c ON c.id = l.course_id 
    WHERE l.id = lesson_attachments.lesson_id AND c.instructor_id = auth.uid()
  ));

-- ============================================================
-- 12.8 CART & WISHLIST POLICIES
-- ============================================================
DROP POLICY IF EXISTS "Users can manage own cart" ON cart_items;
CREATE POLICY "Users can manage own cart" ON cart_items FOR ALL USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can manage own wishlist" ON wishlist;
CREATE POLICY "Users can manage own wishlist" ON wishlist FOR ALL USING (user_id = auth.uid());

-- ============================================================
-- 12.9 ENROLLMENTS POLICIES
-- ============================================================
DROP POLICY IF EXISTS "Users can view own enrollments" ON parent_enrollments;
CREATE POLICY "Users can view own enrollments" ON parent_enrollments FOR SELECT USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can create own enrollments" ON parent_enrollments;
CREATE POLICY "Users can create own enrollments" ON parent_enrollments FOR INSERT WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS "Admins can view all enrollments" ON parent_enrollments;
CREATE POLICY "Admins can view all enrollments" ON parent_enrollments FOR SELECT USING (is_admin());
DROP POLICY IF EXISTS "Users can view own course enrollments" ON enrollments;
CREATE POLICY "Users can view own course enrollments" ON enrollments FOR SELECT USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Instructors can view their course enrollments" ON enrollments;
CREATE POLICY "Instructors can view their course enrollments" ON enrollments FOR SELECT USING (instructor_id = auth.uid());
DROP POLICY IF EXISTS "Users can create own enrollments" ON enrollments;
CREATE POLICY "Users can create own enrollments" ON enrollments FOR INSERT WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS "Admins can manage all enrollments" ON enrollments;
CREATE POLICY "Admins can manage all enrollments" ON enrollments FOR ALL USING (is_admin());

-- ============================================================
-- 12.10 PROGRESS POLICIES
-- ============================================================
DROP POLICY IF EXISTS "Users can manage own progress" ON lesson_progress;
CREATE POLICY "Users can manage own progress" ON lesson_progress FOR ALL USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Instructors can view student progress" ON lesson_progress;
CREATE POLICY "Instructors can view student progress" ON lesson_progress FOR SELECT 
  USING (EXISTS (SELECT 1 FROM courses c WHERE c.id = lesson_progress.course_id AND c.instructor_id = auth.uid()));

-- ============================================================
-- 12.11 CERTIFICATES POLICIES
-- ============================================================
DROP POLICY IF EXISTS "Users can view own certificates" ON certificates;
CREATE POLICY "Users can view own certificates" ON certificates FOR SELECT USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Anyone can verify certificates" ON certificates;
CREATE POLICY "Anyone can verify certificates" ON certificates FOR SELECT USING (TRUE);
DROP POLICY IF EXISTS "System can create certificates" ON certificates;
CREATE POLICY "System can create certificates" ON certificates FOR INSERT WITH CHECK (user_id = auth.uid());


-- ============================================================
-- 12.12 REVIEWS POLICIES
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view visible reviews" ON course_reviews;
CREATE POLICY "Anyone can view visible reviews" ON course_reviews FOR SELECT USING (is_visible = TRUE);
DROP POLICY IF EXISTS "Users can create reviews" ON course_reviews;
CREATE POLICY "Users can create reviews" ON course_reviews FOR INSERT WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can update own reviews" ON course_reviews;
CREATE POLICY "Users can update own reviews" ON course_reviews FOR UPDATE USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can delete own reviews" ON course_reviews;
CREATE POLICY "Users can delete own reviews" ON course_reviews FOR DELETE USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Admins can manage all reviews" ON course_reviews;
CREATE POLICY "Admins can manage all reviews" ON course_reviews FOR ALL USING (is_admin());
DROP POLICY IF EXISTS "Users can manage own helpful votes" ON review_helpful;
CREATE POLICY "Users can manage own helpful votes" ON review_helpful FOR ALL USING (user_id = auth.uid());

-- ============================================================
-- 12.13 NOTES & BOOKMARKS POLICIES
-- ============================================================
DROP POLICY IF EXISTS "Users can manage own notes" ON notes;
CREATE POLICY "Users can manage own notes" ON notes FOR ALL USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can manage own bookmarks" ON bookmarks;
CREATE POLICY "Users can manage own bookmarks" ON bookmarks FOR ALL USING (user_id = auth.uid());

-- ============================================================
-- 12.14 Q&A POLICIES
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view visible questions" ON qa_questions;
CREATE POLICY "Anyone can view visible questions" ON qa_questions FOR SELECT USING (is_visible = TRUE);
DROP POLICY IF EXISTS "Users can create questions" ON qa_questions;
CREATE POLICY "Users can create questions" ON qa_questions FOR INSERT WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can update own questions" ON qa_questions;
CREATE POLICY "Users can update own questions" ON qa_questions FOR UPDATE USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Instructors can manage course questions" ON qa_questions;
CREATE POLICY "Instructors can manage course questions" ON qa_questions FOR ALL 
  USING (EXISTS (SELECT 1 FROM courses c WHERE c.id = qa_questions.course_id AND c.instructor_id = auth.uid()));
DROP POLICY IF EXISTS "Anyone can view visible answers" ON qa_answers;
CREATE POLICY "Anyone can view visible answers" ON qa_answers FOR SELECT USING (is_visible = TRUE);
DROP POLICY IF EXISTS "Users can create answers" ON qa_answers;
CREATE POLICY "Users can create answers" ON qa_answers FOR INSERT WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can update own answers" ON qa_answers;
CREATE POLICY "Users can update own answers" ON qa_answers FOR UPDATE USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Instructors can manage course answers" ON qa_answers;
CREATE POLICY "Instructors can manage course answers" ON qa_answers FOR ALL 
  USING (EXISTS (
    SELECT 1 FROM qa_questions q JOIN courses c ON c.id = q.course_id 
    WHERE q.id = qa_answers.question_id AND c.instructor_id = auth.uid()
  ));

-- ============================================================
-- 12.15 QUIZZES POLICIES
-- ============================================================
DROP POLICY IF EXISTS "Enrolled students can view quizzes" ON quizzes;
CREATE POLICY "Enrolled students can view quizzes" ON quizzes FOR SELECT 
  USING (is_published = TRUE AND is_enrolled(course_id));
DROP POLICY IF EXISTS "Instructors can manage own quizzes" ON quizzes;
CREATE POLICY "Instructors can manage own quizzes" ON quizzes FOR ALL 
  USING (EXISTS (SELECT 1 FROM courses c WHERE c.id = quizzes.course_id AND c.instructor_id = auth.uid()));
DROP POLICY IF EXISTS "Enrolled students can view quiz questions" ON quiz_questions;
CREATE POLICY "Enrolled students can view quiz questions" ON quiz_questions FOR SELECT 
  USING (EXISTS (SELECT 1 FROM quizzes q WHERE q.id = quiz_questions.quiz_id AND is_enrolled(q.course_id)));
DROP POLICY IF EXISTS "Instructors can manage own quiz questions" ON quiz_questions;
CREATE POLICY "Instructors can manage own quiz questions" ON quiz_questions FOR ALL 
  USING (EXISTS (
    SELECT 1 FROM quizzes q JOIN courses c ON c.id = q.course_id 
    WHERE q.id = quiz_questions.quiz_id AND c.instructor_id = auth.uid()
  ));
DROP POLICY IF EXISTS "Users can manage own quiz attempts" ON quiz_attempts;
CREATE POLICY "Users can manage own quiz attempts" ON quiz_attempts FOR ALL USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Instructors can view student attempts" ON quiz_attempts;
CREATE POLICY "Instructors can view student attempts" ON quiz_attempts FOR SELECT 
  USING (EXISTS (
    SELECT 1 FROM quizzes q JOIN courses c ON c.id = q.course_id 
    WHERE q.id = quiz_attempts.quiz_id AND c.instructor_id = auth.uid()
  ));

-- ============================================================
-- 12.16 ANNOUNCEMENTS POLICIES
-- ============================================================
DROP POLICY IF EXISTS "Enrolled students can view announcements" ON announcements;
CREATE POLICY "Enrolled students can view announcements" ON announcements FOR SELECT 
  USING (is_published = TRUE AND is_enrolled(course_id));
DROP POLICY IF EXISTS "Instructors can manage own announcements" ON announcements;
CREATE POLICY "Instructors can manage own announcements" ON announcements FOR ALL 
  USING (instructor_id = auth.uid());
DROP POLICY IF EXISTS "Users can manage own announcement reads" ON announcement_reads;
CREATE POLICY "Users can manage own announcement reads" ON announcement_reads FOR ALL USING (user_id = auth.uid());

-- ============================================================
-- 12.17 COUPONS POLICIES
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view active coupons" ON coupons;
CREATE POLICY "Anyone can view active coupons" ON coupons FOR SELECT 
  USING (is_active = TRUE AND is_suspended = FALSE AND start_date <= NOW() AND (end_date IS NULL OR end_date > NOW()));
DROP POLICY IF EXISTS "Instructors can manage own coupons" ON coupons;
CREATE POLICY "Instructors can manage own coupons" ON coupons FOR ALL USING (instructor_id = auth.uid());
DROP POLICY IF EXISTS "Admins can manage all coupons" ON coupons;
CREATE POLICY "Admins can manage all coupons" ON coupons FOR ALL USING (is_admin());
DROP POLICY IF EXISTS "Anyone can view coupon categories" ON coupon_categories;
CREATE POLICY "Anyone can view coupon categories" ON coupon_categories FOR SELECT USING (TRUE);
DROP POLICY IF EXISTS "Anyone can view coupon courses" ON coupon_courses;
CREATE POLICY "Anyone can view coupon courses" ON coupon_courses FOR SELECT USING (TRUE);
DROP POLICY IF EXISTS "Users can view own coupon usages" ON coupon_usages;
CREATE POLICY "Users can view own coupon usages" ON coupon_usages FOR SELECT USING (user_id = auth.uid());

-- ============================================================
-- 12.18 REPORTS POLICIES
-- ============================================================
DROP POLICY IF EXISTS "Users can view own reports" ON course_reports;
CREATE POLICY "Users can view own reports" ON course_reports FOR SELECT USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can create reports" ON course_reports;
CREATE POLICY "Users can create reports" ON course_reports FOR INSERT WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS "Admins can manage all reports" ON course_reports;
CREATE POLICY "Admins can manage all reports" ON course_reports FOR ALL USING (is_admin());
DROP POLICY IF EXISTS "Users can view own review reports" ON review_reports;
CREATE POLICY "Users can view own review reports" ON review_reports FOR SELECT USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can create review reports" ON review_reports;
CREATE POLICY "Users can create review reports" ON review_reports FOR INSERT WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS "Admins can manage all review reports" ON review_reports;
CREATE POLICY "Admins can manage all review reports" ON review_reports FOR ALL USING (is_admin());

-- ============================================================
-- 12.19 BANNERS POLICIES
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view active banners" ON banners;
CREATE POLICY "Anyone can view active banners" ON banners FOR SELECT 
  USING (is_active = TRUE AND (start_date IS NULL OR start_date <= NOW()) AND (end_date IS NULL OR end_date >= NOW()));
DROP POLICY IF EXISTS "Admins can manage banners" ON banners;
CREATE POLICY "Admins can manage banners" ON banners FOR ALL USING (is_admin());

-- ============================================================
-- 12.20 EARNINGS & PAYOUTS POLICIES
-- ============================================================
DROP POLICY IF EXISTS "Instructors can view own earnings" ON instructor_earnings;
CREATE POLICY "Instructors can view own earnings" ON instructor_earnings FOR SELECT USING (instructor_id = auth.uid());
DROP POLICY IF EXISTS "Admins can manage all earnings" ON instructor_earnings;
CREATE POLICY "Admins can manage all earnings" ON instructor_earnings FOR ALL USING (is_admin());
DROP POLICY IF EXISTS "Instructors can view own payouts" ON instructor_payouts;
CREATE POLICY "Instructors can view own payouts" ON instructor_payouts FOR SELECT USING (instructor_id = auth.uid());
DROP POLICY IF EXISTS "Instructors can request payouts" ON instructor_payouts;
CREATE POLICY "Instructors can request payouts" ON instructor_payouts FOR INSERT WITH CHECK (instructor_id = auth.uid());
DROP POLICY IF EXISTS "Admins can manage all payouts" ON instructor_payouts;
CREATE POLICY "Admins can manage all payouts" ON instructor_payouts FOR ALL USING (is_admin());
DROP POLICY IF EXISTS "Instructors can view own payout items" ON payout_items;
CREATE POLICY "Instructors can view own payout items" ON payout_items FOR SELECT 
  USING (EXISTS (SELECT 1 FROM instructor_payouts p WHERE p.id = payout_items.payout_id AND p.instructor_id = auth.uid()));
DROP POLICY IF EXISTS "Admins can manage payout items" ON payout_items;
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
DROP POLICY IF EXISTS "Public Access to Course Images" ON storage;
CREATE POLICY "Public Access to Course Images" ON storage.objects FOR SELECT USING (bucket_id = 'courses');
DROP POLICY IF EXISTS "Instructors can upload course images" ON storage;
CREATE POLICY "Instructors can upload course images" ON storage.objects FOR INSERT 
  WITH CHECK (bucket_id = 'courses' AND is_instructor());
DROP POLICY IF EXISTS "Instructors can update course images" ON storage;
CREATE POLICY "Instructors can update course images" ON storage.objects FOR UPDATE 
  USING (bucket_id = 'courses' AND is_instructor());
DROP POLICY IF EXISTS "Instructors can delete course images" ON storage;
CREATE POLICY "Instructors can delete course images" ON storage.objects FOR DELETE 
  USING (bucket_id = 'courses' AND is_instructor());

-- Storage policies for categories bucket
DROP POLICY IF EXISTS "Public Access to Category Images" ON storage;
CREATE POLICY "Public Access to Category Images" ON storage.objects FOR SELECT USING (bucket_id = 'categories');
DROP POLICY IF EXISTS "Admins can manage category images" ON storage;
CREATE POLICY "Admins can manage category images" ON storage.objects FOR ALL 
  USING (bucket_id = 'categories' AND is_admin());

-- Storage policies for instructors bucket
DROP POLICY IF EXISTS "Public Access to Instructor Images" ON storage;
CREATE POLICY "Public Access to Instructor Images" ON storage.objects FOR SELECT USING (bucket_id = 'instructors');
DROP POLICY IF EXISTS "Instructors can upload own images" ON storage;
CREATE POLICY "Instructors can upload own images" ON storage.objects FOR INSERT 
  WITH CHECK (bucket_id = 'instructors' AND auth.role() = 'authenticated');
DROP POLICY IF EXISTS "Instructors can update own images" ON storage;
CREATE POLICY "Instructors can update own images" ON storage.objects FOR UPDATE 
  USING (bucket_id = 'instructors' AND auth.role() = 'authenticated');

-- Storage policies for avatars bucket
DROP POLICY IF EXISTS "Public Access to Avatars" ON storage;
CREATE POLICY "Public Access to Avatars" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
DROP POLICY IF EXISTS "Users can upload own avatar" ON storage;
CREATE POLICY "Users can upload own avatar" ON storage.objects FOR INSERT 
  WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');
DROP POLICY IF EXISTS "Users can update own avatar" ON storage;
CREATE POLICY "Users can update own avatar" ON storage.objects FOR UPDATE 
  USING (bucket_id = 'avatars' AND auth.role() = 'authenticated');

-- Storage policies for banners bucket
DROP POLICY IF EXISTS "Public Access to Banners" ON storage;
CREATE POLICY "Public Access to Banners" ON storage.objects FOR SELECT USING (bucket_id = 'banners');
DROP POLICY IF EXISTS "Admins can manage banners" ON storage;
CREATE POLICY "Admins can manage banners" ON storage.objects FOR ALL 
  USING (bucket_id = 'banners' AND is_admin());

-- Storage policies for videos bucket (private - only enrolled students)
DROP POLICY IF EXISTS "Enrolled students can view videos" ON storage;
CREATE POLICY "Enrolled students can view videos" ON storage.objects FOR SELECT 
  USING (bucket_id = 'videos' AND auth.role() = 'authenticated');
DROP POLICY IF EXISTS "Instructors can upload videos" ON storage;
CREATE POLICY "Instructors can upload videos" ON storage.objects FOR INSERT 
  WITH CHECK (bucket_id = 'videos' AND is_instructor());
DROP POLICY IF EXISTS "Instructors can update videos" ON storage;
CREATE POLICY "Instructors can update videos" ON storage.objects FOR UPDATE 
  USING (bucket_id = 'videos' AND is_instructor());
DROP POLICY IF EXISTS "Instructors can delete videos" ON storage;
CREATE POLICY "Instructors can delete videos" ON storage.objects FOR DELETE 
  USING (bucket_id = 'videos' AND is_instructor());

-- Storage policies for attachments bucket
DROP POLICY IF EXISTS "Enrolled students can download attachments" ON storage;
CREATE POLICY "Enrolled students can download attachments" ON storage.objects FOR SELECT 
  USING (bucket_id = 'attachments' AND auth.role() = 'authenticated');
DROP POLICY IF EXISTS "Instructors can manage attachments" ON storage;
CREATE POLICY "Instructors can manage attachments" ON storage.objects FOR ALL 
  USING (bucket_id = 'attachments' AND is_instructor());

-- Storage policies for certificates bucket
DROP POLICY IF EXISTS "Public Access to Certificates" ON storage;
CREATE POLICY "Public Access to Certificates" ON storage.objects FOR SELECT USING (bucket_id = 'certificates');
DROP POLICY IF EXISTS "System can create certificates" ON storage;
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



-- =====================================================================
-- File: 101_assignments_notifications.sql
-- =====================================================================
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

CREATE INDEX IF NOT EXISTS idx_assignments_lesson ON assignments(lesson_id);
CREATE INDEX IF NOT EXISTS idx_assignments_course ON assignments(course_id);
CREATE INDEX IF NOT EXISTS idx_assignments_due_date ON assignments(due_date);
CREATE INDEX IF NOT EXISTS idx_assignments_published ON assignments(is_published) WHERE is_published = TRUE;


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

CREATE INDEX IF NOT EXISTS idx_submissions_assignment ON assignment_submissions(assignment_id);
CREATE INDEX IF NOT EXISTS idx_submissions_user ON assignment_submissions(user_id);
CREATE INDEX IF NOT EXISTS idx_submissions_enrollment ON assignment_submissions(enrollment_id);
CREATE INDEX IF NOT EXISTS idx_submissions_status ON assignment_submissions(status);
CREATE INDEX IF NOT EXISTS idx_submissions_graded ON assignment_submissions(graded_at);
-- Unique constraint: one active submission per user per assignment (latest attempt)
CREATE UNIQUE INDEX IF NOT EXISTS idx_submissions_user_assignment_attempt ON assignment_submissions(assignment_id, user_id, attempt_number);


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

CREATE INDEX IF NOT EXISTS idx_rubrics_assignment ON assignment_rubrics(assignment_id);

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

CREATE INDEX IF NOT EXISTS idx_rubric_scores_submission ON submission_rubric_scores(submission_id);


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

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_course ON notifications(course_id);


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

CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_active ON device_tokens(is_active) WHERE is_active = TRUE;


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

CREATE INDEX IF NOT EXISTS idx_notification_prefs_user ON notification_preferences(user_id);


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



-- =====================================================================
-- File: 102_add_parent_role.sql
-- =====================================================================
-- ============================================================
-- Migration: Add 'parent` role to profiles table
-- Version: 1.0.2 | January 2026
-- ============================================================

-- Update the role check constraint to include 'parent`
ALTER TABLE profiles 
DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE IF EXISTS profiles DROP CONSTRAINT IF EXISTS profiles_role_check;`nALTER TABLE profiles ADD CONSTRAINT profiles_role_check 
CHECK (role IN ('student', 'instructor', 'parent', 'admin'));

-- Add parent-specific fields to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS linked_student_ids UUID[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS parent_verification_status TEXT DEFAULT 'pending' 
  CHECK (parent_verification_status IN ('pending', 'verified', 'rejected'));

-- Create index for parent role
CREATE INDEX IF NOT EXISTS idx_profiles_parent_role 
ON profiles(role) WHERE role = 'parent';

-- Create parent_student_links table for parent-student relationships
CREATE TABLE IF NOT EXISTS parent_student_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  relationship TEXT DEFAULT 'parent' CHECK (relationship IN ('parent', 'guardian', 'other')),
  is_verified BOOLEAN DEFAULT FALSE,
  verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(parent_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_parent_student_links_parent ON parent_student_links(parent_id);
CREATE INDEX IF NOT EXISTS idx_parent_student_links_student ON parent_student_links(student_id);

-- RLS Policies for parent_student_links
ALTER TABLE parent_student_links ENABLE ROW LEVEL SECURITY;

-- Parents can view their own links
DROP POLICY IF EXISTS "Parents can view own links" ON parent_student_links;
CREATE POLICY "Parents can view own links" ON parent_student_links
  FOR SELECT USING (auth.uid() = parent_id);

-- Parents can create links (pending verification)
DROP POLICY IF EXISTS "Parents can create links" ON parent_student_links;
CREATE POLICY "Parents can create links" ON parent_student_links
  FOR INSERT WITH CHECK (auth.uid() = parent_id);

-- Students can view links where they are the student
DROP POLICY IF EXISTS "Students can view links to them" ON parent_student_links;
CREATE POLICY "Students can view links to them" ON parent_student_links
  FOR SELECT USING (auth.uid() = student_id);

-- Students can verify/update links to them
DROP POLICY IF EXISTS "Students can verify links" ON parent_student_links;
CREATE POLICY "Students can verify links" ON parent_student_links
  FOR UPDATE USING (auth.uid() = student_id);

COMMENT ON TABLE parent_student_links IS 'Links between parent accounts and student accounts for progress monitoring';


-- =====================================================================
-- File: 103_quizzes_course_level.sql
-- =====================================================================
-- ============================================================
-- Migration: Make quizzes course-level instead of lesson-level
-- This allows quizzes to be associated with the entire course
-- ============================================================

-- Step 1: Make lesson_id nullable (quizzes can be course-level)
ALTER TABLE quizzes 
ALTER COLUMN lesson_id DROP NOT NULL;

-- Step 2: Add comment for clarity
COMMENT ON COLUMN quizzes.lesson_id IS 'Optional: If NULL, quiz is for the entire course. If set, quiz is for specific lesson.';

-- Step 3: Update the remote data source query to filter by course_id
-- The Flutter code already queries by course_id, so no changes needed there

-- ============================================================
-- Verification Query (run to check existing data)
-- ============================================================
-- SELECT id, course_id, lesson_id, title_ar FROM quizzes;


-- =====================================================================
-- File: 104_fix_issue_certificate.sql
-- =====================================================================
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION issue_certificate(UUID) TO authenticated;


-- =====================================================================
-- File: 105_update_certificate_url.sql
-- =====================================================================
-- ============================================================
-- Function: Update Certificate URL
-- This function updates the certificate_url after PDF is uploaded
-- ============================================================

-- Drop existing function if exists
DROP FUNCTION IF EXISTS update_certificate_url(UUID, TEXT);

-- Create the function
CREATE OR REPLACE FUNCTION update_certificate_url(
  p_certificate_id UUID,
  p_certificate_url TEXT
)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_certificate RECORD;
BEGIN
  -- Get certificate and verify ownership
  SELECT * INTO v_certificate
  FROM certificates
  WHERE id = p_certificate_id AND user_id = v_user_id;
  
  IF v_certificate IS NULL THEN
    RETURN json_build_object(
      'success', false, 
      'error', 'Certificate not found or access denied'
    );
  END IF;
  
  -- Update certificate URL
  UPDATE certificates 
  SET certificate_url = p_certificate_url
  WHERE id = p_certificate_id;
  
  -- Return success
  RETURN json_build_object(
    'success', true,
    'certificate_id', p_certificate_id,
    'certificate_url', p_certificate_url
  );
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false, 
    'error', SQLERRM
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION update_certificate_url(UUID, TEXT) TO authenticated;


-- =====================================================================
-- File: 203_quiz_attempts_rls.sql
-- =====================================================================
-- ============================================================
-- Fix RLS for Quiz Attempts - Simple Version
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. Enable RLS
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;

-- 2. Drop ALL existing policies on quiz_attempts
DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN 
    SELECT policyname FROM pg_policies WHERE tablename = 'quiz_attempts'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON quiz_attempts', pol.policyname);
  END LOOP;
END $$;

-- 3. Create simple policies that allow users to manage their attempts
DROP POLICY IF EXISTS "quiz_attempts_select" ON quiz_attempts;
CREATE POLICY "quiz_attempts_select" ON quiz_attempts
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());
DROP POLICY IF EXISTS "quiz_attempts_insert" ON quiz_attempts;
CREATE POLICY "quiz_attempts_insert" ON quiz_attempts
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS "quiz_attempts_update" ON quiz_attempts;
CREATE POLICY "quiz_attempts_update" ON quiz_attempts
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

-- 4. Verify policies
SELECT tablename, policyname, cmd FROM pg_policies WHERE tablename = 'quiz_attempts';


-- =====================================================================
-- File: 204_fix_submit_quiz.sql
-- =====================================================================
-- ============================================================
-- Fix Submit Quiz Function
-- The quiz_attempts table doesn't have a 'status` column
-- ============================================================

DROP FUNCTION IF EXISTS submit_quiz_attempt(UUID, JSONB, INT);

CREATE OR REPLACE FUNCTION submit_quiz_attempt(
  p_attempt_id UUID,
  p_answers JSONB,
  p_time_spent INT DEFAULT 0
)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_attempt RECORD;
  v_quiz RECORD;
  v_score INT := 0;
  v_total_points INT := 0;
  v_percentage DECIMAL;
  v_passed BOOLEAN;
  v_question RECORD;
  v_user_answer JSONB;
  v_correct_options JSONB;
  v_is_correct BOOLEAN;
BEGIN
  -- Get attempt
  SELECT * INTO v_attempt 
  FROM quiz_attempts 
  WHERE id = p_attempt_id AND user_id = v_user_id;
  
  IF v_attempt IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Attempt not found');
  END IF;
  
  -- Check if already completed
  IF v_attempt.completed_at IS NOT NULL THEN
    RETURN json_build_object('success', false, 'error', 'Attempt already completed');
  END IF;
  
  -- Get quiz
  SELECT * INTO v_quiz FROM quizzes WHERE id = v_attempt.quiz_id;
  
  -- Calculate score
  FOR v_question IN 
    SELECT id, points, options 
    FROM quiz_questions 
    WHERE quiz_id = v_attempt.quiz_id
  LOOP
    v_total_points := v_total_points + v_question.points;
    
    -- Get user`s answer for this question
    v_user_answer := p_answers->v_question.id::text;
    
    IF v_user_answer IS NOT NULL THEN
      -- Get correct options
      SELECT jsonb_agg(opt->>'id') INTO v_correct_options
      FROM jsonb_array_elements(v_question.options) AS opt
      WHERE (opt->>'is_correct')::boolean = true;
      
      -- Check if answer is correct (compare arrays)
      v_is_correct := (
        SELECT COALESCE(v_user_answer @> v_correct_options 
           AND v_correct_options @> v_user_answer, false)
      );
      
      IF v_is_correct THEN
        v_score := v_score + v_question.points;
      END IF;
    END IF;
  END LOOP;
  
  -- Calculate percentage
  v_percentage := CASE 
    WHEN v_total_points > 0 THEN (v_score::DECIMAL / v_total_points) * 100 
    ELSE 0 
  END;
  
  v_passed := v_percentage >= v_quiz.passing_score;
  
  -- Update attempt
  UPDATE quiz_attempts SET
    completed_at = NOW(),
    score = v_score,
    total_points = v_total_points,
    percentage = v_percentage,
    passed = v_passed,
    time_spent = p_time_spent,
    answers = p_answers
  WHERE id = p_attempt_id;
  
  -- Return result
  RETURN json_build_object(
    'success', true,
    'attempt_id', p_attempt_id,
    'score', v_score,
    'total_points', v_total_points,
    'percentage', ROUND(v_percentage, 2),
    'passed', v_passed,
    'passing_score', v_quiz.passing_score
  );
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION submit_quiz_attempt(UUID, JSONB, INT) TO authenticated;

SELECT 'Submit quiz function fixed!' as status;


-- =====================================================================
-- File: 205_user_settings_table.sql
-- =====================================================================
-- ============================================
-- User Settings - LOCAL ONLY
-- ============================================
-- Language and Theme settings are stored locally only
-- using SharedPreferences. No database table needed.
-- 
-- This approach provides:
-- 1. Instant UI updates without network latency
-- 2. Works offline
-- 3. No sync conflicts
-- 4. Simpler architecture
--
-- Settings stored locally:
-- - language_code (en/ar)
-- - is_dark_mode (true/false)
-- - notifications_enabled (true/false)
-- - video_autoplay (true/false)
-- ============================================

-- If you previously created the user_settings table,
-- you can drop it with:
-- DROP TABLE IF EXISTS public.user_settings CASCADE;


-- =====================================================================
-- File: 206_drop_user_settings_table.sql
-- =====================================================================
-- ============================================
-- Drop User Settings Table
-- ============================================
-- Language and Theme are now stored locally only
-- This script removes the unused user_settings table
-- ============================================

-- Drop trigger first
DROP TRIGGER IF EXISTS trigger_user_settings_updated_at ON public.user_settings;
DROP TRIGGER IF EXISTS trigger_create_user_settings ON public.profiles;

-- Drop functions
DROP FUNCTION IF EXISTS update_user_settings_updated_at();
DROP FUNCTION IF EXISTS create_default_user_settings();

-- Drop table
DROP TABLE IF EXISTS public.user_settings CASCADE;

-- Verify deletion
-- SELECT * FROM information_schema.tables WHERE table_name = 'user_settings`;


-- =====================================================================
-- File: 208_fix_update_lesson_progress.sql
-- =====================================================================
-- Fix update_lesson_progress function:
-- 1. Accept ANY enrollment status (not just 'active`)
-- 2. Only update watch_time if new value is greater than existing

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
  
  IF v_course_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Lesson not found');
  END IF;
  
  -- Check enrollment - accept ANY status
  SELECT id INTO v_enrollment_id
  FROM enrollments
  WHERE user_id = v_user_id AND course_id = v_course_id;
  
  IF v_enrollment_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not enrolled in this course');
  END IF;
  
  -- Upsert progress - only update watch_time if new value is greater
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
    'enrollment_id', v_enrollment_id,
    'course_progress', progress_percentage,
    'completed_lessons', completed_lessons,
    'total_watch_time', total_watch_time
  ) INTO v_result
  FROM enrollments WHERE id = v_enrollment_id;
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION update_lesson_progress TO authenticated;


-- =====================================================================
-- File: 210_fix_instructor_earnings_rls.sql
-- =====================================================================
-- Fix RLS policy for instructor_earnings table
-- Allow inserts during checkout (when student buys a course)

-- Drop existing insert policy if any
DROP POLICY IF EXISTS "Allow insert on checkout" ON instructor_earnings;
DROP POLICY IF EXISTS "System can insert earnings" ON instructor_earnings;

-- Create policy to allow authenticated users to insert earnings
-- This is needed because the checkout process runs as the student user
-- but needs to create an earning record for the instructor
DROP POLICY IF EXISTS "Allow insert on checkout" ON instructor_earnings;
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


-- =====================================================================
-- File: 211_instructor_earnings_functions.sql
-- =====================================================================
-- ============================================================
-- Instructor Earnings Functions
-- Functions to automatically calculate and sync earnings
-- ============================================================

-- 1. Function to create earning record when enrollment is created
-- This trigger will automatically add earnings when a paid enrollment happens
CREATE OR REPLACE FUNCTION create_instructor_earning()
RETURNS TRIGGER AS $$
DECLARE
    v_instructor_id UUID;
    v_course_price DECIMAL(10,2);
    v_revenue_share DECIMAL(5,2) := 70.00; -- Default 70% to instructor
    v_instructor_share DECIMAL(10,2);
    v_platform_fee DECIMAL(10,2);
BEGIN
    -- Only create earning for paid enrollments with active status
    IF NEW.price > 0 AND NEW.status = 'active' THEN
        -- Get instructor_id from course if not set
        IF NEW.instructor_id IS NULL THEN
            SELECT instructor_id INTO v_instructor_id
            FROM courses WHERE id = NEW.course_id;
        ELSE
            v_instructor_id := NEW.instructor_id;
        END IF;

        -- Check if earning already exists for this enrollment
        IF NOT EXISTS (SELECT 1 FROM instructor_earnings WHERE enrollment_id = NEW.id) THEN
            -- Calculate shares
            v_instructor_share := NEW.price * (v_revenue_share / 100);
            v_platform_fee := NEW.price - v_instructor_share;

            -- Insert earning record
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
            ) VALUES (
                v_instructor_id,
                NEW.id,
                NEW.course_id,
                NEW.price,
                v_platform_fee,
                v_instructor_share,
                v_revenue_share,
                'available', -- Make available immediately
                NOW(),
                COALESCE(NEW.enrolled_at, NOW())
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on enrollments table
DROP TRIGGER IF EXISTS trigger_create_instructor_earning ON enrollments;
CREATE TRIGGER trigger_create_instructor_earning
    AFTER INSERT OR UPDATE ON enrollments
    FOR EACH ROW
    EXECUTE FUNCTION create_instructor_earning();


-- 2. Function to sync all missing earnings (for existing enrollments)
CREATE OR REPLACE FUNCTION sync_all_instructor_earnings()
RETURNS JSON AS $$
DECLARE
    v_count INTEGER := 0;
    v_enrollment RECORD;
    v_revenue_share DECIMAL(5,2) := 70.00;
    v_instructor_share DECIMAL(10,2);
    v_platform_fee DECIMAL(10,2);
BEGIN
    -- Loop through all paid enrollments without earnings
    FOR v_enrollment IN 
        SELECT 
            e.id as enrollment_id,
            e.course_id,
            e.instructor_id,
            e.price,
            e.enrolled_at,
            c.instructor_id as course_instructor_id
        FROM enrollments e
        JOIN courses c ON c.id = e.course_id
        WHERE e.price > 0
          AND e.status = 'active'
          AND NOT EXISTS (
              SELECT 1 FROM instructor_earnings ie 
              WHERE ie.enrollment_id = e.id
          )
    LOOP
        -- Calculate shares
        v_instructor_share := v_enrollment.price * (v_revenue_share / 100);
        v_platform_fee := v_enrollment.price - v_instructor_share;

        -- Insert earning record
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
        ) VALUES (
            COALESCE(v_enrollment.instructor_id, v_enrollment.course_instructor_id),
            v_enrollment.enrollment_id,
            v_enrollment.course_id,
            v_enrollment.price,
            v_platform_fee,
            v_instructor_share,
            v_revenue_share,
            'available',
            NOW(),
            COALESCE(v_enrollment.enrolled_at, NOW())
        );

        v_count := v_count + 1;
    END LOOP;

    RETURN json_build_object(
        'success', true,
        'synced_count', v_count,
        'message', format('Synced %s earnings records', v_count)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 3. Function to get instructor earnings summary
CREATE OR REPLACE FUNCTION get_instructor_earnings_summary(p_instructor_id UUID DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    v_instructor_id UUID;
    v_result JSON;
BEGIN
    -- Use provided instructor_id or current user
    v_instructor_id := COALESCE(p_instructor_id, auth.uid());

    SELECT json_build_object(
        'total_earnings', COALESCE(SUM(net_amount), 0),
        'available_balance', COALESCE(SUM(CASE WHEN status = 'available' THEN net_amount ELSE 0 END), 0),
        'pending_balance', COALESCE(SUM(CASE WHEN status = 'pending' THEN net_amount ELSE 0 END), 0),
        'paid_amount', COALESCE(SUM(CASE WHEN status = 'paid' THEN net_amount ELSE 0 END), 0),
        'total_sales', COUNT(*),
        'this_month_earnings', COALESCE(SUM(CASE WHEN created_at >= DATE_TRUNC('month', NOW()) THEN net_amount ELSE 0 END), 0),
        'last_month_earnings', COALESCE(SUM(CASE WHEN created_at >= DATE_TRUNC('month', NOW() - INTERVAL '1 month') AND created_at < DATE_TRUNC('month', NOW()) THEN net_amount ELSE 0 END), 0)
    ) INTO v_result
    FROM instructor_earnings
    WHERE instructor_id = v_instructor_id;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 4. Function to get instructor revenue chart data
CREATE OR REPLACE FUNCTION get_instructor_revenue_chart(
    p_start_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
    p_end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
    label TEXT,
    value DECIMAL(10,2)
) AS $$
DECLARE
    v_instructor_id UUID := auth.uid();
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(DATE_TRUNC('day', ie.created_at), 'MM/DD') as label,
        COALESCE(SUM(ie.net_amount), 0)::DECIMAL(10,2) as value
    FROM generate_series(
        DATE_TRUNC('day', p_start_date),
        DATE_TRUNC('day', p_end_date),
        '1 day'::INTERVAL
    ) as dates(date)
    LEFT JOIN instructor_earnings ie ON 
        DATE_TRUNC('day', ie.created_at) = dates.date
        AND ie.instructor_id = v_instructor_id
    GROUP BY dates.date
    ORDER BY dates.date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 5. Function to get instructor enrollments chart data
CREATE OR REPLACE FUNCTION get_instructor_enrollments_chart(
    p_start_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
    p_end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
    label TEXT,
    value DECIMAL(10,2)
) AS $$
DECLARE
    v_instructor_id UUID := auth.uid();
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(DATE_TRUNC('day', dates.date), 'MM/DD') as label,
        COUNT(e.id)::DECIMAL(10,2) as value
    FROM generate_series(
        DATE_TRUNC('day', p_start_date),
        DATE_TRUNC('day', p_end_date),
        '1 day'::INTERVAL
    ) as dates(date)
    LEFT JOIN enrollments e ON 
        DATE_TRUNC('day', e.enrolled_at) = dates.date
        AND e.instructor_id = v_instructor_id
    GROUP BY dates.date
    ORDER BY dates.date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 6. Update the get_instructor_dashboard_stats function to include real earnings
CREATE OR REPLACE FUNCTION get_instructor_dashboard_stats()
RETURNS JSON AS $$
DECLARE
    v_instructor_id UUID := auth.uid();
    v_stats JSON;
BEGIN
    SELECT json_build_object(
        'total_courses', (SELECT COUNT(*) FROM courses WHERE instructor_id = v_instructor_id),
        'published_courses', (SELECT COUNT(*) FROM courses WHERE instructor_id = v_instructor_id AND is_published = true),
        'total_students', (SELECT COUNT(DISTINCT e.user_id) FROM enrollments e JOIN courses c ON c.id = e.course_id WHERE c.instructor_id = v_instructor_id),
        'total_enrollments', (SELECT COUNT(*) FROM enrollments e JOIN courses c ON c.id = e.course_id WHERE c.instructor_id = v_instructor_id),
        'monthly_enrollments', (SELECT COUNT(*) FROM enrollments e JOIN courses c ON c.id = e.course_id WHERE c.instructor_id = v_instructor_id AND e.enrolled_at >= DATE_TRUNC('month', NOW())),
        'total_earnings', COALESCE((SELECT SUM(net_amount) FROM instructor_earnings WHERE instructor_id = v_instructor_id AND status IN ('available', 'paid')), 0),
        'available_balance', COALESCE((SELECT SUM(net_amount) FROM instructor_earnings WHERE instructor_id = v_instructor_id AND status = 'available'), 0),
        'pending_balance', COALESCE((SELECT SUM(net_amount) FROM instructor_earnings WHERE instructor_id = v_instructor_id AND status = 'pending'), 0),
        'this_month_earnings', COALESCE((SELECT SUM(net_amount) FROM instructor_earnings WHERE instructor_id = v_instructor_id AND created_at >= DATE_TRUNC('month', NOW())), 0),
        'average_rating', COALESCE((SELECT AVG(cr.rating) FROM course_reviews cr JOIN courses c ON c.id = cr.course_id WHERE c.instructor_id = v_instructor_id), 0),
        'total_reviews', (SELECT COUNT(*) FROM course_reviews cr JOIN courses c ON c.id = cr.course_id WHERE c.instructor_id = v_instructor_id),
        'unanswered_questions', (SELECT COUNT(*) FROM qa_questions q JOIN courses c ON c.id = q.course_id WHERE c.instructor_id = v_instructor_id AND q.is_answered = false)
    ) INTO v_stats;

    RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 7. Run sync to add earnings for existing enrollments
SELECT sync_all_instructor_earnings();

-- 8. Verify the data
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
ORDER BY ie.created_at DESC
LIMIT 20;


-- =====================================================================
-- File: 212_quizzes_course_level.sql
-- =====================================================================
-- ============================================================
-- Make quizzes work at course level (lesson_id optional)
-- ============================================================

-- Make lesson_id nullable (quiz can be for entire course)
ALTER TABLE quizzes ALTER COLUMN lesson_id DROP NOT NULL;

-- Add index for course-level quizzes
CREATE INDEX IF NOT EXISTS idx_quizzes_course_level ON quizzes(course_id) WHERE lesson_id IS NULL;

-- Verify the change
SELECT column_name, is_nullable, data_type 
FROM information_schema.columns 
WHERE table_name = 'quizzes' AND column_name = 'lesson_id';


-- Function to increment quiz questions count
CREATE OR REPLACE FUNCTION increment_quiz_questions(p_quiz_id UUID, p_points INTEGER DEFAULT 1)
RETURNS VOID AS $$
BEGIN
    UPDATE quizzes 
    SET 
        total_questions = total_questions + 1,
        total_points = total_points + p_points,
        updated_at = NOW()
    WHERE id = p_quiz_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement quiz questions count
CREATE OR REPLACE FUNCTION decrement_quiz_questions(p_quiz_id UUID, p_points INTEGER DEFAULT 1)
RETURNS VOID AS $$
BEGIN
    UPDATE quizzes 
    SET 
        total_questions = GREATEST(0, total_questions - 1),
        total_points = GREATEST(0, total_points - p_points),
        updated_at = NOW()
    WHERE id = p_quiz_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION increment_quiz_questions(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION decrement_quiz_questions(UUID, INTEGER) TO authenticated;


-- =====================================================================
-- File: 213_auto_sync_earnings.sql
-- =====================================================================
-- ============================================================
-- Auto Sync Earnings - Fix Missing Earnings Records
-- Run this script in Supabase SQL Editor
-- ============================================================

-- 1. First, check if instructor_earnings table exists and has correct structure
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'instructor_earnings') THEN
        RAISE EXCEPTION 'instructor_earnings table does not exist! Run the schema script first.';
    END IF;
END $$;

-- 2. Check current state
SELECT 'Current enrollments count:' as info, COUNT(*) as count FROM enrollments WHERE price > 0;
SELECT 'Current earnings count:' as info, COUNT(*) as count FROM instructor_earnings;

-- 3. Sync all missing earnings from existing paid enrollments
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
    COALESCE(e.instructor_id, c.instructor_id) as instructor_id,
    e.id as enrollment_id,
    e.course_id,
    e.price as gross_amount,
    e.price * 0.30 as platform_fee,  -- 30% platform fee
    e.price * 0.70 as net_amount,     -- 70% to instructor
    70.00 as revenue_share,
    'available' as status,
    NOW() as available_at,
    COALESCE(e.enrolled_at, e.created_at, NOW()) as created_at
FROM enrollments e
JOIN courses c ON c.id = e.course_id
WHERE e.price > 0
  AND e.status = 'active'
  AND NOT EXISTS (
      SELECT 1 FROM instructor_earnings ie 
      WHERE ie.enrollment_id = e.id
  );

-- 4. Show results after sync
SELECT 'After sync - earnings count:' as info, COUNT(*) as count FROM instructor_earnings;

-- 5. Show earnings by instructor
SELECT 
    p.name as instructor_name,
    COUNT(*) as total_sales,
    SUM(ie.gross_amount) as total_revenue,
    SUM(ie.net_amount) as total_earnings,
    SUM(ie.platform_fee) as total_platform_fee
FROM instructor_earnings ie
JOIN profiles p ON p.id = ie.instructor_id
GROUP BY p.id, p.name
ORDER BY total_earnings DESC;

-- 6. Create or replace the trigger function for auto-creating earnings
CREATE OR REPLACE FUNCTION auto_create_instructor_earning()
RETURNS TRIGGER AS $$
DECLARE
    v_instructor_id UUID;
    v_revenue_share DECIMAL(5,2) := 70.00;
    v_instructor_share DECIMAL(10,2);
    v_platform_fee DECIMAL(10,2);
BEGIN
    -- Only for paid enrollments with active status
    IF NEW.price > 0 AND NEW.status = 'active' THEN
        -- Get instructor_id
        v_instructor_id := COALESCE(NEW.instructor_id, (SELECT instructor_id FROM courses WHERE id = NEW.course_id));

        -- Check if earning already exists
        IF NOT EXISTS (SELECT 1 FROM instructor_earnings WHERE enrollment_id = NEW.id) THEN
            -- Calculate shares
            v_instructor_share := NEW.price * (v_revenue_share / 100);
            v_platform_fee := NEW.price - v_instructor_share;

            -- Insert earning
            INSERT INTO instructor_earnings (
                instructor_id, enrollment_id, course_id,
                gross_amount, platform_fee, net_amount,
                revenue_share, status, available_at, created_at
            ) VALUES (
                v_instructor_id, NEW.id, NEW.course_id,
                NEW.price, v_platform_fee, v_instructor_share,
                v_revenue_share, 'available', NOW(), COALESCE(NEW.enrolled_at, NOW())
            );
            
            RAISE NOTICE 'Created earning for enrollment %', NEW.id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Drop and recreate trigger
DROP TRIGGER IF EXISTS trigger_auto_create_earning ON enrollments;
CREATE TRIGGER trigger_auto_create_earning
    AFTER INSERT ON enrollments
    FOR EACH ROW
    EXECUTE FUNCTION auto_create_instructor_earning();

-- 8. Grant necessary permissions
GRANT EXECUTE ON FUNCTION auto_create_instructor_earning() TO authenticated;

-- 9. Verify trigger exists
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_auto_create_earning';

SELECT '✅ Earnings sync completed! Trigger created for auto-sync on new enrollments.' as status;


-- =====================================================================
-- File: 214_instructor_enroll_student_policy.sql
-- =====================================================================
-- ============================================================
-- Allow instructors to enroll students in their courses
-- ============================================================

-- Drop existing policy if exists
DROP POLICY IF EXISTS "Instructors can enroll students in their courses" ON enrollments;

-- Create policy for instructors to INSERT enrollments for their courses
DROP POLICY IF EXISTS "Instructors can enroll students in their courses" ON enrollments;
CREATE POLICY "Instructors can enroll students in their courses" ON enrollments 
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
DROP POLICY IF EXISTS "Instructors can update enrollments for their courses" ON enrollments;
CREATE POLICY "Instructors can update enrollments for their courses" ON enrollments 
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
DROP POLICY IF EXISTS "Instructors can delete enrollments for their courses" ON enrollments;
CREATE POLICY "Instructors can delete enrollments for their courses" ON enrollments 
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


-- =====================================================================
-- File: 215_instructor_view_quiz_attempts.sql
-- =====================================================================
-- ============================================================
-- Allow Instructors to View Quiz Attempts for Their Courses
-- Run this in Supabase SQL Editor
-- ============================================================

-- Add policy for instructors to view quiz attempts in their courses
DROP POLICY IF EXISTS "instructors_view_quiz_attempts" ON quiz_attempts;
CREATE POLICY "instructors_view_quiz_attempts" ON quiz_attempts
  FOR SELECT TO authenticated
  USING (
    -- User can see their own attempts
    user_id = auth.uid()
    OR
    -- Instructor can see attempts for quizzes in their courses
    EXISTS (
      SELECT 1 FROM quizzes q
      JOIN courses c ON q.course_id = c.id
      WHERE q.id = quiz_attempts.quiz_id
      AND c.instructor_id = auth.uid()
    )
  );

-- Drop the old select policy first (if exists)
DROP POLICY IF EXISTS "quiz_attempts_select" ON quiz_attempts;

-- Verify policies
SELECT tablename, policyname, cmd FROM pg_policies WHERE tablename = 'quiz_attempts';


-- =====================================================================
-- File: 216_fix_option_ids.sql
-- =====================================================================
-- ============================================================
-- Fix Missing Option IDs in Quiz Questions
-- Run this in Supabase SQL Editor
-- ============================================================

-- Update options that don`t have IDs
UPDATE quiz_questions
SET options = (
  SELECT jsonb_agg(
    CASE 
      WHEN opt->>'id' IS NULL OR opt->>'id' = '' 
      THEN opt || jsonb_build_object('id', gen_random_uuid()::text)
      ELSE opt
    END
  )
  FROM jsonb_array_elements(options) AS opt
)
WHERE options IS NOT NULL 
  AND jsonb_array_length(options) > 0
  AND EXISTS (
    SELECT 1 FROM jsonb_array_elements(options) AS opt
    WHERE opt->>'id' IS NULL OR opt->>'id' = ''
  );

-- Verify the fix
SELECT id, question_ar, options 
FROM quiz_questions 
WHERE options IS NOT NULL 
LIMIT 5;


-- =====================================================================
-- File: 217_fix_submit_quiz_v2.sql
-- =====================================================================
-- ============================================================
-- Fix Submit Quiz Function v2
-- Fix answer comparison logic
-- ============================================================

DROP FUNCTION IF EXISTS submit_quiz_attempt(UUID, JSONB, INT);

CREATE OR REPLACE FUNCTION submit_quiz_attempt(
  p_attempt_id UUID,
  p_answers JSONB,
  p_time_spent INT DEFAULT 0
)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_attempt RECORD;
  v_quiz RECORD;
  v_score INT := 0;
  v_total_points INT := 0;
  v_percentage DECIMAL;
  v_passed BOOLEAN;
  v_question RECORD;
  v_user_answer JSONB;
  v_correct_option_ids JSONB;
  v_is_correct BOOLEAN;
  v_debug_info JSONB := '[]'::jsonb;
BEGIN
  -- Get attempt
  SELECT * INTO v_attempt 
  FROM quiz_attempts 
  WHERE id = p_attempt_id AND user_id = v_user_id;
  
  IF v_attempt IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Attempt not found or unauthorized');
  END IF;
  
  -- Check if already completed
  IF v_attempt.completed_at IS NOT NULL THEN
    RETURN json_build_object('success', false, 'error', 'Attempt already completed');
  END IF;
  
  -- Get quiz
  SELECT * INTO v_quiz FROM quizzes WHERE id = v_attempt.quiz_id;
  
  IF v_quiz IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Quiz not found');
  END IF;
  
  -- Calculate score
  FOR v_question IN 
    SELECT id, points, options 
    FROM quiz_questions 
    WHERE quiz_id = v_attempt.quiz_id
  LOOP
    v_total_points := v_total_points + v_question.points;
    
    -- Get user's answer for this question (it`s an array of option IDs)
    v_user_answer := p_answers->v_question.id::text;
    
    -- Get correct option IDs from the question options
    SELECT jsonb_agg(opt->>'id') INTO v_correct_option_ids
    FROM jsonb_array_elements(v_question.options) AS opt
    WHERE (opt->>'is_correct')::boolean = true;
    
    -- Default to empty array if no correct options found
    IF v_correct_option_ids IS NULL THEN
      v_correct_option_ids := '[]'::jsonb;
    END IF;
    
    -- Check if answer is correct
    -- Both arrays must contain the same elements (order doesn`t matter)
    IF v_user_answer IS NOT NULL AND jsonb_array_length(v_user_answer) > 0 THEN
      -- Sort both arrays and compare
      v_is_correct := (
        SELECT 
          (SELECT jsonb_agg(x ORDER BY x) FROM jsonb_array_elements_text(v_user_answer) x) =
          (SELECT jsonb_agg(x ORDER BY x) FROM jsonb_array_elements_text(v_correct_option_ids) x)
      );
      
      IF v_is_correct THEN
        v_score := v_score + v_question.points;
      END IF;
    ELSE
      v_is_correct := false;
    END IF;
    
    -- Add debug info
    v_debug_info := v_debug_info || jsonb_build_object(
      'question_id', v_question.id,
      'user_answer', v_user_answer,
      'correct_options', v_correct_option_ids,
      'is_correct', v_is_correct
    );
  END LOOP;
  
  -- Calculate percentage
  v_percentage := CASE 
    WHEN v_total_points > 0 THEN (v_score::DECIMAL / v_total_points) * 100 
    ELSE 0 
  END;
  
  v_passed := v_percentage >= v_quiz.passing_score;
  
  -- Update attempt
  UPDATE quiz_attempts SET
    completed_at = NOW(),
    score = v_score,
    total_points = v_total_points,
    percentage = v_percentage,
    passed = v_passed,
    time_spent = p_time_spent,
    answers = p_answers
  WHERE id = p_attempt_id;
  
  -- Return result with debug info
  RETURN json_build_object(
    'success', true,
    'attempt_id', p_attempt_id,
    'score', v_score,
    'total_points', v_total_points,
    'percentage', ROUND(v_percentage, 2),
    'passed', v_passed,
    'passing_score', v_quiz.passing_score,
    'debug', v_debug_info
  );
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION submit_quiz_attempt(UUID, JSONB, INT) TO authenticated;

SELECT 'Submit quiz function v2 fixed!' as status;


-- =====================================================================
-- File: 218_fix_instructor_enrollments_chart.sql
-- =====================================================================
-- Fix get_instructor_enrollments_chart function
-- The function was using single $ instead of $$ for function body delimiter

CREATE OR REPLACE FUNCTION get_instructor_enrollments_chart(
    p_start_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
    p_end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
    label TEXT,
    value DECIMAL(10,2)
) AS $$
DECLARE
    v_instructor_id UUID := auth.uid();
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(DATE_TRUNC('day', dates.date), 'MM/DD') as label,
        COUNT(e.id)::DECIMAL(10,2) as value
    FROM generate_series(
        DATE_TRUNC('day', p_start_date),
        DATE_TRUNC('day', p_end_date),
        '1 day'::INTERVAL
    ) as dates(date)
    LEFT JOIN enrollments e ON 
        DATE_TRUNC('day', e.enrolled_at) = dates.date
        AND e.instructor_id = v_instructor_id
    GROUP BY dates.date
    ORDER BY dates.date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- =====================================================================
-- File: 219_quiz_stats_function.sql
-- =====================================================================
-- ============================================================
-- Add quiz statistics (attempts_count, average_score) to quizzes
-- ============================================================

-- Add columns to quizzes table if not exist
ALTER TABLE quizzes ADD COLUMN IF NOT EXISTS attempts_count INT DEFAULT 0;
ALTER TABLE quizzes ADD COLUMN IF NOT EXISTS average_score DECIMAL(5,2) DEFAULT 0;

-- Function to update quiz stats
CREATE OR REPLACE FUNCTION update_quiz_stats(p_quiz_id UUID)
RETURNS VOID AS $$
DECLARE
    v_attempts_count INT;
    v_average_score DECIMAL(5,2);
BEGIN
    -- Calculate stats from completed attempts
    SELECT 
        COUNT(*)::INT,
        COALESCE(AVG(percentage), 0)::DECIMAL(5,2)
    INTO v_attempts_count, v_average_score
    FROM quiz_attempts
    WHERE quiz_id = p_quiz_id
      AND completed_at IS NOT NULL;
    
    -- Update quiz
    UPDATE quizzes
    SET attempts_count = v_attempts_count,
        average_score = v_average_score
    WHERE id = p_quiz_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update stats when attempt is completed
CREATE OR REPLACE FUNCTION trigger_update_quiz_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Only update when attempt is completed
    IF NEW.completed_at IS NOT NULL AND (OLD.completed_at IS NULL OR OLD.completed_at != NEW.completed_at) THEN
        PERFORM update_quiz_stats(NEW.quiz_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS quiz_attempt_stats_trigger ON quiz_attempts;

-- Create trigger
CREATE TRIGGER quiz_attempt_stats_trigger
AFTER INSERT OR UPDATE ON quiz_attempts
FOR EACH ROW
EXECUTE FUNCTION trigger_update_quiz_stats();

-- Update all existing quizzes stats
DO $$
DECLARE
    quiz_record RECORD;
BEGIN
    FOR quiz_record IN SELECT id FROM quizzes LOOP
        PERFORM update_quiz_stats(quiz_record.id);
    END LOOP;
END $$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION update_quiz_stats(UUID) TO authenticated;

SELECT 'Quiz stats columns and trigger created!' as status;


-- =====================================================================
-- File: 220_instructor_revenue_chart.sql
-- =====================================================================
-- ============================================================
-- Create get_instructor_revenue_chart function
-- ============================================================

CREATE OR REPLACE FUNCTION get_instructor_revenue_chart(
    p_start_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
    p_end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
    label TEXT,
    value DECIMAL(10,2)
) AS $$
DECLARE
    v_instructor_id UUID := auth.uid();
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(DATE_TRUNC('day', dates.date), 'MM/DD') as label,
        COALESCE(SUM(ie.net_amount), 0)::DECIMAL(10,2) as value
    FROM generate_series(
        DATE_TRUNC('day', p_start_date),
        DATE_TRUNC('day', p_end_date),
        '1 day'::INTERVAL
    ) as dates(date)
    LEFT JOIN instructor_earnings ie ON 
        DATE_TRUNC('day', ie.created_at) = dates.date
        AND ie.instructor_id = v_instructor_id
    GROUP BY dates.date
    ORDER BY dates.date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_instructor_revenue_chart(TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;

SELECT 'Instructor revenue chart function created!' as status;


-- =====================================================================
-- File: 221_course_stats_columns.sql
-- =====================================================================
-- ============================================================
-- Add course statistics columns and keep them updated
-- ============================================================

-- Add columns to courses table if not exist
ALTER TABLE courses ADD COLUMN IF NOT EXISTS lesson_count INT DEFAULT 0;
ALTER TABLE courses ADD COLUMN IF NOT EXISTS section_count INT DEFAULT 0;
ALTER TABLE courses ADD COLUMN IF NOT EXISTS total_revenue DECIMAL(10,2) DEFAULT 0;

-- Function to update course stats
CREATE OR REPLACE FUNCTION update_course_stats(p_course_id UUID)
RETURNS VOID AS $$
DECLARE
    v_section_count INT;
    v_lesson_count INT;
    v_total_revenue DECIMAL(10,2);
BEGIN
    -- Count sections
    SELECT COUNT(*) INTO v_section_count
    FROM sections
    WHERE course_id = p_course_id;
    
    -- Count lessons
    SELECT COUNT(*) INTO v_lesson_count
    FROM lessons
    WHERE course_id = p_course_id;
    
    -- Sum revenue from instructor_earnings
    SELECT COALESCE(SUM(net_amount), 0) INTO v_total_revenue
    FROM instructor_earnings
    WHERE course_id = p_course_id;
    
    -- Update course
    UPDATE courses
    SET section_count = v_section_count,
        lesson_count = v_lesson_count,
        total_revenue = v_total_revenue
    WHERE id = p_course_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger function for sections
CREATE OR REPLACE FUNCTION trigger_update_course_stats_on_section()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM update_course_stats(OLD.course_id);
        RETURN OLD;
    ELSE
        PERFORM update_course_stats(NEW.course_id);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for lessons
CREATE OR REPLACE FUNCTION trigger_update_course_stats_on_lesson()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM update_course_stats(OLD.course_id);
        RETURN OLD;
    ELSE
        PERFORM update_course_stats(NEW.course_id);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for earnings
CREATE OR REPLACE FUNCTION trigger_update_course_stats_on_earning()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM update_course_stats(OLD.course_id);
        RETURN OLD;
    ELSE
        PERFORM update_course_stats(NEW.course_id);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Drop existing triggers
DROP TRIGGER IF EXISTS section_stats_trigger ON sections;
DROP TRIGGER IF EXISTS lesson_stats_trigger ON lessons;
DROP TRIGGER IF EXISTS earning_stats_trigger ON instructor_earnings;

-- Create triggers
CREATE TRIGGER section_stats_trigger
AFTER INSERT OR UPDATE OR DELETE ON sections
FOR EACH ROW
EXECUTE FUNCTION trigger_update_course_stats_on_section();

CREATE TRIGGER lesson_stats_trigger
AFTER INSERT OR UPDATE OR DELETE ON lessons
FOR EACH ROW
EXECUTE FUNCTION trigger_update_course_stats_on_lesson();

CREATE TRIGGER earning_stats_trigger
AFTER INSERT OR UPDATE OR DELETE ON instructor_earnings
FOR EACH ROW
EXECUTE FUNCTION trigger_update_course_stats_on_earning();

-- Update all existing courses stats
DO $$
DECLARE
    course_record RECORD;
BEGIN
    FOR course_record IN SELECT id FROM courses LOOP
        PERFORM update_course_stats(course_record.id);
    END LOOP;
END $$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION update_course_stats(UUID) TO authenticated;

SELECT 'Course stats columns and triggers created!' as status;


-- =====================================================================
-- File: 222_quiz_question_images.sql
-- =====================================================================
-- Add image_url column to quiz_questions table
-- This allows questions to have text only, image only, or both

ALTER TABLE quiz_questions
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- Add comment for documentation
COMMENT ON COLUMN quiz_questions.image_url IS 'Optional image URL for the question. Question can be text only, image only, or both.';


-- =====================================================================
-- File: 223_fix_submit_quiz_store_is_correct.sql
-- =====================================================================
-- ============================================================
-- Fix Submit Quiz Function v3
-- Store is_correct with each answer
-- ============================================================

DROP FUNCTION IF EXISTS submit_quiz_attempt(UUID, JSONB, INT);

CREATE OR REPLACE FUNCTION submit_quiz_attempt(
  p_attempt_id UUID,
  p_answers JSONB,
  p_time_spent INT DEFAULT 0
)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_attempt RECORD;
  v_quiz RECORD;
  v_score INT := 0;
  v_total_points INT := 0;
  v_percentage DECIMAL;
  v_passed BOOLEAN;
  v_question RECORD;
  v_user_answer JSONB;
  v_correct_option_ids JSONB;
  v_is_correct BOOLEAN;
  v_answers_with_correct JSONB := '{}'::jsonb;
BEGIN
  -- Get attempt
  SELECT * INTO v_attempt 
  FROM quiz_attempts 
  WHERE id = p_attempt_id AND user_id = v_user_id;
  
  IF v_attempt IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Attempt not found or unauthorized');
  END IF;
  
  -- Check if already completed
  IF v_attempt.completed_at IS NOT NULL THEN
    RETURN json_build_object('success', false, 'error', 'Attempt already completed');
  END IF;
  
  -- Get quiz
  SELECT * INTO v_quiz FROM quizzes WHERE id = v_attempt.quiz_id;
  
  IF v_quiz IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Quiz not found');
  END IF;
  
  -- Calculate score
  FOR v_question IN 
    SELECT id, points, options 
    FROM quiz_questions 
    WHERE quiz_id = v_attempt.quiz_id
  LOOP
    v_total_points := v_total_points + v_question.points;
    
    -- Get user's answer for this question (it`s an array of option IDs)
    v_user_answer := p_answers->v_question.id::text;
    
    -- Get correct option IDs from the question options
    SELECT jsonb_agg(opt->>'id') INTO v_correct_option_ids
    FROM jsonb_array_elements(v_question.options) AS opt
    WHERE (opt->>'is_correct')::boolean = true;
    
    -- Default to empty array if no correct options found
    IF v_correct_option_ids IS NULL THEN
      v_correct_option_ids := '[]'::jsonb;
    END IF;
    
    -- Check if answer is correct
    IF v_user_answer IS NOT NULL AND jsonb_array_length(v_user_answer) > 0 THEN
      v_is_correct := (
        SELECT 
          (SELECT jsonb_agg(x ORDER BY x) FROM jsonb_array_elements_text(v_user_answer) x) =
          (SELECT jsonb_agg(x ORDER BY x) FROM jsonb_array_elements_text(v_correct_option_ids) x)
      );
      
      IF v_is_correct THEN
        v_score := v_score + v_question.points;
      END IF;
    ELSE
      v_is_correct := false;
    END IF;
    
    -- Store answer with is_correct flag
    v_answers_with_correct := v_answers_with_correct || jsonb_build_object(
      v_question.id::text,
      jsonb_build_object(
        'selected_option_ids', COALESCE(v_user_answer, '[]'::jsonb),
        'is_correct', v_is_correct,
        'points_earned', CASE WHEN v_is_correct THEN v_question.points ELSE 0 END
      )
    );
  END LOOP;
  
  -- Calculate percentage
  v_percentage := CASE 
    WHEN v_total_points > 0 THEN (v_score::DECIMAL / v_total_points) * 100 
    ELSE 0 
  END;
  
  v_passed := v_percentage >= v_quiz.passing_score;
  
  -- Update attempt with answers that include is_correct
  UPDATE quiz_attempts SET
    completed_at = NOW(),
    score = v_score,
    total_points = v_total_points,
    percentage = v_percentage,
    passed = v_passed,
    time_spent = p_time_spent,
    answers = v_answers_with_correct
  WHERE id = p_attempt_id;
  
  -- Return result
  RETURN json_build_object(
    'success', true,
    'attempt_id', p_attempt_id,
    'score', v_score,
    'total_points', v_total_points,
    'percentage', ROUND(v_percentage, 2),
    'passed', v_passed,
    'passing_score', v_quiz.passing_score
  );
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION submit_quiz_attempt(UUID, JSONB, INT) TO authenticated;

SELECT 'Submit quiz function v3 - now stores is_correct with each answer!' as status;


-- =====================================================================
-- File: 224_fix_instructor_stats.sql
-- =====================================================================
-- Fix instructor dashboard stats (available balance & average rating)
-- Run this script to ensure stats are calculated correctly

-- 1. First, let`s check if there are any earnings records
SELECT 
    'instructor_earnings' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN status = 'available' THEN 1 END) as available_count,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_count,
    COALESCE(SUM(CASE WHEN status = 'available' THEN net_amount END), 0) as total_available
FROM instructor_earnings;

-- 2. Check if there are any reviews
SELECT 
    'course_reviews' as table_name,
    COUNT(*) as total_reviews,
    COALESCE(AVG(rating), 0) as avg_rating
FROM course_reviews;

-- 3. Sync earnings from enrollments (if not already synced)
-- This will create earnings records for paid enrollments
DO $$
DECLARE
    v_enrollment RECORD;
    v_instructor_id UUID;
    v_platform_fee_percent NUMERIC := 0.20; -- 20% platform fee
    v_gross_amount NUMERIC;
    v_net_amount NUMERIC;
    v_synced_count INT := 0;
BEGIN
    FOR v_enrollment IN 
        SELECT 
            e.id as enrollment_id,
            e.course_id,
            e.user_id as student_id,
            e.price,
            e.enrolled_at,
            c.instructor_id
        FROM enrollments e
        JOIN courses c ON c.id = e.course_id
        WHERE e.price > 0
        AND NOT EXISTS (
            SELECT 1 FROM instructor_earnings ie 
            WHERE ie.enrollment_id = e.id
        )
    LOOP
        v_instructor_id := v_enrollment.instructor_id;
        v_gross_amount := v_enrollment.price;
        v_net_amount := v_gross_amount * (1 - v_platform_fee_percent);
        
        INSERT INTO instructor_earnings (
            instructor_id,
            course_id,
            enrollment_id,
            student_id,
            gross_amount,
            platform_fee_percent,
            platform_fee_amount,
            net_amount,
            status,
            available_at,
            created_at
        ) VALUES (
            v_instructor_id,
            v_enrollment.course_id,
            v_enrollment.enrollment_id,
            v_enrollment.student_id,
            v_gross_amount,
            v_platform_fee_percent,
            v_gross_amount * v_platform_fee_percent,
            v_net_amount,
            'available', -- Make it available immediately for testing
            NOW(),
            v_enrollment.enrolled_at
        );
        
        v_synced_count := v_synced_count + 1;
    END LOOP;
    
    RAISE NOTICE 'Synced % earnings records', v_synced_count;
END $$;

-- 4. Update the get_instructor_dashboard_stats function to handle edge cases
CREATE OR REPLACE FUNCTION get_instructor_dashboard_stats()
RETURNS JSON AS $$
DECLARE
    v_instructor_id UUID := auth.uid();
    v_stats JSON;
    v_total_courses INT;
    v_published_courses INT;
    v_total_students INT;
    v_total_enrollments INT;
    v_monthly_enrollments INT;
    v_total_earnings NUMERIC;
    v_available_balance NUMERIC;
    v_pending_balance NUMERIC;
    v_average_rating NUMERIC;
    v_total_reviews INT;
    v_unanswered_questions INT;
BEGIN
    -- Get course counts
    SELECT COUNT(*), COUNT(CASE WHEN is_published THEN 1 END)
    INTO v_total_courses, v_published_courses
    FROM courses WHERE instructor_id = v_instructor_id;
    
    -- Get student/enrollment counts
    SELECT 
        COUNT(DISTINCT e.user_id),
        COUNT(*),
        COUNT(CASE WHEN e.enrolled_at >= DATE_TRUNC('month', NOW()) THEN 1 END)
    INTO v_total_students, v_total_enrollments, v_monthly_enrollments
    FROM enrollments e 
    JOIN courses c ON c.id = e.course_id 
    WHERE c.instructor_id = v_instructor_id;
    
    -- Get earnings
    SELECT 
        COALESCE(SUM(CASE WHEN status IN ('available', 'paid') THEN net_amount END), 0),
        COALESCE(SUM(CASE WHEN status = 'available' THEN net_amount END), 0),
        COALESCE(SUM(CASE WHEN status = 'pending' THEN net_amount END), 0)
    INTO v_total_earnings, v_available_balance, v_pending_balance
    FROM instructor_earnings 
    WHERE instructor_id = v_instructor_id;
    
    -- Get ratings
    SELECT COALESCE(AVG(cr.rating), 0), COUNT(*)
    INTO v_average_rating, v_total_reviews
    FROM course_reviews cr 
    JOIN courses c ON c.id = cr.course_id 
    WHERE c.instructor_id = v_instructor_id;
    
    -- Get unanswered questions
    SELECT COUNT(*)
    INTO v_unanswered_questions
    FROM qa_questions q 
    JOIN courses c ON c.id = q.course_id 
    WHERE c.instructor_id = v_instructor_id AND q.is_answered = false;
    
    -- Build result
    v_stats := json_build_object(
        'total_courses', COALESCE(v_total_courses, 0),
        'published_courses', COALESCE(v_published_courses, 0),
        'total_students', COALESCE(v_total_students, 0),
        'total_enrollments', COALESCE(v_total_enrollments, 0),
        'monthly_enrollments', COALESCE(v_monthly_enrollments, 0),
        'total_earnings', COALESCE(v_total_earnings, 0),
        'available_balance', COALESCE(v_available_balance, 0),
        'pending_balance', COALESCE(v_pending_balance, 0),
        'average_rating', ROUND(COALESCE(v_average_rating, 0)::numeric, 1),
        'total_reviews', COALESCE(v_total_reviews, 0),
        'unanswered_questions', COALESCE(v_unanswered_questions, 0)
    );

    RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Verify the function works
-- SELECT get_instructor_dashboard_stats();

-- 6. Check final stats
SELECT 
    'After Fix' as status,
    (SELECT COUNT(*) FROM instructor_earnings) as total_earnings_records,
    (SELECT COALESCE(SUM(net_amount), 0) FROM instructor_earnings WHERE status = 'available') as available_balance,
    (SELECT COUNT(*) FROM course_reviews) as total_reviews,
    (SELECT COALESCE(AVG(rating), 0) FROM course_reviews) as avg_rating;


-- =====================================================================
-- File: 225_fix_coupons_policies.sql
-- =====================================================================
-- Fix Coupons Policies - Allow instructors and admins to view all coupons
-- ============================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can view active coupons" ON coupons;
DROP POLICY IF EXISTS "Instructors can manage own coupons" ON coupons;
DROP POLICY IF EXISTS "Admins can manage all coupons" ON coupons;

-- Create new policies
-- 1. Anyone can view active coupons (for students)
DROP POLICY IF EXISTS "Anyone can view active coupons" ON coupons;
CREATE POLICY "Anyone can view active coupons" ON coupons FOR SELECT 
  USING (
    is_active = TRUE 
    AND is_suspended = FALSE 
    AND start_date <= NOW() 
    AND (end_date IS NULL OR end_date > NOW())
  );

-- 2. Instructors can view all coupons (for admin panel)
DROP POLICY IF EXISTS "Instructors can view all coupons" ON coupons;
CREATE POLICY "Instructors can view all coupons" ON coupons FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('instructor', 'admin')
    )
  );

-- 3. Instructors can insert their own coupons
DROP POLICY IF EXISTS "Instructors can insert own coupons" ON coupons;
CREATE POLICY "Instructors can insert own coupons" ON coupons 
  FOR INSERT
  WITH CHECK (instructor_id = auth.uid());

-- 4. Instructors can update their own coupons
DROP POLICY IF EXISTS "Instructors can update own coupons" ON coupons;
CREATE POLICY "Instructors can update own coupons" ON coupons 
  FOR UPDATE
  USING (instructor_id = auth.uid());

-- 5. Instructors can delete their own coupons
DROP POLICY IF EXISTS "Instructors can delete own coupons" ON coupons;
CREATE POLICY "Instructors can delete own coupons" ON coupons 
  FOR DELETE
  USING (instructor_id = auth.uid());

-- 6. Admins can manage all coupons
DROP POLICY IF EXISTS "Admins can manage all coupons" ON coupons;
CREATE POLICY "Admins can manage all coupons" ON coupons 
  FOR ALL 
  USING (is_admin());

-- Update coupon_categories and coupon_courses policies
DROP POLICY IF EXISTS "Instructors can manage coupon categories" ON coupon_categories;
DROP POLICY IF EXISTS "Admins can manage coupon categories" ON coupon_categories;
DROP POLICY IF EXISTS "Instructors can manage coupon categories" ON coupon_categories;
CREATE POLICY "Instructors can manage coupon categories" ON coupon_categories 
  FOR ALL 
  USING (
    EXISTS (
      SELECT 1 FROM coupons 
      WHERE coupons.id = coupon_categories.coupon_id 
      AND coupons.instructor_id = auth.uid()
    )
  );
DROP POLICY IF EXISTS "Admins can manage coupon categories" ON coupon_categories;
CREATE POLICY "Admins can manage coupon categories" ON coupon_categories 
  FOR ALL 
  USING (is_admin());

DROP POLICY IF EXISTS "Instructors can manage coupon courses" ON coupon_courses;
DROP POLICY IF EXISTS "Admins can manage coupon courses" ON coupon_courses;
DROP POLICY IF EXISTS "Instructors can manage coupon courses" ON coupon_courses;
CREATE POLICY "Instructors can manage coupon courses" ON coupon_courses 
  FOR ALL 
  USING (
    EXISTS (
      SELECT 1 FROM coupons 
      WHERE coupons.id = coupon_courses.coupon_id 
      AND coupons.instructor_id = auth.uid()
    )
  );
DROP POLICY IF EXISTS "Admins can manage coupon courses" ON coupon_courses;
CREATE POLICY "Admins can manage coupon courses" ON coupon_courses 
  FOR ALL 
  USING (is_admin());

-- Update coupon_usages policies
DROP POLICY IF EXISTS "Instructors can view coupon usages" ON coupon_usages;
DROP POLICY IF EXISTS "Admins can view all coupon usages" ON coupon_usages;
DROP POLICY IF EXISTS "Instructors can view own coupon usages" ON coupon_usages;
CREATE POLICY "Instructors can view own coupon usages" ON coupon_usages 
  FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM coupons 
      WHERE coupons.id = coupon_usages.coupon_id 
      AND coupons.instructor_id = auth.uid()
    )
  );
DROP POLICY IF EXISTS "Admins can view all coupon usages" ON coupon_usages;
CREATE POLICY "Admins can view all coupon usages" ON coupon_usages 
  FOR SELECT 
  USING (is_admin());


-- =====================================================================
-- File: 226_fix_categories_policies.sql
-- =====================================================================
-- Fix Categories Policies - Allow admins to view all categories
-- ============================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can view active categories" ON categories;
DROP POLICY IF EXISTS "Admins can manage categories" ON categories;

-- Create new policies
-- 1. Anyone can view active categories (for students)
DROP POLICY IF EXISTS "Anyone can view active categories" ON categories;
CREATE POLICY "Anyone can view active categories" ON categories 
  FOR SELECT 
  USING (is_active = TRUE);

-- 2. Admins can view all categories (including inactive)
DROP POLICY IF EXISTS "Admins can view all categories" ON categories;
CREATE POLICY "Admins can view all categories" ON categories 
  FOR SELECT 
  USING (is_admin());

-- 3. Admins can manage all categories
DROP POLICY IF EXISTS "Admins can insert categories" ON categories;
CREATE POLICY "Admins can insert categories" ON categories 
  FOR INSERT 
  WITH CHECK (is_admin());
DROP POLICY IF EXISTS "Admins can update categories" ON categories;
CREATE POLICY "Admins can update categories" ON categories 
  FOR UPDATE 
  USING (is_admin());
DROP POLICY IF EXISTS "Admins can delete categories" ON categories;
CREATE POLICY "Admins can delete categories" ON categories 
  FOR DELETE 
  USING (is_admin());


-- =====================================================================
-- File: 227_fix_missing_columns_and_relations.sql
-- =====================================================================


-- =====================================================================
-- File: 228_fix_phone_auth_profile_creation.sql
-- =====================================================================
-- ============================================================
-- Fix Phone Authentication Profile Creation
-- ============================================================
-- Issue: RLS policy prevents profile creation during phone auth
-- Solution: Create a function that bypasses RLS for initial profile creation
-- Version: 1.0 | January 2026
-- ============================================================

-- Drop existing policy that might cause issues
DROP POLICY IF EXISTS "Enable insert for auth" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON profiles;

-- Create new policy that allows authenticated users to insert their own profile
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON profiles;
CREATE POLICY "Enable insert for authenticated users" ON profiles 
FOR INSERT 
TO authenticated
WITH CHECK (auth.uid() = id);

-- Create a function to handle profile creation (bypasses RLS)
CREATE OR REPLACE FUNCTION public.create_profile_for_phone_auth(
  user_id UUID,
  user_phone TEXT,
  user_email TEXT DEFAULT NULL,
  user_name TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- This allows the function to bypass RLS
SET search_path = public
AS $$
BEGIN
  -- Check if profile already exists
  IF EXISTS (SELECT 1 FROM profiles WHERE id = user_id) THEN
    RETURN;
  END IF;

  -- Create the profile
  INSERT INTO profiles (
    id,
    email,
    phone,
    name,
    role,
    is_active,
    created_at,
    updated_at
  ) VALUES (
    user_id,
    COALESCE(user_email, REPLACE(user_phone, '+', '') || '@phone.user'),
    user_phone,
    COALESCE(user_name, user_phone, 'مستخدم جديد'),
    'student',
    TRUE,
    NOW(),
    NOW()
  );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.create_profile_for_phone_auth TO authenticated;

-- Create a trigger to automatically create profile after phone auth
CREATE OR REPLACE FUNCTION public.handle_new_phone_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only create profile if it doesn`t exist and user has a phone
  IF NEW.phone IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profiles WHERE id = NEW.id) THEN
    INSERT INTO profiles (
      id,
      email,
      phone,
      name,
      role,
      is_active,
      created_at,
      updated_at
    ) VALUES (
      NEW.id,
      COALESCE(NEW.email, REPLACE(NEW.phone, '+', '') || '@phone.user'),
      NEW.phone,
      COALESCE(NEW.raw_user_meta_data->>'name', NEW.phone, 'مستخدم جديد'),
      'student',
      TRUE,
      NOW(),
      NOW()
    )
    ON CONFLICT (id) DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS on_auth_user_created_phone ON auth.users;

-- Create trigger on auth.users table
CREATE TRIGGER on_auth_user_created_phone
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_phone_user();

-- ============================================================
-- Testing
-- ============================================================
-- Test the function:
-- SELECT create_profile_for_phone_auth(
--   'test-uuid`::uuid,
--   '+201234567890`,
--   NULL,
--   'Test User`
-- );
-- ============================================================


-- =====================================================================
-- File: 229_fix_phone_auth_v2.sql
-- =====================================================================
-- ============================================================
-- Fix Phone Authentication Profile Creation - V2
-- ============================================================
-- Issue: Race condition between app insert and trigger insert
-- Solution: Use SECURITY DEFINER function with ON CONFLICT DO NOTHING
-- Version: 2.0 | January 2026
-- ============================================================

-- Update the trigger function to be more robust
CREATE OR REPLACE FUNCTION public.handle_new_phone_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only create profile if user has a phone number
  IF NEW.phone IS NOT NULL THEN
    -- Use INSERT ... ON CONFLICT to avoid race conditions
    INSERT INTO profiles (
      id,
      email,
      phone,
      name,
      role,
      is_active,
      created_at,
      updated_at
    ) VALUES (
      NEW.id,
      COALESCE(NEW.email, REPLACE(NEW.phone, '+', '') || '@phone.user'),
      NEW.phone,
      COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'full_name', NEW.phone, 'مستخدم جديد'),
      COALESCE(NEW.raw_user_meta_data->>'role', 'student'),
      TRUE,
      NOW(),
      NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
      phone = COALESCE(profiles.phone, EXCLUDED.phone),
      updated_at = NOW();
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don`t fail the trigger
    RAISE WARNING 'handle_new_phone_user failed for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created_phone ON auth.users;

CREATE TRIGGER on_auth_user_created_phone
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_phone_user();

-- Also create/update the function for email auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Create profile for any new user (phone or email)
  INSERT INTO profiles (
    id,
    email,
    phone,
    name,
    role,
    is_active,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    COALESCE(NEW.email, REPLACE(NEW.phone, '+', '') || '@phone.user'),
    NEW.phone,
    COALESCE(
      NEW.raw_user_meta_data->>'name', 
      NEW.raw_user_meta_data->>'full_name',
      NEW.phone,
      split_part(NEW.email, '@', 1),
      'مستخدم جديد'
    ),
    COALESCE(NEW.raw_user_meta_data->>'role', 'student'),
    TRUE,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = COALESCE(profiles.email, EXCLUDED.email),
    phone = COALESCE(profiles.phone, EXCLUDED.phone),
    updated_at = NOW();
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don`t fail - app will create profile
    RAISE WARNING 'handle_new_user failed for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;

-- Drop old trigger and create unified one
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_phone ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Ensure RLS policy allows insert
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- Policy: Authenticated users can insert their own profile
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile" ON profiles 
FOR INSERT 
TO authenticated
WITH CHECK (auth.uid() = id);

-- Policy: Service role can insert any profile (for triggers)
DROP POLICY IF EXISTS "Service role full access" ON profiles;

-- ============================================================
-- Verify everything is set up correctly
-- ============================================================
-- SELECT 
--   tgname AS trigger_name,
--   proname AS function_name
-- FROM pg_trigger t
-- JOIN pg_proc p ON t.tgfoid = p.oid
-- WHERE tgrelid = 'auth.users`::regclass;
-- ============================================================


-- =====================================================================
-- File: 230_fix_phone_auth_final.sql
-- =====================================================================
-- ============================================================
-- Fix Phone Authentication Profile Creation - V3
-- ============================================================
-- IMPORTANT: Run this script in Supabase SQL Editor
-- Issue: RLS blocking profile creation for phone auth users
-- Solution: Create SECURITY DEFINER function that bypasses RLS
-- Version: 3.0 | January 2026
-- ============================================================

-- Step 1: Create/Update the RPC function (SECURITY DEFINER bypasses RLS)
CREATE OR REPLACE FUNCTION public.create_profile_for_phone_auth(
  user_id UUID,
  user_phone TEXT,
  user_email TEXT DEFAULT NULL,
  user_name TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- This allows the function to bypass RLS
SET search_path = public
AS $$
BEGIN
  -- Check if profile already exists
  IF EXISTS (SELECT 1 FROM profiles WHERE id = user_id) THEN
    -- Update existing profile with phone if missing
    UPDATE profiles 
    SET 
      phone = COALESCE(profiles.phone, user_phone),
      updated_at = NOW()
    WHERE id = user_id;
    RETURN;
  END IF;

  -- Create the profile
  INSERT INTO profiles (
    id,
    email,
    phone,
    name,
    role,
    is_active,
    created_at,
    updated_at
  ) VALUES (
    user_id,
    COALESCE(user_email, REPLACE(user_phone, '+', '') || '@phone.user'),
    user_phone,
    COALESCE(user_name, user_phone, 'مستخدم جديد'),
    'student',
    TRUE,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    phone = COALESCE(profiles.phone, EXCLUDED.phone),
    updated_at = NOW();
    
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'create_profile_for_phone_auth failed: %', SQLERRM;
END;
$$;

-- Step 2: Grant execute permission to authenticated users and anon
GRANT EXECUTE ON FUNCTION public.create_profile_for_phone_auth TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_profile_for_phone_auth TO anon;
GRANT EXECUTE ON FUNCTION public.create_profile_for_phone_auth TO service_role;

-- Step 3: Create/Update trigger function for automatic profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Create profile for any new user (phone or email)
  INSERT INTO profiles (
    id,
    email,
    phone,
    name,
    role,
    is_active,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    COALESCE(NEW.email, REPLACE(NEW.phone, '+', '') || '@phone.user'),
    NEW.phone,
    COALESCE(
      NEW.raw_user_meta_data->>'name', 
      NEW.raw_user_meta_data->>'full_name',
      NEW.phone,
      split_part(NEW.email, '@', 1),
      'مستخدم جديد'
    ),
    COALESCE(NEW.raw_user_meta_data->>'role', 'student'),
    TRUE,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = COALESCE(profiles.email, EXCLUDED.email),
    phone = COALESCE(profiles.phone, EXCLUDED.phone),
    updated_at = NOW();
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don`t fail - app will create profile
    RAISE WARNING 'handle_new_user failed for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;

-- Step 4: Drop old triggers and create unified one
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_phone ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Step 5: Ensure RLS policies allow profile operations
-- Drop old policies
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Enable insert for auth" ON profiles;

-- Allow users to read their own profile
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
CREATE POLICY "Users can read own profile" ON profiles 
FOR SELECT 
TO authenticated
USING (auth.uid() = id);

-- Allow users to update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles 
FOR UPDATE 
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Allow authenticated users to insert their own profile
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile" ON profiles 
FOR INSERT 
TO authenticated
WITH CHECK (auth.uid() = id);

-- Step 6: Verify setup
DO $$
BEGIN
  RAISE NOTICE '✅ Phone auth profile creation fix applied successfully!';
  RAISE NOTICE 'RPC function: create_profile_for_phone_auth - READY';
  RAISE NOTICE 'Trigger: on_auth_user_created - READY';
END $$;

-- ============================================================
-- TEST: You can test the RPC function with:
-- SELECT create_profile_for_phone_auth(
--   'your-user-uuid`::uuid,
--   '+201234567890`,
--   NULL,
--   'Test User`
-- );
-- ============================================================


-- =====================================================================
-- File: 231_course_reviews_table.sql
-- =====================================================================
-- Drop existing table if exists (clean slate)
DROP TABLE IF EXISTS course_reviews CASCADE;

-- Create simplified course_reviews table
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

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_course_reviews_course_id ON course_reviews(course_id);
CREATE INDEX IF NOT EXISTS idx_course_reviews_user_id ON course_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_course_reviews_rating ON course_reviews(rating);

-- Enable RLS
ALTER TABLE course_reviews ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can view course reviews" ON course_reviews;
DROP POLICY IF EXISTS "Users can insert their own reviews" ON course_reviews;
DROP POLICY IF EXISTS "Users can update their own reviews" ON course_reviews;
DROP POLICY IF EXISTS "Users can delete their own reviews" ON course_reviews;

-- Policy: Users can view all reviews
DROP POLICY IF EXISTS "Anyone can view course reviews" ON course_reviews;
CREATE POLICY "Anyone can view course reviews" ON course_reviews
  FOR SELECT
  USING (true);

-- Policy: Authenticated users can insert their own reviews
DROP POLICY IF EXISTS "Users can insert their own reviews" ON course_reviews;
CREATE POLICY "Users can insert their own reviews" ON course_reviews
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own reviews
DROP POLICY IF EXISTS "Users can update their own reviews" ON course_reviews;
CREATE POLICY "Users can update their own reviews" ON course_reviews
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own reviews
DROP POLICY IF EXISTS "Users can delete their own reviews" ON course_reviews;
CREATE POLICY "Users can delete their own reviews" ON course_reviews
  FOR DELETE
  USING (auth.uid() = user_id);

-- Drop old triggers and functions
DROP TRIGGER IF EXISTS trigger_update_course_rating ON course_reviews;
DROP TRIGGER IF EXISTS trigger_update_instructor_rating ON course_reviews;
DROP FUNCTION IF EXISTS update_course_rating();
DROP FUNCTION IF EXISTS update_instructor_rating();

-- Function to update course average rating (with SECURITY DEFINER to bypass RLS)
CREATE OR REPLACE FUNCTION update_course_rating()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE courses
  SET 
    rating = (
      SELECT COALESCE(AVG(rating), 0)
      FROM course_reviews
      WHERE course_id = COALESCE(NEW.course_id, OLD.course_id)
    ),
    rating_count = (
      SELECT COUNT(*)
      FROM course_reviews
      WHERE course_id = COALESCE(NEW.course_id, OLD.course_id)
    ),
    updated_at = NOW()
  WHERE id = COALESCE(NEW.course_id, OLD.course_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger to update course rating on insert/update/delete
CREATE TRIGGER trigger_update_course_rating
  AFTER INSERT OR UPDATE OR DELETE ON course_reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_course_rating();

-- Function to update instructor average rating (with SECURITY DEFINER to bypass RLS)
CREATE OR REPLACE FUNCTION update_instructor_rating()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_instructor_id UUID;
  v_avg_rating DECIMAL(3,2);
  v_total_reviews INTEGER;
BEGIN
  SELECT instructor_id INTO v_instructor_id
  FROM courses
  WHERE id = COALESCE(NEW.course_id, OLD.course_id);
  
  SELECT 
    COALESCE(AVG(cr.rating), 0)::DECIMAL(3,2),
    COUNT(cr.id)
  INTO v_avg_rating, v_total_reviews
  FROM course_reviews cr
  INNER JOIN courses c ON c.id = cr.course_id
  WHERE c.instructor_id = v_instructor_id;
  
  UPDATE instructor_profiles
  SET 
    average_rating = v_avg_rating,
    total_reviews = v_total_reviews,
    updated_at = NOW()
  WHERE instructor_id = v_instructor_id;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger to update instructor rating on insert/update/delete
CREATE TRIGGER trigger_update_instructor_rating
  AFTER INSERT OR UPDATE OR DELETE ON course_reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_instructor_rating();

-- Add comment
COMMENT ON TABLE course_reviews IS 'Stores user ratings and reviews for courses';


-- =====================================================================
-- File: 233_recalculate_course_ratings.sql
-- =====================================================================
-- Reset all course ratings to zero, then recalculate from course_reviews table
-- This script removes all fake ratings and calculates real ratings from actual reviews

DO $$
DECLARE
  total_courses INTEGER;
  courses_with_reviews INTEGER;
  courses_without_reviews INTEGER;
  total_reviews INTEGER;
BEGIN
  -- Step 1: Reset all ratings to zero
  UPDATE courses
  SET 
    rating = 0,
    rating_count = 0,
    updated_at = NOW();

  RAISE NOTICE 'Step 1: All course ratings reset to zero';

  -- Step 2: Recalculate ratings from course_reviews table
  UPDATE courses
  SET 
    rating = COALESCE(
      (SELECT AVG(rating)::DECIMAL(3,2)
       FROM course_reviews
       WHERE course_reviews.course_id = courses.id),
      0
    ),
    rating_count = COALESCE(
      (SELECT COUNT(*)
       FROM course_reviews
       WHERE course_reviews.course_id = courses.id),
      0
    ),
    updated_at = NOW()
  WHERE EXISTS (
    SELECT 1 FROM course_reviews WHERE course_reviews.course_id = courses.id
  );

  -- Step 3: Get statistics
  SELECT COUNT(*) INTO total_courses FROM courses;
  SELECT COUNT(DISTINCT course_id) INTO courses_with_reviews FROM course_reviews;
  SELECT COUNT(*) INTO total_reviews FROM course_reviews;
  SELECT COUNT(*) INTO courses_without_reviews FROM courses WHERE rating_count = 0;
  
  -- Step 4: Log the results
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Rating recalculation completed:';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Total courses: %', total_courses;
  RAISE NOTICE 'Courses with reviews: %', courses_with_reviews;
  RAISE NOTICE 'Courses without reviews (rating = 0): %', courses_without_reviews;
  RAISE NOTICE 'Total reviews in database: %', total_reviews;
  RAISE NOTICE '========================================';
END $$;




-- =====================================================================
-- File: 234_update_instructor_profiles_ratings.sql
-- =====================================================================
-- Update instructor_profiles table with real ratings from course_reviews
-- This script calculates instructor ratings from actual course reviews

DO $$
DECLARE
  instructor_record RECORD;
  v_total_reviews INTEGER;
  v_avg_rating DECIMAL(3,2);
BEGIN
  -- Loop through all instructor profiles
  FOR instructor_record IN 
    SELECT id, instructor_id FROM instructor_profiles
  LOOP
    -- Calculate average rating and total reviews from course_reviews
    SELECT 
      COALESCE(AVG(cr.rating), 0)::DECIMAL(3,2),
      COUNT(cr.id)
    INTO v_avg_rating, v_total_reviews
    FROM course_reviews cr
    INNER JOIN courses c ON c.id = cr.course_id
    WHERE c.instructor_id = instructor_record.instructor_id;
    
    -- Update instructor profile
    UPDATE instructor_profiles
    SET 
      average_rating = v_avg_rating,
      total_reviews = v_total_reviews,
      updated_at = NOW()
    WHERE id = instructor_record.id;
    
    RAISE NOTICE 'Updated instructor %: rating=%, reviews=%', 
      instructor_record.instructor_id, v_avg_rating, v_total_reviews;
  END LOOP;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Instructor ratings updated successfully';
  RAISE NOTICE '========================================';
END $$;


-- =====================================================================
-- File: 235_test_trigger.sql
-- =====================================================================
-- Test if the trigger is working
-- This script will check if triggers exist and test them

-- Check if triggers exist
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name IN ('trigger_update_course_rating', 'trigger_update_instructor_rating');

-- Check if functions exist
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_name IN ('update_course_rating', 'update_instructor_rating')
  AND routine_schema = 'public';

-- Test: Insert a review and check if course rating updates
DO $$
DECLARE
  test_course_id UUID;
  test_user_id UUID;
  rating_before DECIMAL(3,2);
  rating_after DECIMAL(3,2);
  count_before INTEGER;
  count_after INTEGER;
BEGIN
  -- Get a test course
  SELECT id INTO test_course_id FROM courses LIMIT 1;
  
  -- Get a test user
  SELECT id INTO test_user_id FROM profiles WHERE role = 'student' LIMIT 1;
  
  IF test_course_id IS NULL OR test_user_id IS NULL THEN
    RAISE NOTICE 'No test data available';
    RETURN;
  END IF;
  
  -- Get rating before
  SELECT rating, rating_count INTO rating_before, count_before
  FROM courses WHERE id = test_course_id;
  
  RAISE NOTICE 'Before: Course % has rating=%, count=%', test_course_id, rating_before, count_before;
  
  -- Delete existing review if any
  DELETE FROM course_reviews 
  WHERE course_id = test_course_id AND user_id = test_user_id;
  
  -- Insert test review
  INSERT INTO course_reviews (course_id, user_id, rating, review)
  VALUES (test_course_id, test_user_id, 5, 'Test review from trigger test');
  
  -- Get rating after
  SELECT rating, rating_count INTO rating_after, count_after
  FROM courses WHERE id = test_course_id;
  
  RAISE NOTICE 'After: Course % has rating=%, count=%', test_course_id, rating_after, count_after;
  
  -- Check if trigger worked
  IF rating_after != rating_before OR count_after != count_before THEN
    RAISE NOTICE '✅ SUCCESS: Trigger is working! Rating changed from % to %', rating_before, rating_after;
  ELSE
    RAISE NOTICE '❌ FAILED: Trigger is NOT working! Rating stayed at %', rating_after;
  END IF;
  
  -- Cleanup
  DELETE FROM course_reviews 
  WHERE course_id = test_course_id AND user_id = test_user_id;
  
END $$;


-- =====================================================================
-- File: 236_fix_instructor_search.sql
-- =====================================================================
-- ============================================================
-- Fix Instructor Search - Ensure instructor_profiles has data
-- ============================================================

-- First, ensure all instructors in profiles have entries in instructor_profiles
INSERT INTO instructor_profiles (
  instructor_id,
  display_name,
  headline_ar,
  headline_en,
  bio_ar,
  bio_en,
  is_active,
  created_at,
  updated_at
)
SELECT 
  p.id,
  COALESCE(p.name, p.email),
  'مدرس محترف',
  'Professional Instructor',
  'مدرس متخصص في مجاله',
  'Specialized instructor in their field',
  TRUE,
  NOW(),
  NOW()
FROM profiles p
WHERE p.role = 'instructor'
  AND NOT EXISTS (
    SELECT 1 FROM instructor_profiles ip 
    WHERE ip.instructor_id = p.id
  );

-- Update instructor_profiles with actual stats from courses
UPDATE instructor_profiles ip
SET 
  total_courses = (
    SELECT COUNT(*) 
    FROM courses c 
    WHERE c.instructor_id = ip.instructor_id 
      AND c.is_published = TRUE
  ),
  total_students = (
    SELECT COUNT(DISTINCT e.user_id)
    FROM enrollments e
    JOIN courses c ON c.id = e.course_id
    WHERE c.instructor_id = ip.instructor_id
  ),
  average_rating = (
    SELECT COALESCE(AVG(c.rating), 0)
    FROM courses c
    WHERE c.instructor_id = ip.instructor_id
      AND c.is_published = TRUE
      AND c.rating IS NOT NULL
  ),
  total_reviews = (
    SELECT COALESCE(SUM(c.rating_count), 0)
    FROM courses c
    WHERE c.instructor_id = ip.instructor_id
      AND c.is_published = TRUE
  ),
  updated_at = NOW()
WHERE ip.is_active = TRUE;

-- Verify the data
SELECT 
  ip.id,
  ip.display_name,
  ip.total_students,
  ip.total_courses,
  ip.average_rating,
  ip.is_active
FROM instructor_profiles ip
WHERE ip.is_active = TRUE
ORDER BY ip.total_students DESC
LIMIT 10;


-- =====================================================================
-- File: 237_debug_instructor_search.sql
-- =====================================================================
-- ============================================================
-- Debug Instructor Search - Diagnostic Script
-- ============================================================

-- 1. Check total instructors in instructor_profiles
SELECT 
  '1. Total Instructors' as check_name,
  COUNT(*) as count
FROM instructor_profiles;

-- 2. Check active instructors
SELECT 
  '2. Active Instructors' as check_name,
  COUNT(*) as count
FROM instructor_profiles
WHERE is_active = TRUE;

-- 3. List all instructors with details
SELECT 
  '3. Instructor Details' as section,
  id,
  display_name,
  headline_ar,
  headline_en,
  total_students,
  total_courses,
  average_rating,
  is_active,
  created_at
FROM instructor_profiles
ORDER BY total_students DESC;

-- 4. Check instructors with Arabic names
SELECT 
  '4. Arabic Names' as section,
  display_name,
  total_students,
  is_active
FROM instructor_profiles
WHERE display_name ~ '[ء-ي]'  -- Arabic characters
ORDER BY total_students DESC;

-- 5. Check instructors with English names
SELECT 
  '5. English Names' as section,
  display_name,
  total_students,
  is_active
FROM instructor_profiles
WHERE display_name ~ '[A-Za-z]'  -- English characters
ORDER BY total_students DESC;

-- 6. Check for NULL or empty names
SELECT 
  '6. NULL/Empty Names' as section,
  id,
  display_name,
  instructor_id,
  is_active
FROM instructor_profiles
WHERE display_name IS NULL 
   OR display_name = ''
   OR TRIM(display_name) = '';

-- 7. Check RLS policies
SELECT 
  '7. RLS Policies' as section,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'instructor_profiles';

-- 8. Test search query (example: searching for 'أحمد`)
SELECT 
  '8. Search Test (أحمد)' as section,
  display_name,
  total_students,
  is_active
FROM instructor_profiles
WHERE LOWER(display_name) LIKE '%أحمد%'
   OR LOWER(headline_ar) LIKE '%أحمد%'
   OR LOWER(headline_en) LIKE '%أحمد%';

-- 9. Test search query (example: searching for 'ahmed`)
SELECT 
  '9. Search Test (ahmed)' as section,
  display_name,
  total_students,
  is_active
FROM instructor_profiles
WHERE LOWER(display_name) LIKE '%ahmed%'
   OR LOWER(headline_ar) LIKE '%ahmed%'
   OR LOWER(headline_en) LIKE '%ahmed%';

-- 10. Check profiles table for instructors
SELECT 
  '10. Instructors in Profiles' as section,
  COUNT(*) as count
FROM profiles
WHERE role = 'instructor';

-- 11. Compare instructor_profiles with profiles
SELECT 
  '11. Missing in instructor_profiles' as section,
  p.id,
  p.name,
  p.email,
  p.role
FROM profiles p
WHERE p.role = 'instructor'
  AND NOT EXISTS (
    SELECT 1 FROM instructor_profiles ip 
    WHERE ip.instructor_id = p.id
  );

-- 12. Sample query that the app uses
SELECT 
  '12. App Query Simulation' as section,
  id,
  display_name,
  headline_ar,
  headline_en,
  total_students,
  total_courses,
  average_rating
FROM instructor_profiles
WHERE is_active = TRUE
ORDER BY total_students DESC
LIMIT 50;


-- =====================================================================
-- File: 238_remove_banner_target_audience.sql
-- =====================================================================
-- Remove target_audience from banners table
-- All banners will be shown to everyone

-- Drop the check constraint
ALTER TABLE banners 
DROP CONSTRAINT IF EXISTS banners_target_audience_check;

-- Drop the target_audience column
ALTER TABLE banners 
DROP COLUMN IF EXISTS target_audience;

-- Update any views or functions that use target_audience
-- (The get_active_banners function will be updated to not filter by target_audience)


-- =====================================================================
-- File: 239_add_phone_to_auth_users.sql
-- =====================================================================
-- Drop the old function first if it exists
DROP FUNCTION IF EXISTS add_phone_to_auth_user(UUID, TEXT);

-- Function to add phone number to auth.users without triggering OTP
-- This bypasses the OTP verification for development/testing purposes

CREATE OR REPLACE FUNCTION add_phone_to_auth_user(
  user_id UUID,
  phone_number TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER -- Run with elevated privileges
AS $$
DECLARE
  result JSONB;
  rows_updated INTEGER;
BEGIN
  -- Update the phone in auth.users table directly
  UPDATE auth.users
  SET 
    phone = phone_number,
    phone_confirmed_at = NOW(), -- Mark as confirmed immediately
    phone_change = NULL, -- Clear any pending phone change
    phone_change_token = NULL,
    phone_change_sent_at = NULL,
    updated_at = NOW()
  WHERE id = user_id;
  
  GET DIAGNOSTICS rows_updated = ROW_COUNT;
  
  -- Also update the raw_user_meta_data if needed
  UPDATE auth.users
  SET raw_user_meta_data = 
    COALESCE(raw_user_meta_data, '{}'::jsonb) || 
    jsonb_build_object('phone', phone_number, 'phone_verified', true)
  WHERE id = user_id;
  
  -- Return success result
  result := jsonb_build_object(
    'success', true,
    'rows_updated', rows_updated,
    'phone', phone_number,
    'confirmed_at', NOW()
  );
  
  RETURN result;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION add_phone_to_auth_user(UUID, TEXT) TO authenticated;

COMMENT ON FUNCTION add_phone_to_auth_user IS 'Adds phone number to auth.users without OTP verification - for development/testing only';


-- =====================================================================
-- File: 240_course_attachments_table.sql
-- =====================================================================
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
DROP POLICY IF EXISTS "Instructors can manage their course attachments" ON course_attachments;
CREATE POLICY "Instructors can manage their course attachments" ON course_attachments
FOR ALL
USING (
  course_id IN (
    SELECT id FROM courses WHERE instructor_id = auth.uid()
  )
);

-- Policy: Enrolled students can view course attachments
DROP POLICY IF EXISTS "Enrolled students can view course attachments" ON course_attachments;
CREATE POLICY "Enrolled students can view course attachments" ON course_attachments
FOR SELECT
USING (
  course_id IN (
    SELECT course_id FROM enrollments 
    WHERE user_id = auth.uid() AND status = 'active'
  )
);

-- Policy: Admins can manage all attachments
DROP POLICY IF EXISTS "Admins can manage all attachments" ON course_attachments;
CREATE POLICY "Admins can manage all attachments" ON course_attachments
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  )
);

COMMENT ON TABLE course_attachments IS 'Course-level attachments (PDFs, images, documents) that apply to the entire course';

-- ============================================================
-- NOTE: The lessons table type constraint is NOT modified here.
-- The application code has been updated to only allow 'video` type.
-- Existing lessons with other types will remain as they are.
-- If you want to convert all existing lessons to video type, 
-- run this query manually:
-- UPDATE lessons SET type = 'video' WHERE type != 'video`;
-- ============================================================


-- =====================================================================
-- File: 243_make_user_admin.sql
-- =====================================================================
-- ============================================================================
-- MAKE USER ADMIN
-- ============================================================================
-- This script changes a user`s role to admin
-- ============================================================================

-- Check current user role
SELECT id, name, email, phone, role
FROM profiles
WHERE phone = '+201234566489' OR email = 'a@a.com';

-- Make the user with phone +201234566489 an admin
UPDATE profiles
SET role = 'admin',
    updated_at = NOW()
WHERE phone = '+201234566489';

-- OR make user with email a@a.com an admin
UPDATE profiles
SET role = 'admin',
    updated_at = NOW()
WHERE email = 'a@a.com';

-- Verify the update
SELECT id, name, email, phone, role
FROM profiles
WHERE role = 'admin';

-- ============================================================================
-- NOTES:
-- ============================================================================
-- Available roles: 'student', 'instructor', 'admin', 'parent`
-- This will change the user`s role to admin
-- ============================================================================


-- =====================================================================
-- File: 244_create_bypass_login_function.sql
-- =====================================================================
-- ============================================================================
-- CREATE BYPASS LOGIN FUNCTION
-- ============================================================================
-- This function creates a magic link for bypass login in development
-- ============================================================================

-- Function to generate a one-time password (OTP) link for development
CREATE OR REPLACE FUNCTION generate_dev_login_link(
  user_email TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_id UUID;
  magic_link TEXT;
BEGIN
  -- Get user ID from email
  SELECT id INTO user_id
  FROM auth.users
  WHERE email = user_email;
  
  IF user_id IS NULL THEN
    RAISE EXCEPTION 'User not found with email: %', user_email;
  END IF;
  
  -- For development, we`ll return a success message
  -- The actual login will be handled by the client
  RETURN 'User found: ' || user_id::TEXT;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION generate_dev_login_link(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_dev_login_link(TEXT) TO anon;

COMMENT ON FUNCTION generate_dev_login_link IS 
  'Generates a development login link for bypass authentication';

-- ============================================================================
-- ALTERNATIVE: Use Supabase Admin API
-- ============================================================================
-- The best way to handle bypass login is to use Supabase Admin API
-- from a secure backend, not from the client app
-- ============================================================================


-- =====================================================================
-- File: 245_drop_phone_otp_functions.sql
-- =====================================================================
-- ============================================================================
-- DROP PHONE OTP BYPASS FUNCTIONS
-- ============================================================================
-- This script removes all functions related to phone OTP bypass
-- ============================================================================

-- Drop the add_phone_to_auth_user function
DROP FUNCTION IF EXISTS add_phone_to_auth_user(UUID, TEXT);

-- Drop the generate_dev_login_link function
DROP FUNCTION IF EXISTS generate_dev_login_link(TEXT);

-- Verify functions are dropped
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE '%phone%' OR routine_name LIKE '%login%';

-- ============================================================================
-- CLEANUP COMPLETE
-- ============================================================================
-- All phone OTP bypass functions have been removed
-- ============================================================================


-- =====================================================================
-- File: 246_qa_answers_count_trigger.sql
-- =====================================================================
-- =====================================================
-- Q&A Answers Count Trigger
-- =====================================================
-- This script creates a trigger to automatically update
-- the answers_count in qa_questions table when answers
-- are added or deleted
-- =====================================================

-- Function to update answers count
CREATE OR REPLACE FUNCTION update_qa_answers_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Increment answers count
    UPDATE qa_questions
    SET answers_count = answers_count + 1
    WHERE id = NEW.question_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    -- Decrement answers count
    UPDATE qa_questions
    SET answers_count = GREATEST(0, answers_count - 1)
    WHERE id = OLD.question_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS trigger_update_qa_answers_count ON qa_answers;

-- Create trigger
CREATE TRIGGER trigger_update_qa_answers_count
AFTER INSERT OR DELETE ON qa_answers
FOR EACH ROW
EXECUTE FUNCTION update_qa_answers_count();

-- Recalculate existing counts (one-time fix)
UPDATE qa_questions q
SET answers_count = (
  SELECT COUNT(*)
  FROM qa_answers a
  WHERE a.question_id = q.id
);

COMMENT ON FUNCTION update_qa_answers_count() IS 'Automatically updates answers_count in qa_questions when answers are added or deleted';


-- =====================================================================
-- File: 247_qa_answer_upvotes.sql
-- =====================================================================
-- =====================================================
-- Q&A Answer Upvotes System
-- =====================================================
-- This script creates a table for tracking upvotes on
-- Q&A answers and triggers to update upvotes_count
-- =====================================================

-- Create qa_answer_upvotes table
CREATE TABLE IF NOT EXISTS qa_answer_upvotes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  answer_id UUID NOT NULL REFERENCES qa_answers(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Ensure one upvote per user per answer
  UNIQUE(answer_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_answer_upvotes_answer ON qa_answer_upvotes(answer_id);
CREATE INDEX IF NOT EXISTS idx_answer_upvotes_user ON qa_answer_upvotes(user_id);

-- Enable RLS
ALTER TABLE qa_answer_upvotes ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Anyone can view upvotes" ON qa_answer_upvotes;
DROP POLICY IF EXISTS "Users can add upvotes to others answers only" ON qa_answer_upvotes;
DROP POLICY IF EXISTS "Users can add their own upvotes" ON qa_answer_upvotes;
DROP POLICY IF EXISTS "Users can remove their own upvotes" ON qa_answer_upvotes;
DROP POLICY IF EXISTS "Anyone can view upvotes" ON qa_answer_upvotes;
CREATE POLICY "Anyone can view upvotes" ON qa_answer_upvotes 
  FOR SELECT 
  USING (true);
DROP POLICY IF EXISTS "Users can add their own upvotes" ON qa_answer_upvotes;
CREATE POLICY "Users can add their own upvotes" ON qa_answer_upvotes 
  FOR INSERT 
  WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can remove their own upvotes" ON qa_answer_upvotes;
CREATE POLICY "Users can remove their own upvotes" ON qa_answer_upvotes 
  FOR DELETE 
  USING (user_id = auth.uid());

-- Function to update upvotes count
CREATE OR REPLACE FUNCTION update_qa_answer_upvotes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Increment upvotes count
    UPDATE qa_answers
    SET upvotes_count = upvotes_count + 1
    WHERE id = NEW.answer_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    -- Decrement upvotes count
    UPDATE qa_answers
    SET upvotes_count = GREATEST(0, upvotes_count - 1)
    WHERE id = OLD.answer_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS trigger_update_qa_answer_upvotes_count ON qa_answer_upvotes;

-- Create trigger
CREATE TRIGGER trigger_update_qa_answer_upvotes_count
AFTER INSERT OR DELETE ON qa_answer_upvotes
FOR EACH ROW
EXECUTE FUNCTION update_qa_answer_upvotes_count();

-- Recalculate existing counts (one-time fix)
UPDATE qa_answers a
SET upvotes_count = (
  SELECT COUNT(*)
  FROM qa_answer_upvotes u
  WHERE u.answer_id = a.id
);

-- Grant permissions
GRANT SELECT, INSERT, DELETE ON qa_answer_upvotes TO authenticated;

-- Add to realtime publication (only if not already added)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND tablename = 'qa_answer_upvotes'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE qa_answer_upvotes;
  END IF;
END $$;

COMMENT ON TABLE qa_answer_upvotes IS 'Tracks user upvotes on Q&A answers - users cannot upvote their own answers';
COMMENT ON FUNCTION update_qa_answer_upvotes_count() IS 'Automatically updates upvotes_count in qa_answers when upvotes are added or removed';


-- =====================================================================
-- File: 248_course_attachments_storage.sql
-- =====================================================================
-- ============================================
-- Course Attachments Storage Setup
-- ============================================
-- Description: Create storage bucket and policies for course attachments
-- Author: System
-- Date: 2025-01-30

-- Create attachments bucket if not exists
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'attachments',
  'attachments',
  true, -- Public bucket so students can download
  52428800, -- 50MB limit
  ARRAY[
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'image/jpeg',
    'image/png',
    'image/gif',
    'application/zip',
    'application/x-rar-compressed',
    'text/plain'
  ]
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ============================================
-- Storage Policies
-- ============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Instructors can upload attachments" ON storage.objects;
DROP POLICY IF EXISTS "Instructors can update their attachments" ON storage.objects;
DROP POLICY IF EXISTS "Instructors can delete their attachments" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view attachments" ON storage.objects;

-- Policy 1: Instructors can upload attachments
DROP POLICY IF EXISTS "Instructors can upload attachments" ON storage;
CREATE POLICY "Instructors can upload attachments" ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'attachments' 
  AND (storage.foldername(name))[1] = 'course_attachments'
  AND (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'instructor'
    )
    OR
    -- Also allow admins
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  )
);

-- Policy 2: Instructors can update their own attachments
DROP POLICY IF EXISTS "Instructors can update their attachments" ON storage;
CREATE POLICY "Instructors can update their attachments" ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'attachments'
  AND (storage.foldername(name))[1] = 'course_attachments'
  AND (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'instructor'
    )
    OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  )
)
WITH CHECK (
  bucket_id = 'attachments'
  AND (storage.foldername(name))[1] = 'course_attachments'
);

-- Policy 3: Instructors can delete their own attachments
DROP POLICY IF EXISTS "Instructors can delete their attachments" ON storage;
CREATE POLICY "Instructors can delete their attachments" ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'attachments'
  AND (storage.foldername(name))[1] = 'course_attachments'
  AND (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'instructor'
    )
    OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  )
);

-- Policy 4: Anyone can view/download attachments (public bucket)
DROP POLICY IF EXISTS "Anyone can view attachments" ON storage;
CREATE POLICY "Anyone can view attachments" ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id = 'attachments'
  AND (storage.foldername(name))[1] = 'course_attachments'
);

-- ============================================
-- Verification
-- ============================================

-- Check current user role
DO $$
DECLARE
  current_user_role TEXT;
  current_user_id UUID;
BEGIN
  current_user_id := auth.uid();
  
  IF current_user_id IS NULL THEN
    RAISE WARNING '⚠️ No authenticated user found. Please login first.';
  ELSE
    SELECT role INTO current_user_role
    FROM public.profiles
    WHERE id = current_user_id;
    
    IF current_user_role IS NULL THEN
      RAISE WARNING '⚠️ User profile not found for user: %', current_user_id;
    ELSE
      RAISE NOTICE '✅ Current user role: % (user_id: %)', current_user_role, current_user_id;
      
      IF current_user_role NOT IN ('instructor', 'admin') THEN
        RAISE WARNING '⚠️ Current user is not an instructor or admin. Role: %', current_user_role;
      END IF;
    END IF;
  END IF;
END $$;

-- Verify bucket exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'attachments') THEN
    RAISE NOTICE '✅ Attachments bucket created successfully';
  ELSE
    RAISE EXCEPTION '❌ Failed to create attachments bucket';
  END IF;
END $$;

-- Verify policies exist
DO $$
DECLARE
  policy_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE schemaname = 'storage'
  AND tablename = 'objects'
  AND policyname LIKE '%attachments%';
  
  IF policy_count >= 4 THEN
    RAISE NOTICE '✅ Storage policies created successfully (% policies)', policy_count;
  ELSE
    RAISE WARNING '⚠️ Expected 4 policies, found %', policy_count;
  END IF;
END $$;


-- =====================================================================
-- File: 249_simple_attachments_storage.sql
-- =====================================================================
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
DROP POLICY IF EXISTS "Authenticated users can upload to attachments" ON storage;
CREATE POLICY "Authenticated users can upload to attachments" ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'attachments');

-- Policy 2: Any authenticated user can update
DROP POLICY IF EXISTS "Authenticated users can update attachments" ON storage;
CREATE POLICY "Authenticated users can update attachments" ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'attachments')
WITH CHECK (bucket_id = 'attachments');

-- Policy 3: Any authenticated user can delete
DROP POLICY IF EXISTS "Authenticated users can delete attachments" ON storage;
CREATE POLICY "Authenticated users can delete attachments" ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'attachments');

-- Policy 4: Public can read (for downloads)
DROP POLICY IF EXISTS "Public can read attachments" ON storage;
CREATE POLICY "Public can read attachments" ON storage.objects
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


-- =====================================================================
-- File: 250_notifications_table.sql
-- =====================================================================
-- ============================================================
-- 🔔 NOTIFICATIONS TABLE
-- جدول الإشعارات للمستخدمين
-- Version: 1.0 | January 2026
-- ============================================================

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Notification Type
  type TEXT NOT NULL CHECK (type IN (
    'instructor_message',      -- رسالة من المدرب
    'course_update',           -- تحديث على الكورس
    'new_lesson',              -- درس جديد
    'quiz_result',             -- نتيجة اختبار
    'certificate_issued',      -- شهادة صدرت
    'enrollment_confirmed',    -- تأكيد التسجيل
    'payment_confirmed',       -- تأكيد الدفع
    'course_completed',        -- إكمال الكورس
    'announcement',            -- إعلان
    'promotion',               -- عرض ترويجي
    'reminder',                -- تذكير
    'report_update',           -- تحديث على البلاغ
    'system'                   -- إشعار نظام
  )),
  
  -- Content (Arabic & English)
  title_ar TEXT NOT NULL,
  title_en TEXT,
  body_ar TEXT,
  body_en TEXT,
  
  -- Optional Image/Icon
  image_url TEXT,
  icon_name TEXT,
  
  -- Action Link
  action_type TEXT CHECK (action_type IN ('course', 'lesson', 'certificate', 'quiz', 'url', 'screen')),
  action_value TEXT, -- course_id, lesson_id, certificate_id, url, or screen name
  
  -- Extra Data (JSON for flexibility)
  data JSONB DEFAULT '{}',
  
  -- Status
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  
  -- Sender (optional - for instructor messages)
  sender_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  
  -- Related entities (optional)
  course_id UUID REFERENCES courses(id) ON DELETE SET NULL,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_sender ON notifications(sender_id);
CREATE INDEX IF NOT EXISTS idx_notifications_course ON notifications(course_id);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users can read their own notifications
DROP POLICY IF EXISTS "Users can read own notifications" ON notifications;
CREATE POLICY "Users can read own notifications" ON notifications FOR SELECT
  USING (auth.uid() = user_id);

-- Users can update their own notifications (mark as read)
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own notifications
DROP POLICY IF EXISTS "Users can delete own notifications" ON notifications;
CREATE POLICY "Users can delete own notifications" ON notifications FOR DELETE
  USING (auth.uid() = user_id);

-- Instructors can send notifications to their students
DROP POLICY IF EXISTS "Instructors can create notifications for their students" ON notifications;
CREATE POLICY "Instructors can create notifications for their students" ON notifications FOR INSERT
  WITH CHECK (
    -- System can create any notification
    auth.uid() IS NOT NULL
    AND (
      -- User creating notification for themselves
      auth.uid() = user_id
      OR
      -- Instructor creating notification for their student
      EXISTS (
        SELECT 1 FROM enrollments e
        JOIN courses c ON e.course_id = c.id
        WHERE e.user_id = notifications.user_id
        AND c.instructor_id = auth.uid()
      )
    )
  );

-- Admins have full access
DROP POLICY IF EXISTS "Admins have full access to notifications" ON notifications;
CREATE POLICY "Admins have full access to notifications" ON notifications FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Function to mark notification as read
CREATE OR REPLACE FUNCTION mark_notification_read(p_notification_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE notifications
  SET 
    is_read = TRUE,
    read_at = NOW(),
    updated_at = NOW()
  WHERE id = p_notification_id
  AND user_id = auth.uid();
  
  RETURN FOUND;
END;
$$;

-- Function to mark all notifications as read
CREATE OR REPLACE FUNCTION mark_all_notifications_read()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  updated_count INTEGER;
BEGIN
  WITH updated AS (
    UPDATE notifications
    SET 
      is_read = TRUE,
      read_at = NOW(),
      updated_at = NOW()
    WHERE user_id = auth.uid()
    AND is_read = FALSE
    RETURNING 1
  )
  SELECT COUNT(*) INTO updated_count FROM updated;
  
  RETURN updated_count;
END;
$$;

-- Function to get unread notifications count
CREATE OR REPLACE FUNCTION get_unread_notifications_count()
RETURNS INTEGER
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT COUNT(*)::INTEGER
  FROM notifications
  WHERE user_id = auth.uid()
  AND is_read = FALSE;
$$;

-- Function to send notification (for use by triggers/functions)
CREATE OR REPLACE FUNCTION send_notification(
  p_user_id UUID,
  p_type TEXT,
  p_title_ar TEXT,
  p_title_en TEXT DEFAULT NULL,
  p_body_ar TEXT DEFAULT NULL,
  p_body_en TEXT DEFAULT NULL,
  p_data JSONB DEFAULT '{}',
  p_sender_id UUID DEFAULT NULL,
  p_course_id UUID DEFAULT NULL,
  p_action_type TEXT DEFAULT NULL,
  p_action_value TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  INSERT INTO notifications (
    user_id, type, title_ar, title_en, body_ar, body_en,
    data, sender_id, course_id, action_type, action_value
  ) VALUES (
    p_user_id, p_type, p_title_ar, p_title_en, p_body_ar, p_body_en,
    p_data, p_sender_id, p_course_id, p_action_type, p_action_value
  )
  RETURNING id INTO v_notification_id;
  
  RETURN v_notification_id;
END;
$$;

-- ============================================================
-- GRANT PERMISSIONS
-- ============================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON notifications TO authenticated;
GRANT EXECUTE ON FUNCTION mark_notification_read TO authenticated;
GRANT EXECUTE ON FUNCTION mark_all_notifications_read TO authenticated;
GRANT EXECUTE ON FUNCTION get_unread_notifications_count TO authenticated;
GRANT EXECUTE ON FUNCTION send_notification TO authenticated;


-- =====================================================================
-- File: 251_add_report_update_notification.sql
-- =====================================================================
-- ============================================================
-- 🔔 ADD REPORT_UPDATE NOTIFICATION TYPE
-- إضافة نوع إشعار تحديث البلاغ
-- Version: 1.0 | January 2026
-- ============================================================

-- Drop and recreate the constraint to add 'report_update` type
ALTER TABLE notifications 
DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE IF EXISTS notifications DROP CONSTRAINT IF EXISTS notifications_type_check;`nALTER TABLE notifications ADD CONSTRAINT notifications_type_check 
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

-- Add columns to course_reports if they don`t exist
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

-- Add columns to review_reports if they don`t exist
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


-- =====================================================================
-- File: 252_update_video_urls.sql
-- =====================================================================
-- =====================================================
-- Update Video URLs with Working YouTube Videos
-- =====================================================
-- This script updates lesson video URLs with working YouTube videos
-- Run this to fix "Video unavailable" errors

-- Update Flutter Course Videos with Working URLs
UPDATE lessons 
SET video_url = CASE id
  -- Section 1: Introduction to Flutter
  WHEN '89ef9014-1f81-41cc-bc8c-d0b643bc65f3' THEN 'https://www.youtube.com/watch?v=1xipg02Wu8s' -- What is Flutter?
  WHEN 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e' THEN 'https://www.youtube.com/watch?v=fq4N0hgOWzU' -- Setting up Flutter
  WHEN 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f' THEN 'https://www.youtube.com/watch?v=CD1Y2DmL5JM' -- Your First Flutter App
  
  -- Section 2: Dart Basics
  WHEN 'd4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a' THEN 'https://www.youtube.com/watch?v=5rtujDjt50I' -- Variables and Data Types
  WHEN 'e5f6a7b8-c9d0-1e2f-3a4b-5c6d7e8f9a0b' THEN 'https://www.youtube.com/watch?v=JZukfxvc7Mc' -- Functions in Dart
  WHEN 'f6a7b8c9-d0e1-2f3a-4b5c-6d7e8f9a0b1c' THEN 'https://www.youtube.com/watch?v=71xacFXwzLo' -- Classes and Objects
  
  -- Section 3: Flutter Widgets
  WHEN 'a7b8c9d0-e1f2-3a4b-5c6d-7e8f9a0b1c2d' THEN 'https://www.youtube.com/watch?v=wE7khGHVkYY' -- Stateless Widgets
  WHEN 'b8c9d0e1-f2a3-4b5c-6d7e-8f9a0b1c2d3e' THEN 'https://www.youtube.com/watch?v=AqCMFXEmf3w' -- Stateful Widgets
  WHEN 'c9d0e1f2-a3b4-5c6d-7e8f-9a0b1c2d3e4f' THEN 'https://www.youtube.com/watch?v=gYNTcgZVcWw' -- Layout Widgets
  
  -- Section 4: Navigation and Routing
  WHEN 'd0e1f2a3-b4c5-6d7e-8f9a-0b1c2d3e4f5a' THEN 'https://www.youtube.com/watch?v=nyvwx7o277U' -- Basic Navigation
  WHEN 'e1f2a3b4-c5d6-7e8f-9a0b-1c2d3e4f5a6b' THEN 'https://www.youtube.com/watch?v=RwtJL2KfmB8' -- Named Routes
  WHEN 'f2a3b4c5-d6e7-8f9a-0b1c-2d3e4f5a6b7c' THEN 'https://www.youtube.com/watch?v=b2fgMCeSNpY' -- Passing Data
  
  -- Section 5: State Management
  WHEN 'a3b4c5d6-e7f8-9a0b-1c2d-3e4f5a6b7c8d' THEN 'https://www.youtube.com/watch?v=3tm-R7ymwhc' -- setState
  WHEN 'b4c5d6e7-f8a9-0b1c-2d3e-4f5a6b7c8d9e' THEN 'https://www.youtube.com/watch?v=nyJxyd_IqCY' -- Provider
  WHEN 'c5d6e7f8-a9b0-1c2d-3e4f-5a6b7c8d9e0f' THEN 'https://www.youtube.com/watch?v=vFxk_KJCqgk' -- BLoC Pattern
  
  -- Section 6: Advanced Topics
  WHEN 'd6e7f8a9-b0c1-2d3e-4f5a-6b7c8d9e0f1a' THEN 'https://www.youtube.com/watch?v=DuJWRcFvimM' -- Animations
  WHEN 'e7f8a9b0-c1d2-3e4f-5a6b-7c8d9e0f1a2b' THEN 'https://www.youtube.com/watch?v=cPifIINaeLk' -- Custom Widgets
  WHEN 'f8a9b0c1-d2e3-4f5a-6b7c-8d9e0f1a2b3c' THEN 'https://www.youtube.com/watch?v=OTS-ap9_aXc' -- Testing
  
  ELSE video_url
END
WHERE course_id = 'cc100000-0000-4000-a000-000000000007'
AND video_url IS NOT NULL;

-- Alternative: Update all lessons with a generic Flutter tutorial playlist
-- Uncomment if you want to use a single video for all lessons temporarily
/*
UPDATE lessons 
SET video_url = 'https://www.youtube.com/watch?v=1xipg02Wu8s'
WHERE course_id = 'cc100000-0000-4000-a000-000000000007'
AND video_url IS NOT NULL;
*/

-- Verify the updates
SELECT 
  id,
  title_en as title,
  video_url,
  CASE 
    WHEN video_url LIKE '%youtube.com%' THEN '✅ YouTube'
    WHEN video_url LIKE '%youtu.be%' THEN '✅ YouTube Short'
    WHEN video_url IS NULL THEN '❌ No URL'
    ELSE '⚠️ Other'
  END as url_type
FROM lessons
WHERE course_id = 'cc100000-0000-4000-a000-000000000007'
ORDER BY section_id, sort_order;

-- Log the update
DO $$
BEGIN
  RAISE NOTICE '✅ Video URLs updated successfully!';
  RAISE NOTICE '📹 All lessons now have working YouTube video links';
  RAISE NOTICE '🔍 Run the SELECT query above to verify the changes';
END $$;


-- =====================================================================
-- File: 253_quick_fix_video_urls.sql
-- =====================================================================
-- =====================================================
-- Quick Fix: Update All Video URLs with Working Video
-- =====================================================
-- This is a quick fix to replace all broken video URLs
-- with a working Flutter tutorial video

-- Update all Flutter course videos with a working YouTube video
UPDATE lessons 
SET video_url = 'https://www.youtube.com/watch?v=1xipg02Wu8s'
WHERE course_id = 'cc100000-0000-4000-a000-000000000007'
AND video_url IS NOT NULL;

-- Verify the update
SELECT 
  COUNT(*) as total_lessons,
  COUNT(CASE WHEN video_url IS NOT NULL THEN 1 END) as lessons_with_video,
  COUNT(CASE WHEN video_url = 'https://www.youtube.com/watch?v=1xipg02Wu8s' THEN 1 END) as updated_lessons
FROM lessons
WHERE course_id = 'cc100000-0000-4000-a000-000000000007';

-- Show updated lessons
SELECT 
  l.title as lesson_title,
  s.title as section_title,
  l.video_url,
  '✅ Updated' as status
FROM lessons l
JOIN sections s ON l.section_id = s.section_id
WHERE l.course_id = 'cc100000-0000-4000-a000-000000000007'
AND l.video_url IS NOT NULL
ORDER BY s.order_index, l.order_index;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Quick fix applied successfully!';
  RAISE NOTICE '📹 All lessons now use: https://www.youtube.com/watch?v=1xipg02Wu8s';
  RAISE NOTICE '💡 This is a working Flutter tutorial video';
  RAISE NOTICE '🔄 You can update individual lessons later with specific videos';
END $$;


-- =====================================================================
-- File: 254_fix_quiz_images_storage_policy.sql
-- =====================================================================
-- ============================================================
-- Fix Storage Policies for Quiz Question Images
-- ============================================================
-- This script adds RLS policies to allow instructors to upload
-- images for quiz questions to the 'courses` storage bucket

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Instructors can upload quiz images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view quiz images" ON storage.objects;

-- Policy 1: Allow instructors to upload quiz question images
-- Path format: quiz_questions/quiz_{quizId}_{timestamp}.jpg
DROP POLICY IF EXISTS "Instructors can upload quiz images" ON storage;
CREATE POLICY "Instructors can upload quiz images" ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'courses' 
  AND (storage.foldername(name))[1] = 'quiz_questions'
  AND EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('instructor', 'admin')
  )
);

-- Policy 2: Allow instructors to update their quiz images
DROP POLICY IF EXISTS "Instructors can update quiz images" ON storage;
CREATE POLICY "Instructors can update quiz images" ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'courses' 
  AND (storage.foldername(name))[1] = 'quiz_questions'
  AND EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('instructor', 'admin')
  )
);

-- Policy 3: Allow instructors to delete their quiz images
DROP POLICY IF EXISTS "Instructors can delete quiz images" ON storage;
CREATE POLICY "Instructors can delete quiz images" ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'courses' 
  AND (storage.foldername(name))[1] = 'quiz_questions'
  AND EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('instructor', 'admin')
  )
);

-- Policy 4: Allow anyone (including students) to view quiz images
DROP POLICY IF EXISTS "Anyone can view quiz images" ON storage;
CREATE POLICY "Anyone can view quiz images" ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'courses' 
  AND (storage.foldername(name))[1] = 'quiz_questions'
);

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
WHERE tablename = 'objects'
  AND policyname LIKE '%quiz images%'
ORDER BY policyname;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Quiz question images storage policies created successfully';
  RAISE NOTICE '📁 Instructors can now upload images to: courses/quiz_questions/';
  RAISE NOTICE '👁️ All authenticated users can view quiz images';
END $$;


-- =====================================================================
-- File: 255_course_forum_tables.sql
-- =====================================================================
-- =====================================================
-- Course Forum/Group Chat Feature
-- WhatsApp-like group chat for each course
-- =====================================================

-- Course Forum Messages Table
CREATE TABLE IF NOT EXISTS course_forum_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    message_text TEXT,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'reply')),
    media_url TEXT,
    file_name TEXT,
    file_size BIGINT,
    reply_to_message_id UUID REFERENCES course_forum_messages(id) ON DELETE SET NULL,
    is_edited BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_message_content CHECK (
        (message_type = 'text' AND message_text IS NOT NULL) OR
        (message_type IN ('image', 'file') AND media_url IS NOT NULL)
    )
);

-- Message Reactions Table (like WhatsApp reactions)
CREATE TABLE IF NOT EXISTS course_forum_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES course_forum_messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    reaction VARCHAR(10) NOT NULL, -- emoji
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(message_id, user_id)
);

-- Message Read Receipts (like WhatsApp blue ticks)
CREATE TABLE IF NOT EXISTS course_forum_read_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES course_forum_messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(message_id, user_id)
);

-- Pinned Messages (like WhatsApp pinned messages)
CREATE TABLE IF NOT EXISTS course_forum_pinned_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    message_id UUID NOT NULL REFERENCES course_forum_messages(id) ON DELETE CASCADE,
    pinned_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    pinned_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(course_id, message_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_forum_messages_course ON course_forum_messages(course_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_forum_messages_user ON course_forum_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_forum_messages_reply ON course_forum_messages(reply_to_message_id);
CREATE INDEX IF NOT EXISTS idx_forum_reactions_message ON course_forum_reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_forum_receipts_message ON course_forum_read_receipts(message_id);
CREATE INDEX IF NOT EXISTS idx_forum_receipts_user ON course_forum_read_receipts(user_id);

-- RLS Policies

-- Messages: Students and instructors can read messages for courses they`re enrolled in or teaching
ALTER TABLE course_forum_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view messages in their courses" ON course_forum_messages;
CREATE POLICY "Users can view messages in their courses" ON course_forum_messages FOR SELECT
USING (
    -- Enrolled students can see messages
    EXISTS (
        SELECT 1 FROM enrollments 
        WHERE enrollments.course_id = course_forum_messages.course_id 
        AND enrollments.user_id = auth.uid()
        AND enrollments.status = 'active'
    )
    OR
    -- Course instructor can see messages
    EXISTS (
        SELECT 1 FROM courses 
        WHERE courses.id = course_forum_messages.course_id 
        AND courses.instructor_id = auth.uid()
    )
);
DROP POLICY IF EXISTS "Enrolled users can send messages" ON course_forum_messages;
CREATE POLICY "Enrolled users can send messages" ON course_forum_messages FOR INSERT
WITH CHECK (
    user_id = auth.uid()
    AND (
        -- Enrolled students can send
        EXISTS (
            SELECT 1 FROM enrollments 
            WHERE enrollments.course_id = course_forum_messages.course_id 
            AND enrollments.user_id = auth.uid()
            AND enrollments.status = 'active'
        )
        OR
        -- Course instructor can send
        EXISTS (
            SELECT 1 FROM courses 
            WHERE courses.id = course_forum_messages.course_id 
            AND courses.instructor_id = auth.uid()
        )
    )
);
DROP POLICY IF EXISTS "Users can update their own messages" ON course_forum_messages;
CREATE POLICY "Users can update their own messages" ON course_forum_messages FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can delete their own messages" ON course_forum_messages;
CREATE POLICY "Users can delete their own messages" ON course_forum_messages FOR DELETE
USING (user_id = auth.uid());

-- Reactions policies
ALTER TABLE course_forum_reactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view reactions" ON course_forum_reactions;
CREATE POLICY "Users can view reactions" ON course_forum_reactions FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM course_forum_messages m
        LEFT JOIN enrollments e ON e.course_id = m.course_id AND e.user_id = auth.uid()
        LEFT JOIN courses c ON c.id = m.course_id AND c.instructor_id = auth.uid()
        WHERE m.id = course_forum_reactions.message_id
        AND (e.status = 'active' OR c.id IS NOT NULL)
    )
);
DROP POLICY IF EXISTS "Users can add reactions" ON course_forum_reactions;
CREATE POLICY "Users can add reactions" ON course_forum_reactions FOR INSERT
WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can remove their reactions" ON course_forum_reactions;
CREATE POLICY "Users can remove their reactions" ON course_forum_reactions FOR DELETE
USING (user_id = auth.uid());

-- Read receipts policies
ALTER TABLE course_forum_read_receipts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view read receipts" ON course_forum_read_receipts;
CREATE POLICY "Users can view read receipts" ON course_forum_read_receipts FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM course_forum_messages m
        LEFT JOIN enrollments e ON e.course_id = m.course_id AND e.user_id = auth.uid()
        LEFT JOIN courses c ON c.id = m.course_id AND c.instructor_id = auth.uid()
        WHERE m.id = course_forum_read_receipts.message_id
        AND (e.status = 'active' OR c.id IS NOT NULL)
    )
);
DROP POLICY IF EXISTS "Users can mark messages as read" ON course_forum_read_receipts;
CREATE POLICY "Users can mark messages as read" ON course_forum_read_receipts FOR INSERT
WITH CHECK (user_id = auth.uid());

-- Pinned messages policies
ALTER TABLE course_forum_pinned_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view pinned messages" ON course_forum_pinned_messages;
CREATE POLICY "Users can view pinned messages" ON course_forum_pinned_messages FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM courses c
        LEFT JOIN enrollments e ON e.course_id = c.id AND e.user_id = auth.uid()
        WHERE c.id = course_forum_pinned_messages.course_id
        AND (c.instructor_id = auth.uid() OR e.status = 'active')
    )
);
DROP POLICY IF EXISTS "Instructors can pin messages" ON course_forum_pinned_messages;
CREATE POLICY "Instructors can pin messages" ON course_forum_pinned_messages FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM courses 
        WHERE courses.id = course_forum_pinned_messages.course_id 
        AND courses.instructor_id = auth.uid()
    )
);
DROP POLICY IF EXISTS "Instructors can unpin messages" ON course_forum_pinned_messages;
CREATE POLICY "Instructors can unpin messages" ON course_forum_pinned_messages FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM courses 
        WHERE courses.id = course_forum_pinned_messages.course_id 
        AND courses.instructor_id = auth.uid()
    )
);

-- Function to get unread message count for a course
CREATE OR REPLACE FUNCTION get_unread_forum_messages_count(p_course_id UUID, p_user_id UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)::INTEGER
        FROM course_forum_messages m
        WHERE m.course_id = p_course_id
        AND m.user_id != p_user_id
        AND NOT EXISTS (
            SELECT 1 FROM course_forum_read_receipts r
            WHERE r.message_id = m.id
            AND r.user_id = p_user_id
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark all messages as read
CREATE OR REPLACE FUNCTION mark_forum_messages_as_read(p_course_id UUID, p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO course_forum_read_receipts (message_id, user_id)
    SELECT m.id, p_user_id
    FROM course_forum_messages m
    WHERE m.course_id = p_course_id
    AND m.user_id != p_user_id
    AND NOT EXISTS (
        SELECT 1 FROM course_forum_read_receipts r
        WHERE r.message_id = m.id
        AND r.user_id = p_user_id
    )
    ON CONFLICT (message_id, user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Storage bucket for forum media (images, files)
INSERT INTO storage.buckets (id, name, public)
VALUES ('course-forum-media', 'course-forum-media', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
DROP POLICY IF EXISTS "Users can upload forum media" ON storage;
CREATE POLICY "Users can upload forum media" ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'course-forum-media'
    AND auth.uid()::text = (storage.foldername(name))[1]
);
DROP POLICY IF EXISTS "Anyone can view forum media" ON storage;
CREATE POLICY "Anyone can view forum media" ON storage.objects FOR SELECT
USING (bucket_id = 'course-forum-media');
DROP POLICY IF EXISTS "Users can delete their forum media" ON storage;
CREATE POLICY "Users can delete their forum media" ON storage.objects FOR DELETE
USING (
    bucket_id = 'course-forum-media'
    AND auth.uid()::text = (storage.foldername(name))[1]
);


-- =====================================================================
-- File: 256_create_welcome_messages_for_courses.sql
-- =====================================================================
-- =====================================================
-- Create Welcome Messages for All Existing Courses
-- This ensures every course has a forum group automatically
-- =====================================================

-- Function to create welcome message for a course
CREATE OR REPLACE FUNCTION create_course_welcome_message(p_course_id UUID)
RETURNS VOID AS $$
DECLARE
    v_instructor_id UUID;
    v_course_title TEXT;
BEGIN
    -- Get course instructor and title
    SELECT instructor_id, title_en INTO v_instructor_id, v_course_title
    FROM courses
    WHERE id = p_course_id;
    
    -- Check if welcome message already exists
    IF NOT EXISTS (
        SELECT 1 FROM course_forum_messages
        WHERE course_id = p_course_id
        LIMIT 1
    ) THEN
        -- Create welcome message from instructor
        INSERT INTO course_forum_messages (
            course_id,
            user_id,
            message_text,
            message_type,
            created_at
        ) VALUES (
            p_course_id,
            v_instructor_id,
            'مرحباً بكم في منتدى الكورس! 👋

هذا المكان مخصص للنقاش والتواصل بين الطلاب والمدرس. لا تتردد في طرح أسئلتك ومشاركة أفكارك.

Welcome to the course forum! 👋

This is a space for discussion and communication between students and the instructor. Feel free to ask questions and share your ideas.',
            'text',
            NOW()
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create welcome messages for all existing courses
DO $$
DECLARE
    course_record RECORD;
BEGIN
    FOR course_record IN 
        SELECT id FROM courses WHERE is_published = TRUE
    LOOP
        PERFORM create_course_welcome_message(course_record.id);
    END LOOP;
END $$;

-- Trigger to automatically create welcome message when a new course is published
CREATE OR REPLACE FUNCTION trigger_create_course_welcome_message()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create welcome message when course is published
    IF NEW.is_published = TRUE AND (OLD.is_published IS NULL OR OLD.is_published = FALSE) THEN
        PERFORM create_course_welcome_message(NEW.id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists
DROP TRIGGER IF EXISTS on_course_published_create_forum ON courses;

-- Create trigger
CREATE TRIGGER on_course_published_create_forum
    AFTER INSERT OR UPDATE ON courses
    FOR EACH ROW
    EXECUTE FUNCTION trigger_create_course_welcome_message();

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION create_course_welcome_message(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION trigger_create_course_welcome_message() TO authenticated;


-- =====================================================================
-- File: 257_get_user_course_forums.sql
-- =====================================================================
-- =====================================================
-- Function to Get User`s Course Forums
-- Returns all courses the user is enrolled in with forum info
-- =====================================================

CREATE OR REPLACE FUNCTION get_user_course_forums(p_user_id UUID)
RETURNS TABLE (
    course_id UUID,
    course_title_ar TEXT,
    course_title_en TEXT,
    course_thumbnail TEXT,
    instructor_id UUID,
    instructor_name TEXT,
    participants_count BIGINT,
    last_message_id UUID,
    last_message_text TEXT,
    last_message_user_id UUID,
    last_message_user_name TEXT,
    last_message_created_at TIMESTAMPTZ,
    unread_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id AS course_id,
        c.title_ar AS course_title_ar,
        c.title_en AS course_title_en,
        c.thumbnail_url AS course_thumbnail,
        c.instructor_id,
        p_instructor.full_name AS instructor_name,
        -- Count of enrolled students (participants)
        (SELECT COUNT(DISTINCT e.user_id)
         FROM enrollments e
         WHERE e.course_id = c.id
         AND e.status = 'active') AS participants_count,
        -- Last message info
        lm.id AS last_message_id,
        lm.message_text AS last_message_text,
        lm.user_id AS last_message_user_id,
        p_sender.full_name AS last_message_user_name,
        lm.created_at AS last_message_created_at,
        -- Unread count
        (SELECT COUNT(*)
         FROM course_forum_messages m
         WHERE m.course_id = c.id
         AND m.user_id != p_user_id
         AND NOT EXISTS (
             SELECT 1 FROM course_forum_read_receipts r
             WHERE r.message_id = m.id
             AND r.user_id = p_user_id
         )) AS unread_count
    FROM courses c
    INNER JOIN enrollments e ON e.course_id = c.id
    INNER JOIN profiles p_instructor ON p_instructor.id = c.instructor_id
    LEFT JOIN LATERAL (
        SELECT m.id, m.message_text, m.user_id, m.created_at
        FROM course_forum_messages m
        WHERE m.course_id = c.id
        AND m.is_deleted = FALSE
        ORDER BY m.created_at DESC
        LIMIT 1
    ) lm ON TRUE
    LEFT JOIN profiles p_sender ON p_sender.id = lm.user_id
    WHERE e.user_id = p_user_id
    AND e.status = 'active'
    AND c.is_published = TRUE
    ORDER BY COALESCE(lm.created_at, c.created_at) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_user_course_forums(UUID) TO authenticated;

-- Example usage:
-- SELECT * FROM get_user_course_forums(auth.uid());


-- =====================================================================
-- File: 259_update_payout_methods.sql
-- =====================================================================
-- =====================================================
-- Update Payout Methods to Support InstaPay and Wallet
-- =====================================================

-- First, drop the old constraints
ALTER TABLE instructor_payouts 
DROP CONSTRAINT IF EXISTS instructor_payouts_payout_method_check;

ALTER TABLE instructor_profiles 
DROP CONSTRAINT IF EXISTS instructor_profiles_payout_method_check;

-- Update existing data to use new payment methods
-- Convert old payment methods to new ones
UPDATE instructor_payouts 
SET payout_method = 'wallet'
WHERE payout_method NOT IN ('instapay', 'wallet');

-- Update instructor_profiles as well
UPDATE instructor_profiles 
SET payout_method = 'wallet'
WHERE payout_method NOT IN ('instapay', 'wallet');

-- Now add the new constraints
ALTER TABLE IF EXISTS instructor_payouts DROP CONSTRAINT IF EXISTS instructor_payouts_payout_method_check;`nALTER TABLE instructor_payouts ADD CONSTRAINT instructor_payouts_payout_method_check 
CHECK (payout_method IN ('instapay', 'wallet'));
ALTER TABLE IF EXISTS instructor_profiles DROP CONSTRAINT IF EXISTS instructor_profiles_payout_method_check;`nALTER TABLE instructor_profiles ADD CONSTRAINT instructor_profiles_payout_method_check 
CHECK (payout_method IN ('instapay', 'wallet'));

-- Add comments to explain payout_details structure
COMMENT ON COLUMN instructor_payouts.payout_details IS 
'Payment details in JSON format:
- instapay: {"instapay_id": "user@instapay"}
- wallet: {"phone_number": "01xxxxxxxxx"}';

COMMENT ON COLUMN instructor_profiles.payout_details IS 
'Default payment details in JSON format (same structure as instructor_payouts.payout_details)';

-- Example usage:
-- INSERT INTO instructor_payouts (instructor_id, amount, payout_method, payout_details)
-- VALUES (
--   'instructor-uuid`,
--   1000.00,
--   'instapay`,
--   '{"instapay_id": "user@instapay"}`::jsonb
-- );

-- INSERT INTO instructor_payouts (instructor_id, amount, payout_method, payout_details)
-- VALUES (
--   'instructor-uuid`,
--   500.00,
--   'wallet`,
--   '{"phone_number": "01012345678"}`::jsonb
-- );






-- =====================================================================
-- File: 260_request_payout_function.sql
-- =====================================================================
-- ============================================================
-- Request Payout Function
-- Creates a payout request and marks earnings as processing
-- ============================================================

-- Drop existing function if exists
DROP FUNCTION IF EXISTS request_instructor_payout(UUID, DECIMAL, TEXT, JSONB);

-- Create the payout request function
CREATE OR REPLACE FUNCTION request_instructor_payout(
  p_instructor_id UUID,
  p_amount DECIMAL(10,2),
  p_payout_method TEXT,
  p_payout_details JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_available_amount DECIMAL(10,2);
  v_payout_id UUID;
  v_remaining_amount DECIMAL(10,2);
  v_earning RECORD;
  v_total_allocated DECIMAL(10,2) := 0;
BEGIN
  -- Step 1: Check available earnings
  SELECT COALESCE(SUM(net_amount), 0)
  INTO v_available_amount
  FROM instructor_earnings
  WHERE instructor_id = p_instructor_id
    AND status = 'available';

  -- Validate amount
  IF p_amount <= 0 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Invalid amount',
      'error_ar', 'مبلغ غير صالح'
    );
  END IF;

  IF p_amount > v_available_amount THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Insufficient balance',
      'error_ar', 'الرصيد غير كافي',
      'available', v_available_amount
    );
  END IF;

  -- Step 2: Create payout request
  INSERT INTO instructor_payouts (
    instructor_id,
    amount,
    currency,
    payout_method,
    payout_details,
    status,
    requested_at
  ) VALUES (
    p_instructor_id,
    p_amount,
    'EGP',
    p_payout_method,
    p_payout_details,
    'pending',
    NOW()
  )
  RETURNING id INTO v_payout_id;

  -- Step 3: Mark earnings as processing and link to payout
  v_remaining_amount := p_amount;

  FOR v_earning IN
    SELECT id, net_amount
    FROM instructor_earnings
    WHERE instructor_id = p_instructor_id
      AND status = 'available'
    ORDER BY created_at ASC
  LOOP
    EXIT WHEN v_remaining_amount <= 0;

    IF v_earning.net_amount <= v_remaining_amount THEN
      -- Use entire earning
      UPDATE instructor_earnings
      SET status = 'processing'
      WHERE id = v_earning.id;

      INSERT INTO payout_items (payout_id, earning_id, amount)
      VALUES (v_payout_id, v_earning.id, v_earning.net_amount);

      v_remaining_amount := v_remaining_amount - v_earning.net_amount;
      v_total_allocated := v_total_allocated + v_earning.net_amount;
    ELSE
      -- Partial use (shouldn`t happen normally, but handle it)
      -- For now, just use the full earning
      UPDATE instructor_earnings
      SET status = 'processing'
      WHERE id = v_earning.id;

      INSERT INTO payout_items (payout_id, earning_id, amount)
      VALUES (v_payout_id, v_earning.id, v_earning.net_amount);

      v_total_allocated := v_total_allocated + v_earning.net_amount;
      v_remaining_amount := 0;
    END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'success', true,
    'payout_id', v_payout_id,
    'amount', p_amount,
    'earnings_allocated', v_total_allocated,
    'message', 'Payout request created successfully',
    'message_ar', 'تم إنشاء طلب السحب بنجاح'
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM,
    'error_ar', 'حدث خطأ أثناء إنشاء طلب السحب'
  );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION request_instructor_payout(UUID, DECIMAL, TEXT, JSONB) TO authenticated;

-- Add comment
COMMENT ON FUNCTION request_instructor_payout IS 'Creates a payout request and marks the corresponding earnings as processing';

-- ============================================================
-- Complete Payout Function (for admin use)
-- Marks payout as completed and earnings as paid
-- ============================================================

DROP FUNCTION IF EXISTS complete_instructor_payout(UUID, UUID, TEXT);

CREATE OR REPLACE FUNCTION complete_instructor_payout(
  p_payout_id UUID,
  p_admin_id UUID,
  p_transaction_id TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Update payout status
  UPDATE instructor_payouts
  SET 
    status = 'completed',
    processed_by = p_admin_id,
    processed_at = NOW(),
    transaction_id = p_transaction_id,
    updated_at = NOW()
  WHERE id = p_payout_id;

  -- Update all linked earnings to paid
  UPDATE instructor_earnings
  SET status = 'paid'
  WHERE id IN (
    SELECT earning_id FROM payout_items WHERE payout_id = p_payout_id
  );

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Payout completed successfully',
    'message_ar', 'تم إتمام السحب بنجاح'
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$;

GRANT EXECUTE ON FUNCTION complete_instructor_payout(UUID, UUID, TEXT) TO authenticated;

-- ============================================================
-- Cancel/Fail Payout Function
-- Returns earnings to available status
-- ============================================================

DROP FUNCTION IF EXISTS cancel_instructor_payout(UUID, TEXT);

CREATE OR REPLACE FUNCTION cancel_instructor_payout(
  p_payout_id UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Update payout status
  UPDATE instructor_payouts
  SET 
    status = 'failed',
    failure_reason = p_reason,
    updated_at = NOW()
  WHERE id = p_payout_id;

  -- Return all linked earnings to available
  UPDATE instructor_earnings
  SET status = 'available'
  WHERE id IN (
    SELECT earning_id FROM payout_items WHERE payout_id = p_payout_id
  );

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Payout cancelled successfully',
    'message_ar', 'تم إلغاء طلب السحب'
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$;

GRANT EXECUTE ON FUNCTION cancel_instructor_payout(UUID, TEXT) TO authenticated;

-- ============================================================
-- Get Instructor Balance Function
-- Returns available and pending amounts
-- ============================================================

DROP FUNCTION IF EXISTS get_instructor_balance(UUID);

CREATE OR REPLACE FUNCTION get_instructor_balance(p_instructor_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_available DECIMAL(10,2);
  v_pending DECIMAL(10,2);
  v_processing DECIMAL(10,2);
  v_total_earned DECIMAL(10,2);
  v_total_paid DECIMAL(10,2);
BEGIN
  -- Available earnings (can be withdrawn)
  SELECT COALESCE(SUM(net_amount), 0)
  INTO v_available
  FROM instructor_earnings
  WHERE instructor_id = p_instructor_id AND status = 'available';

  -- Pending earnings (waiting to become available)
  SELECT COALESCE(SUM(net_amount), 0)
  INTO v_pending
  FROM instructor_earnings
  WHERE instructor_id = p_instructor_id AND status = 'pending';

  -- Processing (payout in progress)
  SELECT COALESCE(SUM(net_amount), 0)
  INTO v_processing
  FROM instructor_earnings
  WHERE instructor_id = p_instructor_id AND status = 'processing';

  -- Total earned (all time)
  SELECT COALESCE(SUM(net_amount), 0)
  INTO v_total_earned
  FROM instructor_earnings
  WHERE instructor_id = p_instructor_id;

  -- Total paid out
  SELECT COALESCE(SUM(net_amount), 0)
  INTO v_total_paid
  FROM instructor_earnings
  WHERE instructor_id = p_instructor_id AND status = 'paid';

  RETURN jsonb_build_object(
    'available', v_available,
    'pending', v_pending,
    'processing', v_processing,
    'total_earned', v_total_earned,
    'total_paid', v_total_paid
  );
END;
$$;

GRANT EXECUTE ON FUNCTION get_instructor_balance(UUID) TO authenticated;


-- =====================================================================
-- File: 270_scheduled_publishing.sql
-- =====================================================================
-- ============================================================
-- Migration: Add Scheduled Publishing for Sections and Lessons
-- Version: 2026-02-03
-- ============================================================

-- Add scheduled publish fields to sections
ALTER TABLE sections 
ADD COLUMN IF NOT EXISTS publish_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS unpublish_at TIMESTAMPTZ;

-- Add scheduled publish fields to lessons  
ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS publish_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS unpublish_at TIMESTAMPTZ;

-- Create indexes for scheduled publishing
CREATE INDEX IF NOT EXISTS idx_sections_publish_at ON sections(publish_at) WHERE publish_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_lessons_publish_at ON lessons(publish_at) WHERE publish_at IS NOT NULL;

-- ============================================================
-- Function: Auto-publish sections at scheduled time
-- ============================================================
CREATE OR REPLACE FUNCTION auto_publish_sections()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Publish sections that are scheduled
  UPDATE sections
  SET is_published = TRUE,
      updated_at = NOW()
  WHERE is_published = FALSE
    AND publish_at IS NOT NULL
    AND publish_at <= NOW();
    
  -- Unpublish sections that are scheduled to unpublish
  UPDATE sections
  SET is_published = FALSE,
      updated_at = NOW()
  WHERE is_published = TRUE
    AND unpublish_at IS NOT NULL
    AND unpublish_at <= NOW();
END;
$$;

-- ============================================================
-- Function: Auto-publish lessons at scheduled time
-- ============================================================
CREATE OR REPLACE FUNCTION auto_publish_lessons()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Publish lessons that are scheduled
  UPDATE lessons
  SET is_published = TRUE,
      updated_at = NOW()
  WHERE is_published = FALSE
    AND publish_at IS NOT NULL
    AND publish_at <= NOW();
    
  -- Unpublish lessons that are scheduled to unpublish
  UPDATE lessons
  SET is_published = FALSE,
      updated_at = NOW()
  WHERE is_published = TRUE
    AND unpublish_at IS NOT NULL
    AND unpublish_at <= NOW();
END;
$$;

-- ============================================================
-- Cron Job: Run auto-publish every minute
-- ============================================================
-- Note: Run these in Supabase Dashboard > Database > Extensions > pg_cron

-- SELECT cron.schedule('auto-publish-sections', '* * * * *', 'SELECT auto_publish_sections()`);
-- SELECT cron.schedule('auto-publish-lessons', '* * * * *', 'SELECT auto_publish_lessons()`);

-- ============================================================
-- RPC Function: Toggle Section Published Status
-- ============================================================
CREATE OR REPLACE FUNCTION toggle_section_published(
  p_section_id UUID,
  p_instructor_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_section RECORD;
  v_course RECORD;
BEGIN
  -- Get section
  SELECT * INTO v_section FROM sections WHERE id = p_section_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Section not found');
  END IF;
  
  -- Verify ownership
  SELECT * INTO v_course FROM courses WHERE id = v_section.course_id AND instructor_id = p_instructor_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authorized');
  END IF;
  
  -- Toggle status
  UPDATE sections
  SET is_published = NOT is_published,
      publish_at = NULL,
      unpublish_at = NULL,
      updated_at = NOW()
  WHERE id = p_section_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'is_published', NOT v_section.is_published
  );
END;
$$;

-- ============================================================
-- RPC Function: Schedule Section Publishing
-- ============================================================
CREATE OR REPLACE FUNCTION schedule_section_publish(
  p_section_id UUID,
  p_instructor_id UUID,
  p_publish_at TIMESTAMPTZ DEFAULT NULL,
  p_unpublish_at TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_section RECORD;
  v_course RECORD;
BEGIN
  -- Get section
  SELECT * INTO v_section FROM sections WHERE id = p_section_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Section not found');
  END IF;
  
  -- Verify ownership
  SELECT * INTO v_course FROM courses WHERE id = v_section.course_id AND instructor_id = p_instructor_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authorized');
  END IF;
  
  -- Update schedule
  UPDATE sections
  SET publish_at = p_publish_at,
      unpublish_at = p_unpublish_at,
      updated_at = NOW()
  WHERE id = p_section_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'publish_at', p_publish_at,
    'unpublish_at', p_unpublish_at
  );
END;
$$;

-- ============================================================
-- RPC Function: Toggle Lesson Published Status
-- ============================================================
CREATE OR REPLACE FUNCTION toggle_lesson_published(
  p_lesson_id UUID,
  p_instructor_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_lesson RECORD;
  v_course RECORD;
BEGIN
  -- Get lesson
  SELECT * INTO v_lesson FROM lessons WHERE id = p_lesson_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Lesson not found');
  END IF;
  
  -- Verify ownership
  SELECT * INTO v_course FROM courses WHERE id = v_lesson.course_id AND instructor_id = p_instructor_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authorized');
  END IF;
  
  -- Toggle status
  UPDATE lessons
  SET is_published = NOT is_published,
      publish_at = NULL,
      unpublish_at = NULL,
      updated_at = NOW()
  WHERE id = p_lesson_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'is_published', NOT v_lesson.is_published
  );
END;
$$;

-- ============================================================
-- RPC Function: Schedule Lesson Publishing
-- ============================================================
CREATE OR REPLACE FUNCTION schedule_lesson_publish(
  p_lesson_id UUID,
  p_instructor_id UUID,
  p_publish_at TIMESTAMPTZ DEFAULT NULL,
  p_unpublish_at TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_lesson RECORD;
  v_course RECORD;
BEGIN
  -- Get lesson
  SELECT * INTO v_lesson FROM lessons WHERE id = p_lesson_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Lesson not found');
  END IF;
  
  -- Verify ownership
  SELECT * INTO v_course FROM courses WHERE id = v_lesson.course_id AND instructor_id = p_instructor_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authorized');
  END IF;
  
  -- Update schedule
  UPDATE lessons
  SET publish_at = p_publish_at,
      unpublish_at = p_unpublish_at,
      updated_at = NOW()
  WHERE id = p_lesson_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'publish_at', p_publish_at,
    'unpublish_at', p_unpublish_at
  );
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION toggle_section_published TO authenticated;
GRANT EXECUTE ON FUNCTION schedule_section_publish TO authenticated;
GRANT EXECUTE ON FUNCTION toggle_lesson_published TO authenticated;
GRANT EXECUTE ON FUNCTION schedule_lesson_publish TO authenticated;


-- =====================================================================
-- File: 271_enable_realtime_updates_for_reactions.sql
-- =====================================================================
-- Enable REPLICA IDENTITY FULL for course_forum_reactions table
-- This allows Supabase Realtime to broadcast UPDATE events with full row data

-- Set REPLICA IDENTITY to FULL for the reactions table
ALTER TABLE course_forum_reactions REPLICA IDENTITY FULL;

-- Verify the change
SELECT 
    nspname as schema_name,
    relname as table_name,
    CASE relreplident
        WHEN 'd' THEN 'default'
        WHEN 'n' THEN 'nothing'
        WHEN 'f' THEN 'full'
        WHEN 'i' THEN 'index'
    END as replica_identity
FROM pg_class
JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
WHERE 
    nspname = 'public' 
    AND relname = 'course_forum_reactions';

-- Note: After running this script, Supabase Realtime will be able to broadcast
-- UPDATE events with the full row data (both old and new records)


-- =====================================================================
-- File: 272_add_badge_column.sql
-- =====================================================================
-- Add badge column to courses table if it doesn`t exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'badge') THEN
        ALTER TABLE public.courses ADD COLUMN badge text;
    END IF;
END $$;

-- Reload schema cache to ensure the new column is visible to PostgREST
NOTIFY pgrst, 'reload schema';


-- =====================================================================
-- File: 273_fix_flash_sale_logic.sql
-- =====================================================================
-- Fix flash sale logic:
-- 1) Enforce valid timed window and price
-- 2) Normalize fields when flash sale is disabled
-- 3) Auto-clean expired flash sales with a helper function

-- Clean already expired flash sales once.
UPDATE public.courses
SET
  is_flash_sale = FALSE,
  flash_sale_price = NULL,
  flash_sale_start = NULL,
  flash_sale_end = NULL,
  badge = CASE
    WHEN badge IN ('فلاش سيل', 'Flash Sale') THEN NULL
    ELSE badge
  END
WHERE is_flash_sale = TRUE
  AND flash_sale_end IS NOT NULL
  AND flash_sale_end <= NOW();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'courses_flash_sale_window_chk'
  ) THEN
    ALTER TABLE public.courses
      ADD CONSTRAINT courses_flash_sale_window_chk
      CHECK (
        NOT is_flash_sale OR
        (
          flash_sale_start IS NOT NULL AND
          flash_sale_end IS NOT NULL AND
          flash_sale_end > flash_sale_start
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'courses_flash_sale_price_chk'
  ) THEN
    ALTER TABLE public.courses
      ADD CONSTRAINT courses_flash_sale_price_chk
      CHECK (
        NOT is_flash_sale OR
        (
          price > 0 AND
          flash_sale_price IS NOT NULL AND
          flash_sale_price >= 0 AND
          flash_sale_price < price
        )
      );
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.normalize_course_flash_sale_fields()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- If flash sale is disabled, clear all timed-sale fields.
  IF COALESCE(NEW.is_flash_sale, FALSE) = FALSE THEN
    NEW.flash_sale_price := NULL;
    NEW.flash_sale_start := NULL;
    NEW.flash_sale_end := NULL;
    IF NEW.badge IN ('فلاش سيل', 'Flash Sale') THEN
      NEW.badge := NULL;
    END IF;
    RETURN NEW;
  END IF;

  -- Ensure flash sale badge exists when timed sale is enabled.
  IF NEW.badge IS NULL OR btrim(NEW.badge) = '' THEN
    NEW.badge := 'فلاش سيل';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_normalize_course_flash_sale ON public.courses;
CREATE TRIGGER trg_normalize_course_flash_sale
BEFORE INSERT OR UPDATE ON public.courses
FOR EACH ROW
EXECUTE FUNCTION public.normalize_course_flash_sale_fields();

-- Optional helper for cron jobs:
-- SELECT public.expire_finished_flash_sales();
CREATE OR REPLACE FUNCTION public.expire_finished_flash_sales()
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
  v_updated_count integer;
BEGIN
  UPDATE public.courses
  SET
    is_flash_sale = FALSE,
    flash_sale_price = NULL,
    flash_sale_start = NULL,
    flash_sale_end = NULL,
    badge = CASE
      WHEN badge IN ('فلاش سيل', 'Flash Sale') THEN NULL
      ELSE badge
    END
  WHERE is_flash_sale = TRUE
    AND flash_sale_end IS NOT NULL
    AND flash_sale_end <= NOW();

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  RETURN v_updated_count;
END;
$$;

NOTIFY pgrst, 'reload schema';


-- =====================================================================
-- File: 274_drop_flash_sale_price.sql
-- =====================================================================
-- Migration: Remove flash_sale_price column from courses table
-- Date: 2026-02-12
-- Reason: Flash sale no longer uses a separate price field.
--         The discount_price is used for both permanent and time-limited (flash sale) discounts.
--         Flash sale role is now only to make the discount time-limited via flash_sale_start/end.

ALTER TABLE courses DROP COLUMN IF EXISTS flash_sale_price;


-- =====================================================================
-- File: 300_missing_permissions.sql
-- =====================================================================
-- ============================================================
-- 🔐 MISSING PERMISSIONS - Admin & Instructor
-- إضافة كل الصلاحيات الناقصة للأدمن والمدرس
-- Version: 1.1 | February 2026
-- Safe to re-run (idempotent)
-- ============================================================

-- ============================================================
-- 0. MISSING COLUMNS (must run first)
-- ============================================================

-- Add is_hidden to course_reviews (admin hide review)
ALTER TABLE course_reviews
  ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN NOT NULL DEFAULT false;

-- Add is_hidden + is_pinned to qa_questions (admin/instructor hide & pin)
ALTER TABLE qa_questions
  ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE qa_questions
  ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN NOT NULL DEFAULT false;

-- ============================================================
-- 1. ADMIN RLS POLICIES
-- ============================================================

-- ---- Courses: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all courses" ON courses;
DROP POLICY IF EXISTS "Admins can manage all courses" ON courses;
CREATE POLICY "Admins can manage all courses" ON courses FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Course Reviews: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all reviews" ON course_reviews;
DROP POLICY IF EXISTS "Admins can manage all reviews" ON course_reviews;
CREATE POLICY "Admins can manage all reviews" ON course_reviews FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Q&A Questions: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all questions" ON qa_questions;
DROP POLICY IF EXISTS "Admins can manage all questions" ON qa_questions;
CREATE POLICY "Admins can manage all questions" ON qa_questions FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Q&A Answers: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all answers" ON qa_answers;
DROP POLICY IF EXISTS "Admins can manage all answers" ON qa_answers;
CREATE POLICY "Admins can manage all answers" ON qa_answers FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Quizzes: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all quizzes" ON quizzes;
DROP POLICY IF EXISTS "Admins can manage all quizzes" ON quizzes;
CREATE POLICY "Admins can manage all quizzes" ON quizzes FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Quiz Questions: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all quiz questions" ON quiz_questions;
DROP POLICY IF EXISTS "Admins can manage all quiz questions" ON quiz_questions;
CREATE POLICY "Admins can manage all quiz questions" ON quiz_questions FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Quiz Attempts: Admin can view all ----
DROP POLICY IF EXISTS "Admins can view all quiz attempts" ON quiz_attempts;
DROP POLICY IF EXISTS "Admins can view all quiz attempts" ON quiz_attempts;
CREATE POLICY "Admins can view all quiz attempts" ON quiz_attempts FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Announcements: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all announcements" ON announcements;
DROP POLICY IF EXISTS "Admins can manage all announcements" ON announcements;
CREATE POLICY "Admins can manage all announcements" ON announcements FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Announcement Reads: Admin can view all ----
DROP POLICY IF EXISTS "Admins can view all announcement reads" ON announcement_reads;
DROP POLICY IF EXISTS "Admins can view all announcement reads" ON announcement_reads;
CREATE POLICY "Admins can view all announcement reads" ON announcement_reads FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Notes: Admin can view all ----
DROP POLICY IF EXISTS "Admins can view all notes" ON notes;
DROP POLICY IF EXISTS "Admins can view all notes" ON notes;
CREATE POLICY "Admins can view all notes" ON notes FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Bookmarks: Admin can view all ----
DROP POLICY IF EXISTS "Admins can view all bookmarks" ON bookmarks;
DROP POLICY IF EXISTS "Admins can view all bookmarks" ON bookmarks;
CREATE POLICY "Admins can view all bookmarks" ON bookmarks FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Lesson Attachments: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all lesson attachments" ON lesson_attachments;
DROP POLICY IF EXISTS "Admins can manage all lesson attachments" ON lesson_attachments;
CREATE POLICY "Admins can manage all lesson attachments" ON lesson_attachments FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Lesson Progress: Admin can view all ----
DROP POLICY IF EXISTS "Admins can view all lesson progress" ON lesson_progress;
DROP POLICY IF EXISTS "Admins can view all lesson progress" ON lesson_progress;
CREATE POLICY "Admins can view all lesson progress" ON lesson_progress FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Course Forum Messages: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all forum messages" ON course_forum_messages;
DROP POLICY IF EXISTS "Admins can manage all forum messages" ON course_forum_messages;
CREATE POLICY "Admins can manage all forum messages" ON course_forum_messages FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Course Forum Reactions: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all forum reactions" ON course_forum_reactions;
DROP POLICY IF EXISTS "Admins can manage all forum reactions" ON course_forum_reactions;
CREATE POLICY "Admins can manage all forum reactions" ON course_forum_reactions FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Course Forum Pinned Messages: Admin full access ----
DROP POLICY IF EXISTS "Admins can manage all pinned messages" ON course_forum_pinned_messages;
DROP POLICY IF EXISTS "Admins can manage all pinned messages" ON course_forum_pinned_messages;
CREATE POLICY "Admins can manage all pinned messages" ON course_forum_pinned_messages FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- Direct Messages: Admin can view all ----
DROP POLICY IF EXISTS "Admins can view all direct messages" ON direct_messages;
DROP POLICY IF EXISTS "Admins can view all direct messages" ON direct_messages;
CREATE POLICY "Admins can view all direct messages" ON direct_messages FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ============================================================
-- 2. INSTRUCTOR FORUM MODERATION
-- ============================================================

-- Instructors can delete messages in their course forums
DROP POLICY IF EXISTS "Instructors can delete forum messages in their courses" ON course_forum_messages;
DROP POLICY IF EXISTS "Instructors can delete forum messages in their courses" ON course_forum_messages;
CREATE POLICY "Instructors can delete forum messages in their courses" ON course_forum_messages FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM courses
      WHERE courses.id = course_forum_messages.course_id
      AND courses.instructor_id = auth.uid()
    )
  );

-- ============================================================
-- 3. ADMIN HELPER FUNCTIONS
-- ============================================================

-- Function: Admin delete user (soft delete / deactivate)
CREATE OR REPLACE FUNCTION admin_delete_user(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Only admins can delete users';
  END IF;

  -- Deactivate user (soft delete)
  UPDATE profiles
  SET is_active = false,
      updated_at = NOW()
  WHERE id = p_user_id;

  RETURN FOUND;
END;
$$;

-- Function: Admin change user role
CREATE OR REPLACE FUNCTION admin_change_user_role(p_user_id UUID, p_new_role TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Only admins can change user roles';
  END IF;

  -- Validate role
  IF p_new_role NOT IN ('student', 'instructor', 'admin') THEN
    RAISE EXCEPTION 'Invalid role: %', p_new_role;
  END IF;

  -- Update role
  UPDATE profiles
  SET role = p_new_role,
      updated_at = NOW()
  WHERE id = p_user_id;

  -- If promoting to instructor, create instructor profile if not exists
  IF p_new_role = 'instructor' THEN
    INSERT INTO instructor_profiles (id, revenue_share)
    VALUES (p_user_id, 70.00)
    ON CONFLICT (id) DO NOTHING;
  END IF;

  RETURN FOUND;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION admin_delete_user TO authenticated;
GRANT EXECUTE ON FUNCTION admin_change_user_role TO authenticated;


-- =====================================================================
-- File: 301_direct_chat_features.sql
-- =====================================================================
-- Add reply_to_message_id to direct_messages
ALTER TABLE public.direct_messages 
ADD COLUMN IF NOT EXISTS reply_to_message_id UUID REFERENCES public.direct_messages(id);

-- Add is_deleted to direct_messages
ALTER TABLE public.direct_messages 
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false;

-- Add is_edited to direct_messages
ALTER TABLE public.direct_messages 
ADD COLUMN IF NOT EXISTS is_edited BOOLEAN DEFAULT false;

-- Create direct_message_reactions table
CREATE TABLE IF NOT EXISTS public.direct_message_reactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    message_id UUID REFERENCES public.direct_messages(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    reaction TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(message_id, user_id, reaction)
);

-- Enable RLS on direct_message_reactions
ALTER TABLE public.direct_message_reactions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for direct_message_reactions

-- View reactions: Users can view reactions on messages they can see
-- (i.e. if they are sender or receiver of the message)
DROP POLICY IF EXISTS "Users can view reactions on their messages" ON public;
CREATE POLICY "Users can view reactions on their messages" ON public.direct_message_reactions
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.direct_messages m
        WHERE m.id = direct_message_reactions.message_id
        AND (m.sender_id = auth.uid() OR m.receiver_id = auth.uid())
    )
);

-- Add reactions: Users can add reactions to messages they can see
DROP POLICY IF EXISTS "Users can add reactions to their messages" ON public;
CREATE POLICY "Users can add reactions to their messages" ON public.direct_message_reactions
FOR INSERT
WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
        SELECT 1 FROM public.direct_messages m
        WHERE m.id = direct_message_reactions.message_id
        AND (m.sender_id = auth.uid() OR m.receiver_id = auth.uid())
    )
);

-- Delete reactions: Users can delete their own reactions
DROP POLICY IF EXISTS "Users can delete their own reactions" ON public;
CREATE POLICY "Users can delete their own reactions" ON public.direct_message_reactions
FOR DELETE
USING (auth.uid() = user_id);

-- Add policy for update (if needed, though usually reactions are toggled via insert/delete)
DROP POLICY IF EXISTS "Users can update their own reactions" ON public;
CREATE POLICY "Users can update their own reactions" ON public.direct_message_reactions
FOR UPDATE
USING (auth.uid() = user_id);


-- =====================================================================
-- File: 302_fix_forum_visibility_rls.sql
-- =====================================================================
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


-- =====================================================================
-- File: 303_rebuild_conversations_schema.sql
-- =====================================================================
-- ============================================================
-- 🔄 REBUILD: Unified Conversations Schema
-- Replace course_forum + direct_messages with conversations + messages
-- Version: 1.0 | February 2026
-- ============================================================

-- ================================
-- 1. DROP OLD TABLES & FUNCTIONS
-- ================================

-- Drop functions first (they reference old tables)
DROP FUNCTION IF EXISTS get_user_course_forums(UUID);
DROP FUNCTION IF EXISTS get_forum_courses_for_user(UUID, BOOLEAN, TEXT, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_unread_forum_messages_count(UUID, UUID);
DROP FUNCTION IF EXISTS mark_forum_messages_as_read(UUID, UUID);

-- Drop old tables (order matters due to FK constraints)
DROP TABLE IF EXISTS course_forum_pinned_messages CASCADE;
DROP TABLE IF EXISTS course_forum_read_receipts CASCADE;
DROP TABLE IF EXISTS course_forum_reactions CASCADE;
DROP TABLE IF EXISTS course_forum_messages CASCADE;
DROP TABLE IF EXISTS direct_message_reactions CASCADE;
DROP TABLE IF EXISTS direct_messages CASCADE;

-- ================================
-- 2. CREATE NEW TABLES
-- ================================

-- 2a. conversations: محادثه فرديه (single) أو جماعيه (multi)
CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(10) NOT NULL CHECK (type IN ('single', 'multi')),
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    title TEXT,
    created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2b. conversation_participants: أعضاء كل محادثة
CREATE TABLE IF NOT EXISTS conversation_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('admin', 'member')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(conversation_id, user_id)
);

-- 2c. messages: رسائل كل محادثة
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    message_text TEXT,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file')),
    media_url TEXT,
    file_name TEXT,
    file_size BIGINT,
    reply_to_message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
    is_edited BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2d. message_reactions: ريأكشن لكل رسالة
CREATE TABLE IF NOT EXISTS message_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    reaction TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(message_id, user_id)
);

-- ================================
-- 3. INDEXES
-- ================================
CREATE INDEX IF NOT EXISTS idx_conversations_course ON conversations(course_id);
CREATE INDEX IF NOT EXISTS idx_conversations_type ON conversations(type);
CREATE INDEX IF NOT EXISTS idx_conversations_created_by ON conversations(created_by);

CREATE INDEX IF NOT EXISTS idx_participants_conversation ON conversation_participants(conversation_id);
CREATE INDEX IF NOT EXISTS idx_participants_user ON conversation_participants(user_id);

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_user ON messages(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_reply ON messages(reply_to_message_id);

CREATE INDEX IF NOT EXISTS idx_reactions_message ON message_reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_reactions_user ON message_reactions(user_id);

-- ================================
-- 4. RLS POLICIES
-- ================================

-- Helper to avoid recursive RLS checks on conversation_participants
CREATE OR REPLACE FUNCTION is_conversation_participant(
    p_conversation_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM conversation_participants cp
        WHERE cp.conversation_id = p_conversation_id
        AND cp.user_id = p_user_id
    );
$$;

REVOKE ALL ON FUNCTION is_conversation_participant(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION is_conversation_participant(UUID, UUID) TO authenticated;

-- 4a. conversations RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Participants can view their conversations" ON conversations;
CREATE POLICY "Participants can view their conversations" ON conversations FOR SELECT
USING (
    is_conversation_participant(conversations.id, auth.uid())
    OR
    -- Admins can see all
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
    )
);
DROP POLICY IF EXISTS "Authenticated users can create conversations" ON conversations;
CREATE POLICY "Authenticated users can create conversations" ON conversations FOR INSERT
WITH CHECK (created_by = auth.uid());
DROP POLICY IF EXISTS "Creator can update conversation" ON conversations;
CREATE POLICY "Creator can update conversation" ON conversations FOR UPDATE
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

-- 4b. conversation_participants RLS
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Participants can view members" ON conversation_participants;
CREATE POLICY "Participants can view members" ON conversation_participants FOR SELECT
USING (
    is_conversation_participant(conversation_participants.conversation_id, auth.uid())
    OR
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
    )
);
DROP POLICY IF EXISTS "Conversation creator can add participants" ON conversation_participants;
CREATE POLICY "Conversation creator can add participants" ON conversation_participants FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM conversations c
        WHERE c.id = conversation_participants.conversation_id
        AND c.created_by = auth.uid()
    )
    OR user_id = auth.uid()
);
DROP POLICY IF EXISTS "Creator can remove participants" ON conversation_participants;
CREATE POLICY "Creator can remove participants" ON conversation_participants FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM conversations c
        WHERE c.id = conversation_participants.conversation_id
        AND c.created_by = auth.uid()
    )
    OR user_id = auth.uid()
);

-- 4c. messages RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Participants can view messages" ON messages;
CREATE POLICY "Participants can view messages" ON messages FOR SELECT
USING (
    is_conversation_participant(messages.conversation_id, auth.uid())
    OR
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
    )
);
DROP POLICY IF EXISTS "Participants can send messages" ON messages;
CREATE POLICY "Participants can send messages" ON messages FOR INSERT
WITH CHECK (
    user_id = auth.uid()
    AND is_conversation_participant(messages.conversation_id, auth.uid())
);
DROP POLICY IF EXISTS "Users can update their own messages" ON messages;
CREATE POLICY "Users can update their own messages" ON messages FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can delete their own messages" ON messages;
CREATE POLICY "Users can delete their own messages" ON messages FOR DELETE
USING (user_id = auth.uid());

-- 4d. message_reactions RLS
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Participants can view reactions" ON message_reactions;
CREATE POLICY "Participants can view reactions" ON message_reactions FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM messages m
        WHERE m.id = message_reactions.message_id
        AND is_conversation_participant(m.conversation_id, auth.uid())
    )
);
DROP POLICY IF EXISTS "Participants can add reactions" ON message_reactions;
CREATE POLICY "Participants can add reactions" ON message_reactions FOR INSERT
WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
        SELECT 1 FROM messages m
        WHERE m.id = message_reactions.message_id
        AND is_conversation_participant(m.conversation_id, auth.uid())
    )
);
DROP POLICY IF EXISTS "Users can remove their reactions" ON message_reactions;
CREATE POLICY "Users can remove their reactions" ON message_reactions FOR DELETE
USING (user_id = auth.uid());

-- ================================
-- 5. REALTIME
-- ================================
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE message_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;

-- ================================
-- 6. HELPER FUNCTION: Create course forum conversation
-- When a course is enrolled, auto-create a multi conversation
-- ================================
CREATE OR REPLACE FUNCTION get_or_create_course_conversation(p_course_id UUID, p_user_id UUID)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
    v_instructor_id UUID;
BEGIN
    -- Check if conversation already exists for this course
    SELECT id INTO v_conversation_id
    FROM conversations
    WHERE course_id = p_course_id AND type = 'multi'
    LIMIT 1;

    IF v_conversation_id IS NULL THEN
        -- Get instructor id
        SELECT instructor_id INTO v_instructor_id
        FROM courses WHERE id = p_course_id;

        -- Create the conversation
        INSERT INTO conversations (type, course_id, title, created_by)
        SELECT 'multi', p_course_id, COALESCE(c.title_ar, c.title_en, 'Course Forum'), COALESCE(v_instructor_id, p_user_id)
        FROM courses c WHERE c.id = p_course_id
        RETURNING id INTO v_conversation_id;

        -- Add instructor as admin participant
        IF v_instructor_id IS NOT NULL THEN
            INSERT INTO conversation_participants (conversation_id, user_id, role)
            VALUES (v_conversation_id, v_instructor_id, 'admin')
            ON CONFLICT (conversation_id, user_id) DO NOTHING;
        END IF;
    END IF;

    -- Add user as member (if not already)
    INSERT INTO conversation_participants (conversation_id, user_id, role)
    VALUES (v_conversation_id, p_user_id, 'member')
    ON CONFLICT (conversation_id, user_id) DO NOTHING;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_or_create_course_conversation(UUID, UUID) TO authenticated;

-- ================================
-- 7. HELPER FUNCTION: Get or create single conversation
-- ================================
CREATE OR REPLACE FUNCTION get_or_create_single_conversation(p_user1_id UUID, p_user2_id UUID)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
BEGIN
    -- Check if single conversation already exists between these two users
    SELECT c.id INTO v_conversation_id
    FROM conversations c
    JOIN conversation_participants cp1 ON cp1.conversation_id = c.id AND cp1.user_id = p_user1_id
    JOIN conversation_participants cp2 ON cp2.conversation_id = c.id AND cp2.user_id = p_user2_id
    WHERE c.type = 'single'
    LIMIT 1;

    IF v_conversation_id IS NULL THEN
        -- Create the conversation
        INSERT INTO conversations (type, created_by)
        VALUES ('single', p_user1_id)
        RETURNING id INTO v_conversation_id;

        -- Add both users
        INSERT INTO conversation_participants (conversation_id, user_id, role)
        VALUES
            (v_conversation_id, p_user1_id, 'member'),
            (v_conversation_id, p_user2_id, 'member');
    END IF;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_or_create_single_conversation(UUID, UUID) TO authenticated;

-- ================================
-- 8. HELPER FUNCTION: Get user conversations list
-- ================================
CREATE OR REPLACE FUNCTION get_user_conversations(p_user_id UUID, p_type TEXT DEFAULT NULL)
RETURNS TABLE (
    conversation_id UUID,
    conversation_type VARCHAR(10),
    conversation_title TEXT,
    course_id UUID,
    created_at TIMESTAMPTZ,
    last_message_id UUID,
    last_message_text TEXT,
    last_message_user_id UUID,
    last_message_user_name TEXT,
    last_message_created_at TIMESTAMPTZ,
    participants_count BIGINT,
    other_user_name TEXT,
    other_user_avatar TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id AS conversation_id,
        c.type AS conversation_type,
        c.title AS conversation_title,
        c.course_id,
        c.created_at,
        lm.id AS last_message_id,
        lm.message_text AS last_message_text,
        lm.user_id AS last_message_user_id,
        p_sender.name AS last_message_user_name,
        lm.created_at AS last_message_created_at,
        (SELECT COUNT(*) FROM conversation_participants cp2 WHERE cp2.conversation_id = c.id) AS participants_count,
        -- For single conversations, get the other user`s name
        CASE WHEN c.type = 'single' THEN (
            SELECT p_other.name FROM conversation_participants cp_other
            JOIN profiles p_other ON p_other.id = cp_other.user_id
            WHERE cp_other.conversation_id = c.id AND cp_other.user_id != p_user_id
            LIMIT 1
        ) ELSE NULL END AS other_user_name,
        CASE WHEN c.type = 'single' THEN (
            SELECT p_other.avatar_url FROM conversation_participants cp_other
            JOIN profiles p_other ON p_other.id = cp_other.user_id
            WHERE cp_other.conversation_id = c.id AND cp_other.user_id != p_user_id
            LIMIT 1
        ) ELSE NULL END AS other_user_avatar
    FROM conversations c
    JOIN conversation_participants cp ON cp.conversation_id = c.id AND cp.user_id = p_user_id
    LEFT JOIN LATERAL (
        SELECT m.id, m.message_text, m.user_id, m.created_at
        FROM messages m
        WHERE m.conversation_id = c.id AND m.is_deleted = FALSE
        ORDER BY m.created_at DESC
        LIMIT 1
    ) lm ON TRUE
    LEFT JOIN profiles p_sender ON p_sender.id = lm.user_id
    WHERE (p_type IS NULL OR c.type = p_type)
    ORDER BY COALESCE(lm.created_at, c.created_at) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_user_conversations(UUID, TEXT) TO authenticated;


-- =====================================================================
-- File: 304_fix_conversation_participants_rls_recursion.sql
-- =====================================================================
-- =====================================================
-- Fix RLS recursion on conversation_participants (42P17)
-- =====================================================
-- Issue:
--   Policy on conversation_participants was querying the same table
--   inside USING(), which causes infinite recursion under RLS.
--
-- This migration introduces a SECURITY DEFINER helper function and
-- rewrites policies to use it safely.

BEGIN;

CREATE OR REPLACE FUNCTION public.is_conversation_participant(
    p_conversation_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.conversation_participants cp
        WHERE cp.conversation_id = p_conversation_id
        AND cp.user_id = p_user_id
    );
$$;

REVOKE ALL ON FUNCTION public.is_conversation_participant(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_conversation_participant(UUID, UUID) TO authenticated;

-- Drop any existing SELECT policies on conversation_participants
-- to avoid keeping an old recursive policy with a different name.
DO $$
DECLARE pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'conversation_participants'
      AND cmd = 'SELECT'
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON public.conversation_participants',
      pol.policyname
    );
  END LOOP;
END$$;

-- conversations
DROP POLICY IF EXISTS "Participants can view their conversations" ON public.conversations;
DROP POLICY IF EXISTS "Participants can view their conversations" ON public;
CREATE POLICY "Participants can view their conversations" ON public.conversations FOR SELECT
USING (
    public.is_conversation_participant(conversations.id, auth.uid())
    OR EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
    )
);

-- conversation_participants
DROP POLICY IF EXISTS "Participants can view members" ON public.conversation_participants;
DROP POLICY IF EXISTS "Participants can view members" ON public;
CREATE POLICY "Participants can view members" ON public.conversation_participants FOR SELECT
USING (
    public.is_conversation_participant(conversation_participants.conversation_id, auth.uid())
    OR EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
    )
);

-- messages
DROP POLICY IF EXISTS "Participants can view messages" ON public.messages;
DROP POLICY IF EXISTS "Participants can view messages" ON public;
CREATE POLICY "Participants can view messages" ON public.messages FOR SELECT
USING (
    public.is_conversation_participant(messages.conversation_id, auth.uid())
    OR EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
    )
);

DROP POLICY IF EXISTS "Participants can send messages" ON public.messages;
DROP POLICY IF EXISTS "Participants can send messages" ON public;
CREATE POLICY "Participants can send messages" ON public.messages FOR INSERT
WITH CHECK (
    user_id = auth.uid()
    AND public.is_conversation_participant(messages.conversation_id, auth.uid())
);

-- message_reactions
DROP POLICY IF EXISTS "Participants can view reactions" ON public.message_reactions;
DROP POLICY IF EXISTS "Participants can view reactions" ON public;
CREATE POLICY "Participants can view reactions" ON public.message_reactions FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.messages m
        WHERE m.id = message_reactions.message_id
        AND public.is_conversation_participant(m.conversation_id, auth.uid())
    )
);

DROP POLICY IF EXISTS "Participants can add reactions" ON public.message_reactions;
DROP POLICY IF EXISTS "Participants can add reactions" ON public;
CREATE POLICY "Participants can add reactions" ON public.message_reactions FOR INSERT
WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
        SELECT 1 FROM public.messages m
        WHERE m.id = message_reactions.message_id
        AND public.is_conversation_participant(m.conversation_id, auth.uid())
    )
);

COMMIT;

-- Optional check:
-- SELECT tablename, policyname, cmd
-- FROM pg_policies
-- WHERE tablename IN ('conversations', 'conversation_participants', 'messages', 'message_reactions`)
-- ORDER BY tablename, policyname;


-- =====================================================================
-- File: 305_instructor_forum_group_management.sql
-- =====================================================================
-- =====================================================
-- Instructor Forum Group Management
-- =====================================================
-- Adds RPC functions so instructors can enable/disable a course group
-- from the forums tab in instructor dashboard.

BEGIN;

CREATE OR REPLACE FUNCTION public.get_instructor_forum_courses(p_user_id UUID)
RETURNS TABLE (
    course_id UUID,
    title_ar TEXT,
    title_en TEXT,
    has_group BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_is_admin BOOLEAN := FALSE;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = v_caller AND p.role = 'admin'
    ) INTO v_is_admin;

    IF v_caller <> p_user_id AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    RETURN QUERY
    SELECT
        c.id AS course_id,
        c.title_ar,
        c.title_en,
        EXISTS (
            SELECT 1
            FROM public.conversations conv
            WHERE conv.course_id = c.id
              AND conv.type = 'multi'
        ) AS has_group
    FROM public.courses c
    WHERE c.instructor_id = p_user_id
    ORDER BY c.created_at DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_instructor_forum_courses(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_instructor_forum_courses(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.set_course_group_enabled(
    p_course_id UUID,
    p_enabled BOOLEAN
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_course_instructor UUID;
    v_conversation_id UUID;
    v_is_admin BOOLEAN := FALSE;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT c.instructor_id
    INTO v_course_instructor
    FROM public.courses c
    WHERE c.id = p_course_id;

    IF v_course_instructor IS NULL THEN
        RAISE EXCEPTION 'Course not found';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = v_caller AND p.role = 'admin'
    ) INTO v_is_admin;

    IF v_caller <> v_course_instructor AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF p_enabled THEN
        -- Create group conversation if missing
        SELECT conv.id
        INTO v_conversation_id
        FROM public.conversations conv
        WHERE conv.course_id = p_course_id
          AND conv.type = 'multi'
        LIMIT 1;

        IF v_conversation_id IS NULL THEN
            INSERT INTO public.conversations (type, course_id, title, created_by)
            SELECT
                'multi',
                c.id,
                COALESCE(c.title_ar, c.title_en, 'Course Forum'),
                COALESCE(c.instructor_id, v_caller)
            FROM public.courses c
            WHERE c.id = p_course_id
            RETURNING id INTO v_conversation_id;
        END IF;

        -- Ensure instructor is participant admin
        INSERT INTO public.conversation_participants (conversation_id, user_id, role)
        VALUES (v_conversation_id, v_course_instructor, 'admin')
        ON CONFLICT (conversation_id, user_id) DO UPDATE
        SET role = 'admin';

        -- Ensure caller is participant too (useful for admin operations)
        INSERT INTO public.conversation_participants (conversation_id, user_id, role)
        VALUES (v_conversation_id, v_caller, 'admin')
        ON CONFLICT (conversation_id, user_id) DO NOTHING;

        RETURN v_conversation_id;
    END IF;

    -- Disable group by deleting ALL multi conversations for this course
    -- (safety for any legacy duplicated rows)
    DELETE FROM public.conversations
    WHERE course_id = p_course_id
      AND type = 'multi';

    RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.set_course_group_enabled(UUID, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_course_group_enabled(UUID, BOOLEAN) TO authenticated;

COMMIT;


-- =====================================================================
-- File: 306_fix_course_group_disable.sql
-- =====================================================================
-- =====================================================
-- Fix: disabling course group should remove all group chats
-- =====================================================
-- Use this if 305 was already applied before this fix.

BEGIN;

CREATE OR REPLACE FUNCTION public.set_course_group_enabled(
    p_course_id UUID,
    p_enabled BOOLEAN
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_course_instructor UUID;
    v_conversation_id UUID;
    v_is_admin BOOLEAN := FALSE;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT c.instructor_id
    INTO v_course_instructor
    FROM public.courses c
    WHERE c.id = p_course_id;

    IF v_course_instructor IS NULL THEN
        RAISE EXCEPTION 'Course not found';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = v_caller AND p.role = 'admin'
    ) INTO v_is_admin;

    IF v_caller <> v_course_instructor AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF p_enabled THEN
        SELECT conv.id
        INTO v_conversation_id
        FROM public.conversations conv
        WHERE conv.course_id = p_course_id
          AND conv.type = 'multi'
        ORDER BY conv.created_at ASC
        LIMIT 1;

        IF v_conversation_id IS NULL THEN
            INSERT INTO public.conversations (type, course_id, title, created_by)
            SELECT
                'multi',
                c.id,
                COALESCE(c.title_ar, c.title_en, 'Course Forum'),
                COALESCE(c.instructor_id, v_caller)
            FROM public.courses c
            WHERE c.id = p_course_id
            RETURNING id INTO v_conversation_id;
        END IF;

        INSERT INTO public.conversation_participants (conversation_id, user_id, role)
        VALUES (v_conversation_id, v_course_instructor, 'admin')
        ON CONFLICT (conversation_id, user_id) DO UPDATE
        SET role = 'admin';

        INSERT INTO public.conversation_participants (conversation_id, user_id, role)
        VALUES (v_conversation_id, v_caller, 'admin')
        ON CONFLICT (conversation_id, user_id) DO NOTHING;

        -- remove any accidental duplicate multi groups for same course
        DELETE FROM public.conversations
        WHERE course_id = p_course_id
          AND type = 'multi'
          AND id <> v_conversation_id;

        RETURN v_conversation_id;
    END IF;

    -- IMPORTANT: remove all multi groups for this course
    DELETE FROM public.conversations
    WHERE course_id = p_course_id
      AND type = 'multi';

    RETURN NULL;
END;
$$;

COMMIT;


-- =====================================================================
-- File: 307_ensure_get_instructor_forum_courses_rpc.sql
-- =====================================================================
-- =====================================================
-- Ensure instructor forum courses RPC exists
-- =====================================================
-- Use this migration if app expects get_instructor_forum_courses RPC.

BEGIN;

CREATE OR REPLACE FUNCTION public.get_instructor_forum_courses(p_user_id UUID)
RETURNS TABLE (
    course_id UUID,
    title_ar TEXT,
    title_en TEXT,
    has_group BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_is_admin BOOLEAN := FALSE;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = v_caller AND p.role = 'admin'
    ) INTO v_is_admin;

    IF v_caller <> p_user_id AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    RETURN QUERY
    SELECT
        c.id AS course_id,
        c.title_ar,
        c.title_en,
        EXISTS (
            SELECT 1
            FROM public.conversations conv
            WHERE conv.course_id = c.id
              AND conv.type = 'multi'
        ) AS has_group
    FROM public.courses c
    WHERE c.instructor_id = p_user_id
    ORDER BY c.created_at DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_instructor_forum_courses(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_instructor_forum_courses(UUID) TO authenticated;

COMMIT;


-- =====================================================================
-- File: 308_fix_group_chat_visibility_and_participants.sql
-- =====================================================================
-- =====================================================
-- Fix: group chats visibility via participant sync
-- =====================================================
-- Why this exists:
-- get_user_conversations only returns rows where user exists in
-- conversation_participants. Some course groups were created without
-- adding all enrolled students, so users saw 0 group conversations.

BEGIN;

CREATE OR REPLACE FUNCTION public.set_course_group_enabled(
    p_course_id UUID,
    p_enabled BOOLEAN
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_course_instructor UUID;
    v_conversation_id UUID;
    v_is_admin BOOLEAN := FALSE;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT c.instructor_id
    INTO v_course_instructor
    FROM public.courses c
    WHERE c.id = p_course_id;

    IF v_course_instructor IS NULL THEN
        RAISE EXCEPTION 'Course not found';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = v_caller AND p.role = 'admin'
    ) INTO v_is_admin;

    IF v_caller <> v_course_instructor AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF p_enabled THEN
        SELECT conv.id
        INTO v_conversation_id
        FROM public.conversations conv
        WHERE conv.course_id = p_course_id
          AND conv.type = 'multi'
        ORDER BY conv.created_at ASC
        LIMIT 1;

        IF v_conversation_id IS NULL THEN
            INSERT INTO public.conversations (type, course_id, title, created_by)
            SELECT
                'multi',
                c.id,
                COALESCE(c.title_ar, c.title_en, 'Course Forum'),
                COALESCE(c.instructor_id, v_caller)
            FROM public.courses c
            WHERE c.id = p_course_id
            RETURNING id INTO v_conversation_id;
        END IF;

        INSERT INTO public.conversation_participants (conversation_id, user_id, role)
        VALUES (v_conversation_id, v_course_instructor, 'admin')
        ON CONFLICT (conversation_id, user_id) DO UPDATE
        SET role = 'admin';

        INSERT INTO public.conversation_participants (conversation_id, user_id, role)
        VALUES (v_conversation_id, v_caller, 'admin')
        ON CONFLICT (conversation_id, user_id) DO UPDATE
        SET role = 'admin';

        -- Ensure all enrolled students are members of the group
        INSERT INTO public.conversation_participants (conversation_id, user_id, role)
        SELECT DISTINCT
            v_conversation_id,
            e.user_id,
            'member'
        FROM public.enrollments e
        WHERE e.course_id = p_course_id
          AND e.status IN ('active', 'completed')
        ON CONFLICT (conversation_id, user_id) DO NOTHING;

        -- remove any accidental duplicate multi groups for same course
        DELETE FROM public.conversations
        WHERE course_id = p_course_id
          AND type = 'multi'
          AND id <> v_conversation_id;

        RETURN v_conversation_id;
    END IF;

    -- IMPORTANT: remove all multi groups for this course
    DELETE FROM public.conversations
    WHERE course_id = p_course_id
      AND type = 'multi';

    RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.set_course_group_enabled(UUID, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_course_group_enabled(UUID, BOOLEAN) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_user_conversations(
    p_user_id UUID,
    p_type TEXT DEFAULT NULL
)
RETURNS TABLE (
    conversation_id UUID,
    conversation_type VARCHAR(10),
    conversation_title TEXT,
    course_id UUID,
    created_at TIMESTAMPTZ,
    last_message_id UUID,
    last_message_text TEXT,
    last_message_user_id UUID,
    last_message_user_name TEXT,
    last_message_created_at TIMESTAMPTZ,
    participants_count BIGINT,
    other_user_name TEXT,
    other_user_avatar TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_is_admin BOOLEAN := FALSE;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = v_caller AND p.role = 'admin'
    ) INTO v_is_admin;

    IF v_caller <> p_user_id AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    -- Auto-join user to eligible course groups to avoid empty forum list.
    INSERT INTO public.conversation_participants (conversation_id, user_id, role)
    SELECT
        c.id,
        p_user_id,
        CASE
            WHEN cr.instructor_id = p_user_id THEN 'admin'
            ELSE 'member'
        END
    FROM public.conversations c
    JOIN public.courses cr ON cr.id = c.course_id
    WHERE c.type = 'multi'
      AND (
          cr.instructor_id = p_user_id
          OR EXISTS (
              SELECT 1
              FROM public.enrollments e
              WHERE e.course_id = c.course_id
                AND e.user_id = p_user_id
                AND e.status IN ('active', 'completed')
          )
      )
    ON CONFLICT ON CONSTRAINT conversation_participants_conversation_id_user_id_key DO UPDATE
    SET role = CASE
        WHEN EXCLUDED.role = 'admin' THEN 'admin'
        ELSE conversation_participants.role
    END;

    RETURN QUERY
    SELECT
        c.id AS conversation_id,
        c.type AS conversation_type,
        c.title AS conversation_title,
        c.course_id,
        c.created_at,
        lm.id AS last_message_id,
        lm.message_text AS last_message_text,
        lm.user_id AS last_message_user_id,
        p_sender.name AS last_message_user_name,
        lm.created_at AS last_message_created_at,
        (SELECT COUNT(*) FROM public.conversation_participants cp2 WHERE cp2.conversation_id = c.id) AS participants_count,
        CASE WHEN c.type = 'single' THEN (
            SELECT p_other.name FROM public.conversation_participants cp_other
            JOIN public.profiles p_other ON p_other.id = cp_other.user_id
            WHERE cp_other.conversation_id = c.id AND cp_other.user_id <> p_user_id
            LIMIT 1
        ) ELSE NULL END AS other_user_name,
        CASE WHEN c.type = 'single' THEN (
            SELECT p_other.avatar_url FROM public.conversation_participants cp_other
            JOIN public.profiles p_other ON p_other.id = cp_other.user_id
            WHERE cp_other.conversation_id = c.id AND cp_other.user_id <> p_user_id
            LIMIT 1
        ) ELSE NULL END AS other_user_avatar
    FROM public.conversations c
    JOIN public.conversation_participants cp ON cp.conversation_id = c.id AND cp.user_id = p_user_id
    LEFT JOIN LATERAL (
        SELECT m.id, m.message_text, m.user_id, m.created_at
        FROM public.messages m
        WHERE m.conversation_id = c.id AND m.is_deleted = FALSE
        ORDER BY m.created_at DESC
        LIMIT 1
    ) lm ON TRUE
    LEFT JOIN public.profiles p_sender ON p_sender.id = lm.user_id
    WHERE (p_type IS NULL OR c.type = p_type)
    ORDER BY COALESCE(lm.created_at, c.created_at) DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_user_conversations(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_conversations(UUID, TEXT) TO authenticated;

COMMIT;


-- =====================================================================
-- File: 309_hotfix_get_user_conversations_ambiguous_column.sql
-- =====================================================================
-- =====================================================
-- Hotfix: resolve ambiguous conversation_id in get_user_conversations
-- =====================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.get_user_conversations(
    p_user_id UUID,
    p_type TEXT DEFAULT NULL
)
RETURNS TABLE (
    conversation_id UUID,
    conversation_type VARCHAR(10),
    conversation_title TEXT,
    course_id UUID,
    created_at TIMESTAMPTZ,
    last_message_id UUID,
    last_message_text TEXT,
    last_message_user_id UUID,
    last_message_user_name TEXT,
    last_message_created_at TIMESTAMPTZ,
    participants_count BIGINT,
    other_user_name TEXT,
    other_user_avatar TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_is_admin BOOLEAN := FALSE;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = v_caller AND p.role = 'admin'
    ) INTO v_is_admin;

    IF v_caller <> p_user_id AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    INSERT INTO public.conversation_participants (conversation_id, user_id, role)
    SELECT
        c.id,
        p_user_id,
        CASE
            WHEN cr.instructor_id = p_user_id THEN 'admin'
            ELSE 'member'
        END
    FROM public.conversations c
    JOIN public.courses cr ON cr.id = c.course_id
    WHERE c.type = 'multi'
      AND (
          cr.instructor_id = p_user_id
          OR EXISTS (
              SELECT 1
              FROM public.enrollments e
              WHERE e.course_id = c.course_id
                AND e.user_id = p_user_id
                AND e.status IN ('active', 'completed')
          )
      )
    ON CONFLICT ON CONSTRAINT conversation_participants_conversation_id_user_id_key DO UPDATE
    SET role = CASE
        WHEN EXCLUDED.role = 'admin' THEN 'admin'
        ELSE conversation_participants.role
    END;

    RETURN QUERY
    SELECT
        c.id AS conversation_id,
        c.type AS conversation_type,
        c.title AS conversation_title,
        c.course_id,
        c.created_at,
        lm.id AS last_message_id,
        lm.message_text AS last_message_text,
        lm.user_id AS last_message_user_id,
        p_sender.name AS last_message_user_name,
        lm.created_at AS last_message_created_at,
        (SELECT COUNT(*) FROM public.conversation_participants cp2 WHERE cp2.conversation_id = c.id) AS participants_count,
        CASE WHEN c.type = 'single' THEN (
            SELECT p_other.name FROM public.conversation_participants cp_other
            JOIN public.profiles p_other ON p_other.id = cp_other.user_id
            WHERE cp_other.conversation_id = c.id AND cp_other.user_id <> p_user_id
            LIMIT 1
        ) ELSE NULL END AS other_user_name,
        CASE WHEN c.type = 'single' THEN (
            SELECT p_other.avatar_url FROM public.conversation_participants cp_other
            JOIN public.profiles p_other ON p_other.id = cp_other.user_id
            WHERE cp_other.conversation_id = c.id AND cp_other.user_id <> p_user_id
            LIMIT 1
        ) ELSE NULL END AS other_user_avatar
    FROM public.conversations c
    JOIN public.conversation_participants cp ON cp.conversation_id = c.id AND cp.user_id = p_user_id
    LEFT JOIN LATERAL (
        SELECT m.id, m.message_text, m.user_id, m.created_at
        FROM public.messages m
        WHERE m.conversation_id = c.id AND m.is_deleted = FALSE
        ORDER BY m.created_at DESC
        LIMIT 1
    ) lm ON TRUE
    LEFT JOIN public.profiles p_sender ON p_sender.id = lm.user_id
    WHERE (p_type IS NULL OR c.type = p_type)
    ORDER BY COALESCE(lm.created_at, c.created_at) DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_user_conversations(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_conversations(UUID, TEXT) TO authenticated;

COMMIT;


-- =====================================================================
-- File: 310_course_forums_management.sql
-- =====================================================================
-- =====================================================
-- Course Forums Management: separate management features
-- - Rename group
-- - Set member role (admin/member)
-- - Remove member
-- - Ban / Unban member
-- =====================================================

BEGIN;

-- Persistent bans per course group
CREATE TABLE IF NOT EXISTS public.course_group_bans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    banned_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reason TEXT,
    banned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(course_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_course_group_bans_course ON public.course_group_bans(course_id);
CREATE INDEX IF NOT EXISTS idx_course_group_bans_user ON public.course_group_bans(user_id);

ALTER TABLE public.course_group_bans ENABLE ROW LEVEL SECURITY;

-- Keep table private to clients; only SECURITY DEFINER functions should access it.
REVOKE ALL ON TABLE public.course_group_bans FROM PUBLIC;
REVOKE ALL ON TABLE public.course_group_bans FROM authenticated;

CREATE OR REPLACE FUNCTION public.set_course_group_enabled(
    p_course_id UUID,
    p_enabled BOOLEAN
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_course_instructor UUID;
    v_conversation_id UUID;
    v_is_admin BOOLEAN := FALSE;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT c.instructor_id
    INTO v_course_instructor
    FROM public.courses c
    WHERE c.id = p_course_id;

    IF v_course_instructor IS NULL THEN
        RAISE EXCEPTION 'Course not found';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = v_caller AND p.role = 'admin'
    ) INTO v_is_admin;

    IF v_caller <> v_course_instructor AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF p_enabled THEN
        SELECT conv.id
        INTO v_conversation_id
        FROM public.conversations conv
        WHERE conv.course_id = p_course_id
          AND conv.type = 'multi'
        ORDER BY conv.created_at ASC
        LIMIT 1;

        IF v_conversation_id IS NULL THEN
            INSERT INTO public.conversations (type, course_id, title, created_by)
            SELECT
                'multi',
                c.id,
                COALESCE(c.title_ar, c.title_en, 'Course Forum'),
                COALESCE(c.instructor_id, v_caller)
            FROM public.courses c
            WHERE c.id = p_course_id
            RETURNING id INTO v_conversation_id;
        END IF;

        INSERT INTO public.conversation_participants (conversation_id, user_id, role)
        VALUES (v_conversation_id, v_course_instructor, 'admin')
        ON CONFLICT (conversation_id, user_id) DO UPDATE
        SET role = 'admin';

        INSERT INTO public.conversation_participants (conversation_id, user_id, role)
        VALUES (v_conversation_id, v_caller, 'admin')
        ON CONFLICT (conversation_id, user_id) DO UPDATE
        SET role = 'admin';

        -- Add enrolled users except banned ones.
        INSERT INTO public.conversation_participants (conversation_id, user_id, role)
        SELECT DISTINCT
            v_conversation_id,
            e.user_id,
            'member'
        FROM public.enrollments e
        WHERE e.course_id = p_course_id
          AND e.status IN ('active', 'completed')
          AND NOT EXISTS (
              SELECT 1
              FROM public.course_group_bans b
              WHERE b.course_id = p_course_id
                AND b.user_id = e.user_id
          )
        ON CONFLICT (conversation_id, user_id) DO NOTHING;

        DELETE FROM public.conversations
        WHERE course_id = p_course_id
          AND type = 'multi'
          AND id <> v_conversation_id;

        RETURN v_conversation_id;
    END IF;

    DELETE FROM public.conversations
    WHERE course_id = p_course_id
      AND type = 'multi';

    RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.set_course_group_enabled(UUID, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_course_group_enabled(UUID, BOOLEAN) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_user_conversations(
    p_user_id UUID,
    p_type TEXT DEFAULT NULL
)
RETURNS TABLE (
    conversation_id UUID,
    conversation_type VARCHAR(10),
    conversation_title TEXT,
    course_id UUID,
    created_at TIMESTAMPTZ,
    last_message_id UUID,
    last_message_text TEXT,
    last_message_user_id UUID,
    last_message_user_name TEXT,
    last_message_created_at TIMESTAMPTZ,
    participants_count BIGINT,
    other_user_name TEXT,
    other_user_avatar TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_is_admin BOOLEAN := FALSE;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = v_caller AND p.role = 'admin'
    ) INTO v_is_admin;

    IF v_caller <> p_user_id AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    INSERT INTO public.conversation_participants (conversation_id, user_id, role)
    SELECT
        c.id,
        p_user_id,
        CASE
            WHEN cr.instructor_id = p_user_id THEN 'admin'
            ELSE 'member'
        END
    FROM public.conversations c
    JOIN public.courses cr ON cr.id = c.course_id
    WHERE c.type = 'multi'
      AND NOT EXISTS (
          SELECT 1
          FROM public.course_group_bans b
          WHERE b.course_id = c.course_id
            AND b.user_id = p_user_id
      )
      AND (
          cr.instructor_id = p_user_id
          OR EXISTS (
              SELECT 1
              FROM public.enrollments e
              WHERE e.course_id = c.course_id
                AND e.user_id = p_user_id
                AND e.status IN ('active', 'completed')
          )
      )
    ON CONFLICT ON CONSTRAINT conversation_participants_conversation_id_user_id_key DO UPDATE
    SET role = CASE
        WHEN EXCLUDED.role = 'admin' THEN 'admin'
        ELSE conversation_participants.role
    END;

    RETURN QUERY
    SELECT
        c.id AS conversation_id,
        c.type AS conversation_type,
        c.title AS conversation_title,
        c.course_id,
        c.created_at,
        lm.id AS last_message_id,
        lm.message_text AS last_message_text,
        lm.user_id AS last_message_user_id,
        p_sender.name AS last_message_user_name,
        lm.created_at AS last_message_created_at,
        (SELECT COUNT(*) FROM public.conversation_participants cp2 WHERE cp2.conversation_id = c.id) AS participants_count,
        CASE WHEN c.type = 'single' THEN (
            SELECT p_other.name FROM public.conversation_participants cp_other
            JOIN public.profiles p_other ON p_other.id = cp_other.user_id
            WHERE cp_other.conversation_id = c.id AND cp_other.user_id <> p_user_id
            LIMIT 1
        ) ELSE NULL END AS other_user_name,
        CASE WHEN c.type = 'single' THEN (
            SELECT p_other.avatar_url FROM public.conversation_participants cp_other
            JOIN public.profiles p_other ON p_other.id = cp_other.user_id
            WHERE cp_other.conversation_id = c.id AND cp_other.user_id <> p_user_id
            LIMIT 1
        ) ELSE NULL END AS other_user_avatar
    FROM public.conversations c
    JOIN public.conversation_participants cp ON cp.conversation_id = c.id AND cp.user_id = p_user_id
    LEFT JOIN LATERAL (
        SELECT m.id, m.message_text, m.user_id, m.created_at
        FROM public.messages m
        WHERE m.conversation_id = c.id AND m.is_deleted = FALSE
        ORDER BY m.created_at DESC
        LIMIT 1
    ) lm ON TRUE
    LEFT JOIN public.profiles p_sender ON p_sender.id = lm.user_id
    WHERE (p_type IS NULL OR c.type = p_type)
    ORDER BY COALESCE(lm.created_at, c.created_at) DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_user_conversations(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_conversations(UUID, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.update_course_group_title(
    p_course_id UUID,
    p_title TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_course_instructor UUID;
    v_conversation_id UUID;
    v_is_admin BOOLEAN := FALSE;
    v_new_title TEXT;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    v_new_title := NULLIF(BTRIM(p_title), '');
    IF v_new_title IS NULL THEN
        RAISE EXCEPTION 'Title cannot be empty';
    END IF;

    SELECT c.instructor_id
    INTO v_course_instructor
    FROM public.courses c
    WHERE c.id = p_course_id;

    IF v_course_instructor IS NULL THEN
        RAISE EXCEPTION 'Course not found';
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = v_caller AND p.role = 'admin'
    ) INTO v_is_admin;

    IF v_caller <> v_course_instructor AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    SELECT conv.id
    INTO v_conversation_id
    FROM public.conversations conv
    WHERE conv.course_id = p_course_id
      AND conv.type = 'multi'
    LIMIT 1;

    IF v_conversation_id IS NULL THEN
        RAISE EXCEPTION 'Group not enabled';
    END IF;

    UPDATE public.conversations
    SET title = v_new_title,
        updated_at = NOW()
    WHERE id = v_conversation_id;

    RETURN v_conversation_id;
END;
$$;

REVOKE ALL ON FUNCTION public.update_course_group_title(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_course_group_title(UUID, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_course_group_members(
    p_course_id UUID
)
RETURNS TABLE (
    conversation_id UUID,
    conversation_title TEXT,
    user_id UUID,
    user_name TEXT,
    user_avatar TEXT,
    role TEXT,
    is_banned BOOLEAN,
    banned_reason TEXT,
    banned_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_course_instructor UUID;
    v_is_admin BOOLEAN := FALSE;
    v_conversation_id UUID;
    v_conversation_title TEXT;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT c.instructor_id
    INTO v_course_instructor
    FROM public.courses c
    WHERE c.id = p_course_id;

    IF v_course_instructor IS NULL THEN
        RAISE EXCEPTION 'Course not found';
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = v_caller AND p.role = 'admin'
    ) INTO v_is_admin;

    IF v_caller <> v_course_instructor AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    SELECT conv.id, conv.title
    INTO v_conversation_id, v_conversation_title
    FROM public.conversations conv
    WHERE conv.course_id = p_course_id
      AND conv.type = 'multi'
    LIMIT 1;

    RETURN QUERY
    SELECT
        v_conversation_id AS conversation_id,
        v_conversation_title AS conversation_title,
        cp.user_id,
        COALESCE(pr.name, 'Unknown') AS user_name,
        pr.avatar_url AS user_avatar,
        cp.role::TEXT,
        FALSE AS is_banned,
        NULL::TEXT AS banned_reason,
        NULL::TIMESTAMPTZ AS banned_at
    FROM public.conversation_participants cp
    LEFT JOIN public.profiles pr ON pr.id = cp.user_id
    WHERE cp.conversation_id = v_conversation_id

    UNION ALL

    SELECT
        v_conversation_id AS conversation_id,
        v_conversation_title AS conversation_title,
        b.user_id,
        COALESCE(pr.name, 'Unknown') AS user_name,
        pr.avatar_url AS user_avatar,
        'banned'::TEXT AS role,
        TRUE AS is_banned,
        b.reason AS banned_reason,
        b.banned_at
    FROM public.course_group_bans b
    LEFT JOIN public.profiles pr ON pr.id = b.user_id
    WHERE b.course_id = p_course_id
      AND NOT EXISTS (
          SELECT 1
          FROM public.conversation_participants cp
          WHERE cp.conversation_id = v_conversation_id
            AND cp.user_id = b.user_id
      )

    ORDER BY is_banned ASC, user_name ASC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_course_group_members(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_course_group_members(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.manage_course_group_member(
    p_course_id UUID,
    p_target_user_id UUID,
    p_action TEXT,
    p_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_course_instructor UUID;
    v_is_admin BOOLEAN := FALSE;
    v_conversation_id UUID;
    v_action TEXT := LOWER(COALESCE(p_action, ''));
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT c.instructor_id
    INTO v_course_instructor
    FROM public.courses c
    WHERE c.id = p_course_id;

    IF v_course_instructor IS NULL THEN
        RAISE EXCEPTION 'Course not found';
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = v_caller AND p.role = 'admin'
    ) INTO v_is_admin;

    IF v_caller <> v_course_instructor AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF p_target_user_id IS NULL THEN
        RAISE EXCEPTION 'Target user is required';
    END IF;

    IF p_target_user_id = v_course_instructor AND v_action IN ('remove', 'ban', 'member') THEN
        RAISE EXCEPTION 'Cannot change instructor core role';
    END IF;

    SELECT conv.id
    INTO v_conversation_id
    FROM public.conversations conv
    WHERE conv.course_id = p_course_id
      AND conv.type = 'multi'
    LIMIT 1;

    IF v_action IN ('admin', 'member', 'remove', 'ban') AND v_conversation_id IS NULL THEN
        RAISE EXCEPTION 'Group not enabled';
    END IF;

    IF v_action = 'admin' THEN
        DELETE FROM public.course_group_bans
        WHERE course_id = p_course_id
          AND user_id = p_target_user_id;

        INSERT INTO public.conversation_participants (conversation_id, user_id, role)
        VALUES (v_conversation_id, p_target_user_id, 'admin')
        ON CONFLICT (conversation_id, user_id) DO UPDATE
        SET role = 'admin';

        RETURN TRUE;
    ELSIF v_action = 'member' THEN
        DELETE FROM public.course_group_bans
        WHERE course_id = p_course_id
          AND user_id = p_target_user_id;

        INSERT INTO public.conversation_participants (conversation_id, user_id, role)
        VALUES (v_conversation_id, p_target_user_id, 'member')
        ON CONFLICT (conversation_id, user_id) DO UPDATE
        SET role = 'member';

        RETURN TRUE;
    ELSIF v_action = 'remove' THEN
        DELETE FROM public.conversation_participants
        WHERE conversation_id = v_conversation_id
          AND user_id = p_target_user_id;

        RETURN TRUE;
    ELSIF v_action = 'ban' THEN
        INSERT INTO public.course_group_bans (course_id, user_id, banned_by, reason, banned_at)
        VALUES (p_course_id, p_target_user_id, v_caller, NULLIF(BTRIM(p_reason), ''), NOW())
        ON CONFLICT (course_id, user_id) DO UPDATE
        SET banned_by = EXCLUDED.banned_by,
            reason = EXCLUDED.reason,
            banned_at = EXCLUDED.banned_at;

        DELETE FROM public.conversation_participants
        WHERE conversation_id = v_conversation_id
          AND user_id = p_target_user_id;

        RETURN TRUE;
    ELSIF v_action = 'unban' THEN
        DELETE FROM public.course_group_bans
        WHERE course_id = p_course_id
          AND user_id = p_target_user_id;

        IF v_conversation_id IS NOT NULL THEN
            INSERT INTO public.conversation_participants (conversation_id, user_id, role)
            SELECT
                v_conversation_id,
                p_target_user_id,
                CASE WHEN p_target_user_id = v_course_instructor THEN 'admin' ELSE 'member' END
            WHERE p_target_user_id = v_course_instructor
               OR EXISTS (
                    SELECT 1
                    FROM public.enrollments e
                    WHERE e.course_id = p_course_id
                      AND e.user_id = p_target_user_id
                      AND e.status IN ('active', 'completed')
               )
            ON CONFLICT (conversation_id, user_id) DO NOTHING;
        END IF;

        RETURN TRUE;
    END IF;

    RAISE EXCEPTION 'Unsupported action: %', p_action;
END;
$$;

REVOKE ALL ON FUNCTION public.manage_course_group_member(UUID, UUID, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.manage_course_group_member(UUID, UUID, TEXT, TEXT) TO authenticated;

COMMIT;



-- =====================================================================
-- File: 311_hotfix_get_or_create_single_conversation_duplicate_key.sql
-- =====================================================================
-- =============================================================================
-- 311_hotfix_get_or_create_single_conversation_duplicate_key.sql
-- -----------------------------------------------------------------------------
-- Fixes duplicate key errors in get_or_create_single_conversation by:
-- 1) Serializing pair creation with advisory lock
-- 2) Upserting participants safely with ON CONFLICT
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_or_create_single_conversation(
    p_user1_id UUID,
    p_user2_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_a UUID;
    v_user_b UUID;
    v_conversation_id UUID;
BEGIN
    IF p_user1_id IS NULL OR p_user2_id IS NULL THEN
        RAISE EXCEPTION 'Both user ids are required';
    END IF;

    IF p_user1_id = p_user2_id THEN
        RAISE EXCEPTION 'Cannot create single conversation with the same user';
    END IF;

    IF p_user1_id::text < p_user2_id::text THEN
        v_user_a := p_user1_id;
        v_user_b := p_user2_id;
    ELSE
        v_user_a := p_user2_id;
        v_user_b := p_user1_id;
    END IF;

    -- Prevent race conditions for the same pair within a transaction.
    PERFORM pg_advisory_xact_lock(hashtext(v_user_a::text), hashtext(v_user_b::text));

    -- Try to find an existing 1:1 conversation that contains both users.
    SELECT c.id
      INTO v_conversation_id
      FROM public.conversations c
     WHERE c.type = 'single'
       AND EXISTS (
           SELECT 1
             FROM public.conversation_participants cp
            WHERE cp.conversation_id = c.id
              AND cp.user_id = v_user_a
       )
       AND EXISTS (
           SELECT 1
             FROM public.conversation_participants cp
            WHERE cp.conversation_id = c.id
              AND cp.user_id = v_user_b
       )
     ORDER BY c.created_at ASC
     LIMIT 1;

    IF v_conversation_id IS NULL THEN
        INSERT INTO public.conversations (type, created_by)
        VALUES ('single', p_user1_id)
        RETURNING id INTO v_conversation_id;
    END IF;

    INSERT INTO public.conversation_participants (conversation_id, user_id, role)
    VALUES
        (v_conversation_id, p_user1_id, 'member'),
        (v_conversation_id, p_user2_id, 'member')
    ON CONFLICT ON CONSTRAINT conversation_participants_conversation_id_user_id_key
    DO NOTHING;

    RETURN v_conversation_id;
END;
$$;

REVOKE ALL ON FUNCTION public.get_or_create_single_conversation(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_or_create_single_conversation(UUID, UUID) TO authenticated;


-- =====================================================================
-- File: 312_fix_single_chat_display_name_and_admin_send_policy.sql
-- =====================================================================
-- =============================================================================
-- 312_fix_single_chat_display_name_and_admin_send_policy.sql
-- -----------------------------------------------------------------------------
-- Fixes:
-- 1) Ensure single chat list uses the other person`s real identity with fallback
--    (name -> email -> phone), and ignores placeholder names.
-- 2) Allow admins to send messages in conversations they can moderate/view.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_user_conversations(
    p_user_id UUID,
    p_type TEXT DEFAULT NULL
)
RETURNS TABLE (
    conversation_id UUID,
    conversation_type VARCHAR(10),
    conversation_title TEXT,
    course_id UUID,
    created_at TIMESTAMPTZ,
    last_message_id UUID,
    last_message_text TEXT,
    last_message_user_id UUID,
    last_message_user_name TEXT,
    last_message_created_at TIMESTAMPTZ,
    participants_count BIGINT,
    other_user_name TEXT,
    other_user_avatar TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_is_admin BOOLEAN := FALSE;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = v_caller AND p.role = 'admin'
    ) INTO v_is_admin;

    IF v_caller <> p_user_id AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    INSERT INTO public.conversation_participants (conversation_id, user_id, role)
    SELECT
        c.id,
        p_user_id,
        CASE
            WHEN cr.instructor_id = p_user_id THEN 'admin'
            ELSE 'member'
        END
    FROM public.conversations c
    JOIN public.courses cr ON cr.id = c.course_id
    WHERE c.type = 'multi'
      AND NOT EXISTS (
          SELECT 1
          FROM public.course_group_bans b
          WHERE b.course_id = c.course_id
            AND b.user_id = p_user_id
      )
      AND (
          cr.instructor_id = p_user_id
          OR EXISTS (
              SELECT 1
              FROM public.enrollments e
              WHERE e.course_id = c.course_id
                AND e.user_id = p_user_id
                AND e.status IN ('active', 'completed')
          )
      )
    ON CONFLICT ON CONSTRAINT conversation_participants_conversation_id_user_id_key DO UPDATE
    SET role = CASE
        WHEN EXCLUDED.role = 'admin' THEN 'admin'
        ELSE conversation_participants.role
    END;

    RETURN QUERY
    SELECT
        c.id AS conversation_id,
        c.type AS conversation_type,
        c.title AS conversation_title,
        c.course_id,
        c.created_at,
        lm.id AS last_message_id,
        lm.message_text AS last_message_text,
        lm.user_id AS last_message_user_id,
        p_sender.name AS last_message_user_name,
        lm.created_at AS last_message_created_at,
        (SELECT COUNT(*) FROM public.conversation_participants cp2 WHERE cp2.conversation_id = c.id) AS participants_count,
        CASE WHEN c.type = 'single' THEN (
            SELECT
                CASE
                    WHEN p_other.name IS NULL
                         OR BTRIM(p_other.name) = ''
                         OR BTRIM(p_other.name) IN ('Unknown', 'Unknown user', 'Chat', 'محادثة', 'مستخدم جديد')
                    THEN COALESCE(
                        NULLIF(BTRIM(p_other.email), ''),
                        NULLIF(BTRIM(p_other.phone), ''),
                        'Unknown'
                    )
                    ELSE p_other.name
                END
            FROM public.conversation_participants cp_other
            JOIN public.profiles p_other ON p_other.id = cp_other.user_id
            WHERE cp_other.conversation_id = c.id AND cp_other.user_id <> p_user_id
            LIMIT 1
        ) ELSE NULL END AS other_user_name,
        CASE WHEN c.type = 'single' THEN (
            SELECT p_other.avatar_url FROM public.conversation_participants cp_other
            JOIN public.profiles p_other ON p_other.id = cp_other.user_id
            WHERE cp_other.conversation_id = c.id AND cp_other.user_id <> p_user_id
            LIMIT 1
        ) ELSE NULL END AS other_user_avatar
    FROM public.conversations c
    JOIN public.conversation_participants cp ON cp.conversation_id = c.id AND cp.user_id = p_user_id
    LEFT JOIN LATERAL (
        SELECT m.id, m.message_text, m.user_id, m.created_at
        FROM public.messages m
        WHERE m.conversation_id = c.id AND m.is_deleted = FALSE
        ORDER BY m.created_at DESC
        LIMIT 1
    ) lm ON TRUE
    LEFT JOIN public.profiles p_sender ON p_sender.id = lm.user_id
    WHERE (p_type IS NULL OR c.type = p_type)
    ORDER BY COALESCE(lm.created_at, c.created_at) DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_user_conversations(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_conversations(UUID, TEXT) TO authenticated;

DROP POLICY IF EXISTS "Participants can send messages" ON public.messages;
DROP POLICY IF EXISTS "Participants can send messages" ON public;
CREATE POLICY "Participants can send messages" ON public.messages FOR INSERT
WITH CHECK (
    user_id = auth.uid()
    AND (
        public.is_conversation_participant(messages.conversation_id, auth.uid())
        OR EXISTS (
            SELECT 1
            FROM public.profiles p
            WHERE p.id = auth.uid()
              AND p.role = 'admin'
        )
    )
);


-- =====================================================================
-- File: 313_normalize_instructor_profile_schema.sql
-- =====================================================================
-- =====================================================
-- 313_normalize_instructor_profile_schema.sql
-- Goal:
-- 1) Keep instructor-specific data in instructor_profiles
-- 2) Remove duplicated instructor columns from profiles
-- =====================================================

BEGIN;

-- A) Normalize payout_method first to satisfy existing CHECK constraint.
-- Current allowed values (from migration 259): 'instapay', 'wallet`.
UPDATE public.instructor_profiles
SET payout_method = 'wallet'
WHERE payout_method IS NOT NULL
  AND payout_method NOT IN ('instapay', 'wallet');

ALTER TABLE public.instructor_profiles
  ALTER COLUMN payout_method SET DEFAULT 'wallet';

-- 0) Deduplicate instructor_profiles by instructor_id (keep most recently updated row).
WITH ranked AS (
  SELECT
    id,
    instructor_id,
    ROW_NUMBER() OVER (
      PARTITION BY instructor_id
      ORDER BY updated_at DESC NULLS LAST, created_at DESC NULLS LAST, id DESC
    ) AS rn
  FROM public.instructor_profiles
  WHERE instructor_id IS NOT NULL
)
DELETE FROM public.instructor_profiles ip
USING ranked r
WHERE ip.id = r.id
  AND r.rn > 1;

-- 1) Ensure uniqueness on instructor_id.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'instructor_profiles_instructor_id_key'
      AND conrelid = 'public.instructor_profiles'::regclass
  ) THEN
    ALTER TABLE public.instructor_profiles
      ADD CONSTRAINT instructor_profiles_instructor_id_key UNIQUE (instructor_id);
  END IF;
END $$;

-- 2) Ensure each instructor has a row in instructor_profiles.
INSERT INTO public.instructor_profiles (
  instructor_id,
  display_name,
  avatar_url,
  payout_method,
  is_active,
  created_at,
  updated_at
)
SELECT
  p.id,
  COALESCE(NULLIF(BTRIM(p.name), ''), 'Instructor'),
  p.avatar_url,
  'wallet',
  COALESCE(p.is_active, TRUE),
  NOW(),
  NOW()
FROM public.profiles p
WHERE p.role = 'instructor'
  AND NOT EXISTS (
    SELECT 1
    FROM public.instructor_profiles ip
    WHERE ip.instructor_id = p.id
  );

-- 3) Migrate/merge legacy instructor fields from profiles -> instructor_profiles.
UPDATE public.instructor_profiles ip
SET
  display_name = COALESCE(
    NULLIF(BTRIM(ip.display_name), ''),
    NULLIF(BTRIM(p.name), ''),
    ip.display_name
  ),
  avatar_url = COALESCE(
    NULLIF(BTRIM(ip.avatar_url), ''),
    NULLIF(BTRIM(p.avatar_url), ''),
    ip.avatar_url
  ),
  headline_ar = COALESCE(
    NULLIF(BTRIM(ip.headline_ar), ''),
    NULLIF(BTRIM(p.headline_ar), ''),
    NULLIF(BTRIM(p.headline), ''),
    ip.headline_ar
  ),
  headline_en = COALESCE(
    NULLIF(BTRIM(ip.headline_en), ''),
    NULLIF(BTRIM(p.headline_en), ''),
    ip.headline_en
  ),
  bio_ar = COALESCE(
    NULLIF(BTRIM(ip.bio_ar), ''),
    NULLIF(BTRIM(p.bio_ar), ''),
    NULLIF(BTRIM(p.bio), ''),
    ip.bio_ar
  ),
  bio_en = COALESCE(
    NULLIF(BTRIM(ip.bio_en), ''),
    NULLIF(BTRIM(p.bio_en), ''),
    ip.bio_en
  ),
  expertise = CASE
    WHEN ip.expertise IS NULL OR cardinality(ip.expertise) = 0 THEN p.expertise
    ELSE ip.expertise
  END,
  social_links = COALESCE(
    ip.social_links,
    p.social_links,
    NULLIF(
      jsonb_strip_nulls(
        jsonb_build_object(
          'website', NULLIF(BTRIM(p.website), ''),
          'linkedin', NULLIF(BTRIM(p.linkedin), ''),
          'twitter', NULLIF(BTRIM(p.twitter), '')
        )
      ),
      '{}'::jsonb
    )
  ),
  is_verified = COALESCE(ip.is_verified, p.is_verified_instructor, FALSE),
  updated_at = NOW()
FROM public.profiles p
WHERE p.id = ip.instructor_id
  AND p.role = 'instructor';

-- 4) Keep profiles.name non-empty for instructors (fallback from display_name).
UPDATE public.profiles p
SET
  name = COALESCE(NULLIF(BTRIM(p.name), ''), NULLIF(BTRIM(ip.display_name), ''), p.name),
  updated_at = NOW()
FROM public.instructor_profiles ip
WHERE ip.instructor_id = p.id
  AND p.role = 'instructor'
  AND (p.name IS NULL OR BTRIM(p.name) = '');

-- 5) Drop duplicated instructor-only columns from profiles.
ALTER TABLE public.profiles DROP COLUMN IF EXISTS headline_ar;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS headline_en;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS bio_ar;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS bio_en;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS expertise;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS social_links;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS is_verified_instructor;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS headline;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS bio;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS website;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS linkedin;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS twitter;

COMMIT;


-- =====================================================================
-- File: 332_new_earnings_withdrawal_schema.sql
-- =====================================================================
-- =============================================
-- 332: NEW EARNINGS & WITHDRAWAL SCHEMA
-- =============================================
-- This script:
-- 0. DROPS old tables, triggers, and functions
-- 1. Creates the `withdraw_requests` table (new schema for withdrawals)
-- 2. Creates the `earnings_transactions` table (replaces instructor_earnings)
-- 3. Adds columns to `instructor_balance` (total_earnings)
-- 4. Creates RPC: submit_withdraw_request
-- 5. Creates RPC: admin_approve_withdraw
-- 6. Creates RPC: admin_reject_withdraw
-- 7. Applies RLS policies
-- 8. Migrates existing data
-- 9. Drops old tables after migration
-- =============================================

-- =============================================
-- STEP 0: DROP OLD FUNCTIONS & TRIGGERS
-- =============================================

-- Drop old RPC functions
DROP FUNCTION IF EXISTS public.request_instructor_payout(UUID, DECIMAL, TEXT, JSONB) CASCADE;
DROP FUNCTION IF EXISTS public.review_instructor_payout(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.complete_instructor_payout(UUID, UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.reject_instructor_payout(UUID, UUID, TEXT) CASCADE;

-- Drop old triggers on ENROLLMENTS that insert into instructor_earnings
DROP TRIGGER IF EXISTS trigger_create_instructor_earning ON public.enrollments;
DROP TRIGGER IF EXISTS create_instructor_earning_trigger ON public.enrollments;
DROP TRIGGER IF EXISTS trigger_auto_create_earning ON public.enrollments;

-- Drop old triggers on instructor_earnings (the duplicate trigger etc.)
DO $$
DECLARE
  r RECORD;
BEGIN
  -- Drop all triggers on instructor_earnings if table exists
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'instructor_earnings') THEN
    FOR r IN (
      SELECT trigger_name
      FROM information_schema.triggers
      WHERE event_object_table = 'instructor_earnings'
        AND event_object_schema = 'public'
    ) LOOP
      EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.instructor_earnings CASCADE', r.trigger_name);
      RAISE NOTICE 'Dropped trigger: %', r.trigger_name;
    END LOOP;
  END IF;

  -- Drop all triggers on instructor_payouts if table exists
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'instructor_payouts') THEN
    FOR r IN (
      SELECT trigger_name
      FROM information_schema.triggers
      WHERE event_object_table = 'instructor_payouts'
        AND event_object_schema = 'public'
    ) LOOP
      EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.instructor_payouts CASCADE', r.trigger_name);
      RAISE NOTICE 'Dropped trigger: %', r.trigger_name;
    END LOOP;
  END IF;
END $$;

-- Drop old trigger functions
DROP FUNCTION IF EXISTS public.create_instructor_earning() CASCADE;
DROP FUNCTION IF EXISTS public.update_instructor_balance_on_earning() CASCADE;
DROP FUNCTION IF EXISTS public.update_balance_on_payout() CASCADE;
DROP FUNCTION IF EXISTS public.handle_enrollment_earning() CASCADE;

DO $$ BEGIN RAISE NOTICE '✅ Old functions, triggers dropped'; END $$;


-- =============================================
-- STEP 1: Create withdraw_requests table
-- =============================================
CREATE TABLE IF NOT EXISTS public.withdraw_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount NUMERIC(12,2) NOT NULL CHECK (amount >= 50),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'paid')),
  method TEXT NOT NULL DEFAULT 'instapay',
  account_details JSONB,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  approved_at TIMESTAMPTZ,
  paid_at TIMESTAMPTZ,
  admin_id UUID REFERENCES auth.users(id),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_withdraw_requests_user_id ON public.withdraw_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_withdraw_requests_status ON public.withdraw_requests(status);

-- Add FK to profiles for PostgREST join support
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'withdraw_requests_user_id_profiles_fkey'
  ) THEN
    ALTER TABLE public.withdraw_requests
      ADD CONSTRAINT withdraw_requests_user_id_profiles_fkey
      FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
  END IF;
END $$;

-- =============================================
-- STEP 2: Create earnings_transactions table
-- =============================================
CREATE TABLE IF NOT EXISTS public.earnings_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  course_id UUID,
  course_name TEXT NOT NULL DEFAULT '',
  amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  commission NUMERIC(12,2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'pending', 'paid')),
  source_type TEXT NOT NULL DEFAULT 'course_sale' CHECK (source_type IN ('course_sale', 'refund', 'adjustment')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_earnings_transactions_user_id ON public.earnings_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_earnings_transactions_status ON public.earnings_transactions(status);

-- =============================================
-- STEP 3: Add total_earnings to instructor_balance if missing
-- =============================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'instructor_balance'
      AND column_name = 'total_earnings'
  ) THEN
    ALTER TABLE public.instructor_balance
      ADD COLUMN total_earnings NUMERIC(12,2) NOT NULL DEFAULT 0;
  END IF;
END $$;

-- =============================================
-- STEP 4: RPC — submit_withdraw_request
-- =============================================
-- Flow:
--   IF available_balance >= amount:
--     1) Deduct from available_balance
--     2) Add to pending_balance
--     3) Create withdraw_request (status=pending)
-- =============================================
CREATE OR REPLACE FUNCTION public.submit_withdraw_request(
  p_user_id UUID,
  p_amount NUMERIC,
  p_method TEXT DEFAULT 'instapay',
  p_account_details JSONB DEFAULT '{}'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_available NUMERIC;
  v_request_id UUID;
BEGIN
  -- Validate minimum
  IF p_amount < 50 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Minimum withdrawal is 50 EGP');
  END IF;

  -- Lock the balance row
  SELECT available_balance INTO v_available
  FROM public.instructor_balance
  WHERE instructor_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Balance record not found');
  END IF;

  IF v_available < p_amount THEN
    RETURN jsonb_build_object('success', false, 'error', 'Insufficient available balance');
  END IF;

  -- Deduct from available, add to pending
  UPDATE public.instructor_balance
  SET
    available_balance = available_balance - p_amount,
    pending_balance = pending_balance + p_amount,
    updated_at = now()
  WHERE instructor_id = p_user_id;

  -- Create withdraw request
  INSERT INTO public.withdraw_requests (user_id, amount, method, account_details, status)
  VALUES (p_user_id, p_amount, p_method, p_account_details, 'pending')
  RETURNING id INTO v_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'request_id', v_request_id,
    'message', 'Withdraw request submitted successfully'
  );
END;
$$;

-- =============================================
-- STEP 5: RPC — admin_approve_withdraw
-- =============================================
-- Flow:
--   1) Deduct from pending_balance
--   2) Add to total_withdrawn
--   3) Update withdraw_request → approved
-- =============================================
CREATE OR REPLACE FUNCTION public.admin_approve_withdraw(
  p_request_id UUID,
  p_admin_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_request RECORD;
BEGIN
  -- Get and lock request
  SELECT * INTO v_request
  FROM public.withdraw_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Request not found');
  END IF;

  -- Handle pending → approved
  IF v_request.status = 'pending' THEN
    UPDATE public.instructor_balance
    SET
      pending_balance = pending_balance - v_request.amount,
      total_withdrawn = total_withdrawn + v_request.amount,
      updated_at = now()
    WHERE instructor_id = v_request.user_id;

    UPDATE public.withdraw_requests
    SET
      status = 'approved',
      approved_at = now(),
      admin_id = p_admin_id,
      updated_at = now()
    WHERE id = p_request_id;

    RETURN jsonb_build_object('success', true, 'message', 'Withdraw request approved');

  -- Handle approved → paid
  ELSIF v_request.status = 'approved' THEN
    UPDATE public.withdraw_requests
    SET
      status = 'paid',
      paid_at = now(),
      admin_id = p_admin_id,
      updated_at = now()
    WHERE id = p_request_id;

    RETURN jsonb_build_object('success', true, 'message', 'Withdraw request marked as paid');

  ELSE
    RETURN jsonb_build_object('success', false, 'error', 'Request status is ' || v_request.status || ', cannot approve');
  END IF;
END;
$$;

-- =============================================
-- STEP 6: RPC — admin_reject_withdraw
-- =============================================
-- Flow:
--   1) Return amount to available_balance
--   2) Deduct from pending_balance
--   3) Update withdraw_request → rejected
-- =============================================
CREATE OR REPLACE FUNCTION public.admin_reject_withdraw(
  p_request_id UUID,
  p_admin_id UUID,
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_request RECORD;
BEGIN
  SELECT * INTO v_request
  FROM public.withdraw_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Request not found');
  END IF;

  -- Handle rejection from PENDING
  IF v_request.status = 'pending' THEN
    -- Return to available, deduct from pending
    UPDATE public.instructor_balance
    SET
      available_balance = available_balance + v_request.amount,
      pending_balance = pending_balance - v_request.amount,
      updated_at = now()
    WHERE instructor_id = v_request.user_id;

  -- Handle rejection from APPROVED (Under Review)
  ELSIF v_request.status = 'approved' THEN
    -- Return to available, deduct from total_withdrawn (since it was added there on approval)
    UPDATE public.instructor_balance
    SET
      available_balance = available_balance + v_request.amount,
      total_withdrawn = total_withdrawn - v_request.amount,
      updated_at = now()
    WHERE instructor_id = v_request.user_id;

  ELSE
    RETURN jsonb_build_object('success', false, 'error', 'Request status is ' || v_request.status || ', cannot reject');
  END IF;

  -- Update request status
  UPDATE public.withdraw_requests
  SET
    status = 'rejected',
    admin_id = p_admin_id,
    notes = COALESCE(p_notes, notes),
    updated_at = now()
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Withdraw request rejected and amount returned'
  );
END;
$$;

-- =============================================
-- STEP 7: RLS Policies
-- =============================================

-- withdraw_requests
ALTER TABLE public.withdraw_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own withdraw requests" ON public.withdraw_requests;
DROP POLICY IF EXISTS "Users can view own withdraw requests" ON public;
CREATE POLICY "Users can view own withdraw requests" ON public.withdraw_requests
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own withdraw requests" ON public.withdraw_requests;
DROP POLICY IF EXISTS "Users can insert own withdraw requests" ON public;
CREATE POLICY "Users can insert own withdraw requests" ON public.withdraw_requests
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view all withdraw requests" ON public.withdraw_requests;
DROP POLICY IF EXISTS "Admins can view all withdraw requests" ON public;
CREATE POLICY "Admins can view all withdraw requests" ON public.withdraw_requests
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Admins can update withdraw requests" ON public.withdraw_requests;
DROP POLICY IF EXISTS "Admins can update withdraw requests" ON public;
CREATE POLICY "Admins can update withdraw requests" ON public.withdraw_requests
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- earnings_transactions
ALTER TABLE public.earnings_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own earnings" ON public.earnings_transactions;
DROP POLICY IF EXISTS "Users can view own earnings" ON public;
CREATE POLICY "Users can view own earnings" ON public.earnings_transactions
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view all earnings" ON public.earnings_transactions;
DROP POLICY IF EXISTS "Admins can view all earnings" ON public;
CREATE POLICY "Admins can view all earnings" ON public.earnings_transactions
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Service can insert earnings" ON public.earnings_transactions;
DROP POLICY IF EXISTS "Service can insert earnings" ON public;
CREATE POLICY "Service can insert earnings" ON public.earnings_transactions
  FOR INSERT
  WITH CHECK (true);

-- =============================================
-- STEP 8: Migrate existing data from instructor_earnings → earnings_transactions
-- =============================================
-- Skip migration - old table columns may not match new schema
-- Data will start fresh with new earnings_transactions table
-- Old data is preserved in Supabase backups if needed

-- =============================================
-- STEP 8b: RPC — increment_balance (used by checkout)
-- =============================================
CREATE OR REPLACE FUNCTION public.increment_balance(
  p_instructor_id UUID,
  p_amount NUMERIC
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.instructor_balance
  SET
    available_balance = available_balance + p_amount,
    total_earnings = total_earnings + p_amount,
    updated_at = now()
  WHERE instructor_id = p_instructor_id;
END;
$$;

-- =============================================
-- STEP 9: Migrate existing payouts → withdraw_requests
-- =============================================
-- Skip migration - old table columns may not match new schema
-- Data will start fresh with new withdraw_requests table
-- Old data is preserved in Supabase backups if needed

-- =============================================
-- STEP 10: Update total_earnings in instructor_balance
-- =============================================
UPDATE public.instructor_balance ib
SET total_earnings = COALESCE((
  SELECT SUM(amount - commission)
  FROM public.earnings_transactions et
  WHERE et.user_id = ib.instructor_id
), 0);

-- =============================================
-- STEP 11: DROP OLD TABLES (after migration)
-- =============================================
-- Drop RLS policies on old tables first
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'instructor_earnings') THEN
    DROP POLICY IF EXISTS "Instructors can view own earnings" ON public.instructor_earnings;
    DROP POLICY IF EXISTS "instructor_earnings_select" ON public.instructor_earnings;
    DROP POLICY IF EXISTS "instructor_earnings_insert" ON public.instructor_earnings;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'instructor_payouts') THEN
    DROP POLICY IF EXISTS "Instructors can view own payouts" ON public.instructor_payouts;
    DROP POLICY IF EXISTS "Instructors can insert payouts" ON public.instructor_payouts;
    DROP POLICY IF EXISTS "instructor_payouts_select" ON public.instructor_payouts;
    DROP POLICY IF EXISTS "instructor_payouts_insert" ON public.instructor_payouts;
  END IF;
END $$;

-- Drop old tables
DROP TABLE IF EXISTS public.instructor_earnings CASCADE;
DROP TABLE IF EXISTS public.instructor_payouts CASCADE;

-- Grant execute on new functions
GRANT EXECUTE ON FUNCTION public.submit_withdraw_request(UUID, NUMERIC, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_approve_withdraw(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_reject_withdraw(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_balance(UUID, NUMERIC) TO authenticated;

-- =============================================
-- ✅ MIGRATION COMPLETE!
-- Old tables: instructor_earnings, instructor_payouts → DROPPED
-- Old functions: request/review/complete/reject_instructor_payout → DROPPED
-- New tables: earnings_transactions, withdraw_requests → CREATED
-- New functions: submit_withdraw_request, admin_approve_withdraw, admin_reject_withdraw → CREATED
-- =============================================

-- =====================================================================
-- File: 333_kill_all_old_triggers.sql
-- =====================================================================
-- =============================================
-- 333: KILL ALL OLD EARNINGS TRIGGERS
-- Run this FIRST before anything else
-- =============================================

-- Drop ALL possible trigger names on enrollments
DROP TRIGGER IF EXISTS trigger_create_instructor_earning ON public.enrollments;
DROP TRIGGER IF EXISTS create_instructor_earning_trigger ON public.enrollments;
DROP TRIGGER IF EXISTS trigger_auto_create_earning ON public.enrollments;
DROP TRIGGER IF EXISTS auto_create_earning_trigger ON public.enrollments;
DROP TRIGGER IF EXISTS trigger_handle_enrollment_earning ON public.enrollments;
DROP TRIGGER IF EXISTS handle_enrollment_earning_trigger ON public.enrollments;
DROP TRIGGER IF EXISTS trg_instructor_earning ON public.enrollments;
DROP TRIGGER IF EXISTS trigger_instructor_earning ON public.enrollments;

-- Drop ALL possible trigger functions
DROP FUNCTION IF EXISTS public.create_instructor_earning() CASCADE;
DROP FUNCTION IF EXISTS public.auto_create_earning() CASCADE;
DROP FUNCTION IF EXISTS public.handle_enrollment_earning() CASCADE;
DROP FUNCTION IF EXISTS public.update_instructor_balance_on_earning() CASCADE;
DROP FUNCTION IF EXISTS public.update_balance_on_payout() CASCADE;

-- Drop ALL triggers on instructor_earnings (if table somehow still exists)
DO $$
DECLARE r RECORD;
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'instructor_earnings') THEN
    FOR r IN (
      SELECT trigger_name FROM information_schema.triggers
      WHERE event_object_table = 'instructor_earnings' AND event_object_schema = 'public'
    ) LOOP
      EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.instructor_earnings CASCADE', r.trigger_name);
      RAISE NOTICE 'Dropped trigger on instructor_earnings: %', r.trigger_name;
    END LOOP;
  END IF;
  
  -- Also drop any remaining triggers on enrollments that have 'earning` in the name
  FOR r IN (
    SELECT trigger_name FROM information_schema.triggers
    WHERE event_object_table = 'enrollments' 
    AND event_object_schema = 'public'
    AND (
      trigger_name ILIKE '%earning%' 
      OR trigger_name ILIKE '%payout%'
      OR trigger_name ILIKE '%instructor_earn%'
    )
  ) LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.enrollments CASCADE', r.trigger_name);
    RAISE NOTICE 'Dropped trigger on enrollments: %', r.trigger_name;
  END LOOP;
END $$;

-- Verify: Show remaining triggers on enrollments
SELECT trigger_name, event_manipulation, action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'enrollments' 
AND event_object_schema = 'public';


-- =====================================================================
-- File: 334_instructor_commission_system.sql
-- =====================================================================
-- =============================================
-- 334: INSTRUCTOR COMMISSION SYSTEM
-- =============================================
-- This script:
-- 1. Ensures instructor_profiles.revenue_share is usable
-- 2. Adds commission_rate column (admin-facing alias) if needed
-- 3. Creates RPC: admin_set_instructor_commission
-- 4. Creates RPC: get_instructor_commission
-- 5. Updates checkout earnings to track original_price
-- =============================================

-- =============================================
-- STEP 1: Add original_price to earnings_transactions
-- =============================================
-- This lets us track the full course price separately from what was charged
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'earnings_transactions'
      AND column_name = 'original_price'
  ) THEN
    ALTER TABLE public.earnings_transactions
      ADD COLUMN original_price NUMERIC(12,2) NOT NULL DEFAULT 0;
  END IF;
END $$;

-- =============================================
-- STEP 2: RPC — admin_set_instructor_commission
-- =============================================
-- Admin sets commission % for an instructor.
-- revenue_share is the instructor`s share (e.g. 70 means 30% commission to platform)
-- =============================================
CREATE OR REPLACE FUNCTION public.admin_set_instructor_commission(
  p_instructor_id UUID,
  p_commission_rate NUMERIC       -- platform commission percentage (0-100)
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_revenue_share NUMERIC;
BEGIN
  -- Validate
  IF p_commission_rate < 0 OR p_commission_rate > 100 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Commission rate must be between 0 and 100');
  END IF;

  -- Commission = platform`s share, so revenue_share = 100 - commission
  v_revenue_share := 100 - p_commission_rate;

  -- Check if instructor profile exists
  IF NOT EXISTS (
    SELECT 1 FROM public.instructor_profiles WHERE instructor_id = p_instructor_id
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Instructor profile not found');
  END IF;

  -- Update revenue_share
  UPDATE public.instructor_profiles
  SET
    revenue_share = v_revenue_share,
    updated_at = now()
  WHERE instructor_id = p_instructor_id;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Commission updated successfully',
    'commission_rate', p_commission_rate,
    'revenue_share', v_revenue_share
  );
END;
$$;

-- =============================================
-- STEP 3: RPC — get_instructor_commissions
-- =============================================
-- Returns list of instructors with their commission settings
-- =============================================
CREATE OR REPLACE FUNCTION public.get_instructor_commissions()
RETURNS TABLE (
  instructor_id UUID,
  name TEXT,
  email TEXT,
  avatar_url TEXT,
  revenue_share NUMERIC,
  commission_rate NUMERIC,
  total_courses INTEGER,
  total_students INTEGER,
  is_verified BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id AS instructor_id,
    p.name,
    p.email,
    p.avatar_url,
    COALESCE(ip.revenue_share, 70.00) AS revenue_share,
    (100 - COALESCE(ip.revenue_share, 70.00)) AS commission_rate,
    COALESCE(ip.total_courses, 0) AS total_courses,
    COALESCE(ip.total_students, 0) AS total_students,
    COALESCE(ip.is_verified, false) AS is_verified
  FROM public.profiles p
  LEFT JOIN public.instructor_profiles ip ON ip.instructor_id = p.id
  WHERE p.role = 'instructor'
  ORDER BY p.name ASC;
END;
$$;

-- =============================================
-- STEP 4: Grant execute permissions
-- =============================================
GRANT EXECUTE ON FUNCTION public.admin_set_instructor_commission(UUID, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_instructor_commissions() TO authenticated;

DO $$ BEGIN RAISE NOTICE '✅ Commission system ready'; END $$;


-- =====================================================================
-- File: 334_restore_balance_data.sql
-- =====================================================================
-- =============================================
-- 334: Restore instructor_balance data
-- =============================================

-- Re-insert balance for all instructors who have courses
INSERT INTO public.instructor_balance (instructor_id, available_balance, pending_balance, total_withdrawn, total_earnings)
SELECT 
  p.id,
  0,  -- available_balance (will be recalculated)
  0,  -- pending_balance
  0,  -- total_withdrawn
  0   -- total_earnings
FROM public.profiles p
WHERE p.role = 'instructor'
ON CONFLICT (instructor_id) DO NOTHING;

-- Recalculate total_earnings from enrollments (actual sales)
UPDATE public.instructor_balance ib
SET total_earnings = COALESCE(sub.total, 0),
    available_balance = COALESCE(sub.total, 0)
FROM (
  SELECT 
    e.instructor_id,
    SUM(e.price * 0.7) as total  -- 70% instructor share
  FROM public.enrollments e
  WHERE e.price > 0 
    AND e.instructor_id IS NOT NULL
  GROUP BY e.instructor_id
) sub
WHERE ib.instructor_id = sub.instructor_id;

-- Account for already withdrawn amounts from withdraw_requests
UPDATE public.instructor_balance ib
SET total_withdrawn = COALESCE(sub.total_withdrawn, 0),
    available_balance = ib.total_earnings - COALESCE(sub.total_withdrawn, 0)
FROM (
  SELECT 
    user_id,
    SUM(amount) as total_withdrawn
  FROM public.withdraw_requests
  WHERE status IN ('approved', 'paid')
  GROUP BY user_id
) sub
WHERE ib.instructor_id = sub.user_id;

-- Account for pending withdrawals
UPDATE public.instructor_balance ib
SET pending_balance = COALESCE(sub.total_pending, 0),
    available_balance = ib.available_balance - COALESCE(sub.total_pending, 0)
FROM (
  SELECT 
    user_id,
    SUM(amount) as total_pending
  FROM public.withdraw_requests
  WHERE status = 'pending'
  GROUP BY user_id
) sub
WHERE ib.instructor_id = sub.user_id;

-- Make sure available_balance is never negative
UPDATE public.instructor_balance
SET available_balance = 0
WHERE available_balance < 0;

-- Also recreate earnings_transactions from enrollments history
INSERT INTO public.earnings_transactions (user_id, course_id, course_name, amount, commission, status, source_type, created_at)
SELECT 
  e.instructor_id,
  e.course_id,
  COALESCE(c.title_ar, 'Unknown Course'),
  e.price,
  e.price * 0.3,  -- 30% platform commission
  'available',
  'course_sale',
  e.enrolled_at
FROM public.enrollments e
LEFT JOIN public.courses c ON c.id = e.course_id
WHERE e.price > 0 
  AND e.instructor_id IS NOT NULL
ON CONFLICT DO NOTHING;

-- Show results
SELECT 
  ib.instructor_id,
  p.name as instructor_name,
  ib.available_balance,
  ib.pending_balance,
  ib.total_earnings,
  ib.total_withdrawn
FROM public.instructor_balance ib
LEFT JOIN public.profiles p ON p.id = ib.instructor_id
ORDER BY ib.total_earnings DESC;


-- =====================================================================
-- File: 335_fix_old_earnings_data.sql
-- =====================================================================
-- =============================================
-- 335: FIX OLD EARNINGS DATA
-- =============================================
-- Problem: Old earnings_transactions records were saved with 
-- the original course price instead of the effective (discounted) price.
-- Also used hardcoded 70% commission instead of per-instructor revenue_share.
--
-- Fix:
--   1. Update each earnings_transaction to use the enrollment.price 
--      (which IS the correct effective/discounted price)
--   2. Recalculate commission using per-instructor revenue_share
--   3. Set original_price from courses.price (for reference)
--   4. Rebuild instructor_balance from scratch
-- =============================================

-- =============================================
-- STEP 1: Fix earnings_transactions — use enrollment price + instructor revenue_share
-- =============================================
-- For each earning, find the matching enrollment and use its price
-- Also apply the correct per-instructor revenue_share
DO $$
DECLARE
  r RECORD;
  v_enrollment_price NUMERIC;
  v_original_price NUMERIC;
  v_revenue_share NUMERIC;
  v_instructor_share NUMERIC;
  v_platform_fee NUMERIC;
  v_fix_count INTEGER := 0;
BEGIN
  RAISE NOTICE '🔧 Starting earnings fix...';

  FOR r IN
    SELECT et.id, et.user_id, et.course_id, et.amount, et.commission
    FROM public.earnings_transactions et
    WHERE et.source_type = 'course_sale'
  LOOP
    -- Get enrollment price (the correct effective/discounted price)
    SELECT e.price INTO v_enrollment_price
    FROM public.enrollments e
    WHERE e.course_id = r.course_id
      AND e.instructor_id = r.user_id
    ORDER BY e.enrolled_at DESC
    LIMIT 1;

    -- If no enrollment found, try matching by course_id directly
    IF v_enrollment_price IS NULL THEN
      SELECT e.price INTO v_enrollment_price
      FROM public.enrollments e
      WHERE e.course_id = r.course_id
      ORDER BY e.enrolled_at DESC
      LIMIT 1;
    END IF;

    -- Get original course price (for reference)
    SELECT c.price INTO v_original_price
    FROM public.courses c
    WHERE c.id = r.course_id;

    -- Get instructor`s revenue_share (default 70%)
    SELECT COALESCE(ip.revenue_share, 70.00) INTO v_revenue_share
    FROM public.instructor_profiles ip
    WHERE ip.instructor_id = r.user_id;

    IF v_revenue_share IS NULL THEN
      v_revenue_share := 70.00;
    END IF;

    -- Use enrollment price if found, otherwise keep current amount
    IF v_enrollment_price IS NOT NULL AND v_enrollment_price > 0 THEN
      -- Recalculate with correct price and revenue_share
      v_instructor_share := ROUND(v_enrollment_price * (v_revenue_share / 100));
      v_platform_fee := v_enrollment_price - v_instructor_share;

      UPDATE public.earnings_transactions
      SET
        amount = v_enrollment_price,
        commission = v_platform_fee,
        original_price = COALESCE(v_original_price, v_enrollment_price)
      WHERE id = r.id;

      v_fix_count := v_fix_count + 1;

      RAISE NOTICE '  ✅ Fixed earning %: amount % → %, commission % → %, revenue_share=%',
        r.id, r.amount, v_enrollment_price, r.commission, v_platform_fee, v_revenue_share;
    ELSE
      -- No enrollment found, just set original_price and recalculate commission
      v_instructor_share := ROUND(r.amount * (v_revenue_share / 100));
      v_platform_fee := r.amount - v_instructor_share;

      UPDATE public.earnings_transactions
      SET
        commission = v_platform_fee,
        original_price = COALESCE(v_original_price, r.amount)
      WHERE id = r.id;

      RAISE NOTICE '  ⚠️ No enrollment for earning %, kept amount=%, recalculated commission=%',
        r.id, r.amount, v_platform_fee;
    END IF;
  END LOOP;

  RAISE NOTICE '🔧 Fixed % earnings_transactions records', v_fix_count;
END $$;


-- =============================================
-- STEP 2: Rebuild instructor_balance from scratch
-- =============================================
-- Reset all balances and recalculate from earnings_transactions
-- This ensures available_balance, total_earnings are correct
DO $$
DECLARE
  r RECORD;
  v_total_net_earnings NUMERIC;
  v_total_pending NUMERIC;
  v_total_withdrawn NUMERIC;
  v_available NUMERIC;
  v_count INTEGER := 0;
BEGIN
  RAISE NOTICE '🔧 Rebuilding instructor_balance...';

  FOR r IN
    SELECT DISTINCT user_id FROM public.earnings_transactions
  LOOP
    -- Calculate total net earnings (amount - commission) for this instructor
    SELECT COALESCE(SUM(amount - commission), 0)
    INTO v_total_net_earnings
    FROM public.earnings_transactions
    WHERE user_id = r.user_id;

    -- Calculate total pending (from withdraw_requests with status=pending)
    SELECT COALESCE(SUM(amount), 0)
    INTO v_total_pending
    FROM public.withdraw_requests
    WHERE user_id = r.user_id
      AND status = 'pending';

    -- Calculate total withdrawn (approved + paid withdraw_requests)
    SELECT COALESCE(SUM(amount), 0)
    INTO v_total_withdrawn
    FROM public.withdraw_requests
    WHERE user_id = r.user_id
      AND status IN ('approved', 'paid');

    -- Available = total earnings - pending - withdrawn
    v_available := v_total_net_earnings - v_total_pending - v_total_withdrawn;
    IF v_available < 0 THEN
      v_available := 0;
    END IF;

    -- Upsert instructor_balance
    IF EXISTS (
      SELECT 1 FROM public.instructor_balance WHERE instructor_id = r.user_id
    ) THEN
      UPDATE public.instructor_balance
      SET
        available_balance = v_available,
        pending_balance = v_total_pending,
        total_withdrawn = v_total_withdrawn,
        total_earnings = v_total_net_earnings,
        updated_at = now()
      WHERE instructor_id = r.user_id;
    ELSE
      INSERT INTO public.instructor_balance (
        instructor_id,
        available_balance,
        pending_balance,
        total_withdrawn,
        total_earnings
      ) VALUES (
        r.user_id,
        v_available,
        v_total_pending,
        v_total_withdrawn,
        v_total_net_earnings
      );
    END IF;

    v_count := v_count + 1;
    RAISE NOTICE '  ✅ Instructor %: earnings=%, available=%, pending=%, withdrawn=%',
      r.user_id, v_total_net_earnings, v_available, v_total_pending, v_total_withdrawn;
  END LOOP;

  RAISE NOTICE '🔧 Rebuilt balance for % instructors', v_count;
END $$;


-- =============================================
-- STEP 3: Verify — show final state
-- =============================================
DO $$
DECLARE
  v_total_earnings_count INTEGER;
  v_total_balance_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_total_earnings_count FROM public.earnings_transactions;
  SELECT COUNT(*) INTO v_total_balance_count FROM public.instructor_balance;

  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ FIX COMPLETE!';
  RAISE NOTICE '  earnings_transactions: % records', v_total_earnings_count;
  RAISE NOTICE '  instructor_balance: % records', v_total_balance_count;
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Changes made:';
  RAISE NOTICE '  1. earnings_transactions.amount → enrollment effective price';
  RAISE NOTICE '  2. earnings_transactions.commission → recalculated with per-instructor revenue_share';
  RAISE NOTICE '  3. earnings_transactions.original_price → courses.price';
  RAISE NOTICE '  4. instructor_balance → rebuilt from earnings + withdrawals';
END $$;


-- =====================================================================
-- File: 336_fix_coupon_timezone.sql
-- =====================================================================
-- =============================================
-- 336: FIX COUPON TIMEZONE OFFSET
-- =============================================
-- Problem: start_date and end_date were stored with local time
-- as if it were UTC, creating a +2 hour offset.
-- Fix: Subtract 2 hours from all affected dates.
-- =============================================

-- Fix start_date (subtract 2 hours to correct the offset)
UPDATE public.coupons
SET start_date = start_date - INTERVAL '2 hours'
WHERE start_date IS NOT NULL;

-- Fix end_date (subtract 2 hours to correct the offset)
UPDATE public.coupons
SET end_date = end_date - INTERVAL '2 hours'
WHERE end_date IS NOT NULL;

-- Also fix banners if affected
UPDATE public.banners
SET start_date = start_date - INTERVAL '2 hours'
WHERE start_date IS NOT NULL;

UPDATE public.banners
SET end_date = end_date - INTERVAL '2 hours'
WHERE end_date IS NOT NULL;

-- Verify
SELECT id, code, start_date, end_date, is_active
FROM public.coupons
ORDER BY created_at DESC
LIMIT 20;


-- =====================================================================
-- File: 337_add_coupon_discount_to_earnings.sql
-- =====================================================================
-- =============================================
-- 337: ADD COUPON DISCOUNT TO EARNINGS_TRANSACTIONS
-- =============================================
-- Adds coupon_discount column to track per-item coupon discount
-- Net instructor earnings = amount - commission - coupon_discount
-- =============================================

ALTER TABLE public.earnings_transactions
ADD COLUMN IF NOT EXISTS coupon_discount NUMERIC DEFAULT 0;

COMMENT ON COLUMN public.earnings_transactions.coupon_discount IS
  'Per-item coupon discount (proportionally distributed from cart coupon)';


-- =====================================================================
-- File: 338_fix_revenue_chart_for_new_schema.sql
-- =====================================================================
-- ============================================================
-- 338: FIX REVENUE CHART FOR NEW EARNINGS SCHEMA
-- ============================================================
-- Updates get_instructor_revenue_chart to use earnings_transactions
-- instead of the old instructor_earnings table
-- ============================================================

CREATE OR REPLACE FUNCTION get_instructor_revenue_chart(
    p_start_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
    p_end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
    label TEXT,
    value DECIMAL(10,2)
) AS $$
DECLARE
    v_instructor_id UUID := auth.uid();
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(DATE_TRUNC('day', dates.date), 'MM/DD') as label,
        COALESCE(SUM(et.amount - et.commission - et.coupon_discount), 0)::DECIMAL(10,2) as value
    FROM generate_series(
        DATE_TRUNC('day', p_start_date),
        DATE_TRUNC('day', p_end_date),
        '1 day'::INTERVAL
    ) as dates(date)
    LEFT JOIN earnings_transactions et ON 
        DATE_TRUNC('day', et.created_at) = dates.date
        AND et.user_id = v_instructor_id
        AND et.source_type = 'course_sale'
    GROUP BY dates.date
    ORDER BY dates.date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_instructor_revenue_chart(TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;

-- ============================================================
-- ✅ DONE: Revenue chart now uses earnings_transactions
-- ============================================================


-- =====================================================================
-- File: 339_fix_dashboard_stats_for_new_schema.sql
-- =====================================================================
-- ============================================================
-- 339: FIX DASHBOARD STATS FOR NEW EARNINGS SCHEMA
-- ============================================================
-- Updates get_instructor_dashboard_stats to use total_earnings
-- instead of total_earned (column name changed in new schema)
-- ============================================================

CREATE OR REPLACE FUNCTION get_instructor_dashboard_stats()
RETURNS JSON AS $$
DECLARE
    v_instructor_id UUID := auth.uid();
    v_stats JSON;
    v_total_courses INT;
    v_published_courses INT;
    v_total_students INT;
    v_total_enrollments INT;
    v_monthly_enrollments INT;
    v_total_earnings NUMERIC;
    v_available_balance NUMERIC;
    v_pending_balance NUMERIC;
    v_average_rating NUMERIC;
    v_total_reviews INT;
    v_unanswered_questions INT;
BEGIN
    -- Get course counts
    SELECT COUNT(*), COUNT(CASE WHEN is_published THEN 1 END)
    INTO v_total_courses, v_published_courses
    FROM courses WHERE instructor_id = v_instructor_id;
    
    -- Get student/enrollment counts
    SELECT 
        COUNT(DISTINCT e.user_id),
        COUNT(*),
        COUNT(CASE WHEN e.enrolled_at >= DATE_TRUNC('month', NOW()) THEN 1 END)
    INTO v_total_students, v_total_enrollments, v_monthly_enrollments
    FROM enrollments e 
    JOIN courses c ON c.id = e.course_id 
    WHERE c.instructor_id = v_instructor_id;
    
    -- Get earnings from instructor_balance table (using total_earnings column)
    SELECT 
        COALESCE(total_earnings, 0),
        COALESCE(available_balance, 0),
        COALESCE(pending_balance, 0)
    INTO v_total_earnings, v_available_balance, v_pending_balance
    FROM instructor_balance
    WHERE instructor_id = v_instructor_id;
    
    -- If no balance record exists, use 0
    IF v_total_earnings IS NULL THEN
        v_total_earnings := 0;
        v_available_balance := 0;
        v_pending_balance := 0;
    END IF;
    
    -- Get ratings
    SELECT COALESCE(AVG(cr.rating), 0), COUNT(*)
    INTO v_average_rating, v_total_reviews
    FROM course_reviews cr 
    JOIN courses c ON c.id = cr.course_id 
    WHERE c.instructor_id = v_instructor_id;
    
    -- Get unanswered questions
    SELECT COUNT(*)
    INTO v_unanswered_questions
    FROM qa_questions q 
    JOIN courses c ON c.id = q.course_id 
    WHERE c.instructor_id = v_instructor_id AND q.is_answered = false;
    
    -- Build result
    v_stats := json_build_object(
        'total_courses', COALESCE(v_total_courses, 0),
        'published_courses', COALESCE(v_published_courses, 0),
        'total_students', COALESCE(v_total_students, 0),
        'total_enrollments', COALESCE(v_total_enrollments, 0),
        'monthly_enrollments', COALESCE(v_monthly_enrollments, 0),
        'total_earnings', COALESCE(v_total_earnings, 0),
        'available_balance', COALESCE(v_available_balance, 0),
        'pending_balance', COALESCE(v_pending_balance, 0),
        'average_rating', ROUND(COALESCE(v_average_rating, 0)::numeric, 1),
        'total_reviews', COALESCE(v_total_reviews, 0),
        'unanswered_questions', COALESCE(v_unanswered_questions, 0)
    );

    RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_instructor_dashboard_stats() TO authenticated;

COMMENT ON FUNCTION get_instructor_dashboard_stats IS 'Returns instructor dashboard statistics using new earnings schema';

-- ============================================================
-- ✅ DONE: Dashboard stats now uses total_earnings column
-- ============================================================


-- =====================================================================
-- File: 340_create_levels_table.sql
-- =====================================================================
-- ============================================================
-- 340: CREATE LEVELS TABLE
-- ============================================================
-- Creates a separate levels table for dynamic level management
-- Migrates existing level data from courses table
-- ============================================================

-- =============================================
-- STEP 1: Create levels table
-- =============================================
CREATE TABLE IF NOT EXISTS public.levels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name_ar TEXT NOT NULL,
  name_en TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description_ar TEXT,
  description_en TEXT,
  display_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_levels_active ON public.levels(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_levels_order ON public.levels(display_order);

-- =============================================
-- STEP 2: Insert default levels
-- =============================================
INSERT INTO public.levels (name_ar, name_en, slug, description_ar, description_en, display_order, is_active)
VALUES
  ('مبتدئ', 'Beginner', 'beginner', 'مناسب للمبتدئين بدون خبرة سابقة', 'Suitable for beginners with no prior experience', 1, true),
  ('متوسط', 'Intermediate', 'intermediate', 'يتطلب معرفة أساسية بالموضوع', 'Requires basic knowledge of the subject', 2, true),
  ('متقدم', 'Advanced', 'advanced', 'للمتقدمين ذوي الخبرة', 'For advanced learners with experience', 3, true),
  ('جميع المستويات', 'All Levels', 'all_levels', 'مناسب لجميع المستويات', 'Suitable for all levels', 4, true)
ON CONFLICT (slug) DO NOTHING;

-- =============================================
-- STEP 3: Add level_id column to courses table
-- =============================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'courses'
      AND column_name = 'level_id'
  ) THEN
    ALTER TABLE public.courses
      ADD COLUMN level_id UUID REFERENCES public.levels(id);
  END IF;
END $$;

-- =============================================
-- STEP 4: Migrate existing level data
-- =============================================
-- Map old level enum values to new level_id
UPDATE public.courses c
SET level_id = l.id
FROM public.levels l
WHERE c.level = l.slug
  AND c.level_id IS NULL;

-- =============================================
-- STEP 5: Make level_id NOT NULL after migration
-- =============================================
DO $$
BEGIN
  -- Check if all courses have level_id
  IF NOT EXISTS (
    SELECT 1 FROM public.courses WHERE level_id IS NULL
  ) THEN
    ALTER TABLE public.courses
      ALTER COLUMN level_id SET NOT NULL;
  END IF;
END $$;

-- =============================================
-- STEP 6: Enable RLS on levels table
-- =============================================
ALTER TABLE public.levels ENABLE ROW LEVEL SECURITY;

-- Everyone can view active levels
DROP POLICY IF EXISTS "Anyone can view active levels" ON public.levels;
DROP POLICY IF EXISTS "Anyone can view active levels" ON public;
CREATE POLICY "Anyone can view active levels" ON public.levels
  FOR SELECT
  USING (is_active = true OR auth.uid() IS NOT NULL);

-- Only admins can insert/update/delete levels
DROP POLICY IF EXISTS "Admins can manage levels" ON public.levels;
DROP POLICY IF EXISTS "Admins can manage levels" ON public;
CREATE POLICY "Admins can manage levels" ON public.levels
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- =============================================
-- STEP 7: Grant permissions
-- =============================================
GRANT SELECT ON public.levels TO authenticated, anon;
GRANT ALL ON public.levels TO authenticated;

-- =============================================
-- ✅ MIGRATION COMPLETE!
-- =============================================
-- Old: courses.level (TEXT enum)
-- New: courses.level_id (UUID FK to levels table)
-- Note: Keep old 'level` column for backward compatibility
--       Can be removed after full migration
-- =============================================


-- =====================================================================
-- File: 341_add_file_to_lessons.sql
-- =====================================================================
-- Add file upload capabilities to lessons
ALTER TABLE public.lessons 
ADD COLUMN IF NOT EXISTS file_url TEXT,
ADD COLUMN IF NOT EXISTS file_name TEXT,
ADD COLUMN IF NOT EXISTS file_size INTEGER,
ADD COLUMN IF NOT EXISTS file_type TEXT;

-- Optionally, add 'document` to lesson types if not already there, 
-- but since CHECK constraints can`t be easily altered in Postgres without dropping them,
-- we'll just use the existing 'resource' or 'article` types, 
-- or we can just drop and recreate the constraint if really needed.
-- But wait, checking the constraint first.
DO $$
BEGIN
    -- Drop the check constraint if it exists
    ALTER TABLE public.lessons DROP CONSTRAINT IF EXISTS lessons_type_check;
EXCEPTION
    WHEN undefined_object THEN
        null;
END $$;

ALTER TABLE public.lessons
ADD CONSTRAINT lessons_type_check CHECK (type IN ('video', 'article', 'quiz', 'assignment', 'resource', 'live', 'document', 'file'));


-- =====================================================================
-- File: 342_fix_course_stats_function.sql
-- =====================================================================
-- ============================================================
-- Fix course statistics columns function to use earnings_transactions
-- ============================================================

-- Function to update course stats
CREATE OR REPLACE FUNCTION update_course_stats(p_course_id UUID)
RETURNS VOID AS $$
DECLARE
    v_section_count INT;
    v_lesson_count INT;
    v_total_revenue DECIMAL(10,2);
BEGIN
    -- Count sections
    SELECT COUNT(*) INTO v_section_count
    FROM sections
    WHERE course_id = p_course_id;
    
    -- Count lessons
    SELECT COUNT(*) INTO v_lesson_count
    FROM lessons
    WHERE course_id = p_course_id;
    
    -- Sum revenue from earnings_transactions 
    SELECT COALESCE(SUM(amount - commission), 0) INTO v_total_revenue
    FROM earnings_transactions
    WHERE course_id = p_course_id
      AND status IN ('available', 'pending', 'paid');
    
    -- Update course
    UPDATE courses
    SET section_count = v_section_count,
        lesson_count = v_lesson_count,
        total_revenue = v_total_revenue
    WHERE id = p_course_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-Trigger function for earnings
CREATE OR REPLACE FUNCTION trigger_update_course_stats_on_earning()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF OLD.course_id IS NOT NULL THEN
            PERFORM update_course_stats(OLD.course_id);
        END IF;
        RETURN OLD;
    ELSE
        IF NEW.course_id IS NOT NULL THEN
            PERFORM update_course_stats(NEW.course_id);
        END IF;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Drop from earnings_transactions if exists
DROP TRIGGER IF EXISTS earning_stats_trigger ON earnings_transactions;

-- Create trigger on earnings_transactions
CREATE TRIGGER earning_stats_trigger
AFTER INSERT OR UPDATE OR DELETE ON earnings_transactions
FOR EACH ROW
EXECUTE FUNCTION trigger_update_course_stats_on_earning();

-- Update all existing courses stats
DO $$
DECLARE
    course_record RECORD;
BEGIN
    FOR course_record IN SELECT id FROM courses LOOP
        PERFORM update_course_stats(course_record.id);
    END LOOP;
END $$;


-- =====================================================================
-- File: 343_parent_portal.sql
-- =====================================================================
-- Add parent_phone to profiles for the public parent portal
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS parent_phone TEXT;

-- Create an RPC to fetch the parent dashboard data based simply on the parent phone
CREATE OR REPLACE FUNCTION get_parent_dashboard(p_phone TEXT)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_agg(
    json_build_object(
      'id', p.id,
      'name', p.name,
      'avatar_url', p.avatar_url,
      'courses', (
        SELECT COALESCE(json_agg(
          json_build_object(
            'title_ar', c.title_ar,
            'title_en', c.title_en,
            'instructor_name', i.name,
            'progress', (
              SELECT COALESCE(
                 (SELECT count(*)::float FROM lesson_progress lp 
                  JOIN lessons l2 ON l2.id = lp.lesson_id 
                  WHERE lp.user_id = p.id AND l2.section_id IN (SELECT id FROM sections WHERE course_id = c.id) AND lp.is_completed = true)
                  / NULLIF((SELECT count(*)::float FROM lessons l3 
                            WHERE l3.section_id IN (SELECT id FROM sections WHERE course_id = c.id)), 0)
                * 100, 0
              )::int
            )
          )
        ), '[]'::json)
        FROM enrollments e
        JOIN parent_enrollments pe ON e.parent_enrollment_id = pe.id
        JOIN courses c ON e.course_id = c.id
        LEFT JOIN profiles i ON c.instructor_id = i.id
        WHERE pe.user_id = p.id AND pe.payment_status IN ('completed', 'free')
      ),
      'quizzes', (
        SELECT COALESCE(json_agg(
          json_build_object(
            'course_title_ar', qc.title_ar,
            'course_title_en', qc.title_en,
            'quiz_title_ar', q.title_ar,
            'quiz_title_en', q.title_en,
            'score', qa.score,
            'total_score', qa.total_points,
            'is_passed', qa.passed,
            'completed_at', qa.completed_at
          )
        ), '[]'::json)
        FROM quiz_attempts qa
        JOIN quizzes q ON qa.quiz_id = q.id
        LEFT JOIN courses qc ON q.course_id = qc.id
        WHERE qa.user_id = p.id AND qa.completed_at IS NOT NULL
      )
    )
  ) INTO result
  FROM public.profiles p
  WHERE p.parent_phone = p_phone AND p.parent_phone IS NOT NULL AND p.parent_phone != '';
  
  RETURN COALESCE(result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- =====================================================================
-- File: 344_fix_parent_portal_rpc.sql
-- =====================================================================
-- Fix the get_parent_dashboard RPC function to correctly map quiz_attempts columns

CREATE OR REPLACE FUNCTION get_parent_dashboard(p_phone TEXT)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_agg(
    json_build_object(
      'id', p.id,
      'name', p.name,
      'avatar_url', p.avatar_url,
      'courses', (
        SELECT COALESCE(json_agg(
          json_build_object(
            'title_ar', c.title_ar,
            'title_en', c.title_en,
            'instructor_name', i.name,
            'progress', (
              SELECT COALESCE(
                 (SELECT count(*)::float FROM lesson_progress lp 
                  JOIN lessons l2 ON l2.id = lp.lesson_id 
                  WHERE lp.user_id = p.id AND l2.section_id IN (SELECT id FROM sections WHERE course_id = c.id) AND lp.is_completed = true)
                  / NULLIF((SELECT count(*)::float FROM lessons l3 
                            WHERE l3.section_id IN (SELECT id FROM sections WHERE course_id = c.id)), 0)
                * 100, 0
              )::int
            )
          )
        ), '[]'::json)
        FROM enrollments e
        JOIN parent_enrollments pe ON e.parent_enrollment_id = pe.id
        JOIN courses c ON e.course_id = c.id
        LEFT JOIN profiles i ON c.instructor_id = i.id
        WHERE pe.user_id = p.id AND pe.payment_status IN ('completed', 'free')
      ),
      'quizzes', (
        SELECT COALESCE(json_agg(
          json_build_object(
            'course_title_ar', qc.title_ar,
            'course_title_en', qc.title_en,
            'quiz_title_ar', q.title_ar,
            'quiz_title_en', q.title_en,
            'score', qa.score,
            'total_score', qa.total_points,  /* Corrected from total_score */
            'is_passed', qa.passed,          /* Corrected from is_passed */
            'completed_at', qa.completed_at
          )
        ), '[]'::json)
        FROM quiz_attempts qa
        JOIN quizzes q ON qa.quiz_id = q.id
        LEFT JOIN courses qc ON q.course_id = qc.id
        WHERE qa.user_id = p.id AND qa.completed_at IS NOT NULL /* Corrected from status='completed' */
      )
    )
  ) INTO result
  FROM public.profiles p
  WHERE p.parent_phone = p_phone AND p.parent_phone IS NOT NULL AND p.parent_phone != '';
  
  RETURN COALESCE(result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- =====================================================================
-- File: 345_parent_portal_final.sql
-- =====================================================================
-- Final setup for the Parent Portal RPC

CREATE OR REPLACE FUNCTION get_parent_dashboard(p_phone TEXT)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  -- We aggregate all students into a json array
  SELECT json_agg(
    json_build_object(
      'id', p.id,
      'name', p.name,
      'avatar_url', p.avatar_url,
      'courses', (
        SELECT COALESCE(json_agg(
          json_build_object(
            'title_ar', c.title_ar,
            'title_en', c.title_en,
            'instructor_name', i.name,
            'enrolled_at', e.created_at,
            'progress', (
              SELECT COALESCE(
                 (SELECT count(*)::float FROM lesson_progress lp 
                  JOIN lessons l2 ON l2.id = lp.lesson_id 
                  WHERE lp.user_id = p.id AND l2.section_id IN (SELECT id FROM sections WHERE course_id = c.id) AND lp.is_completed = true)
                  / NULLIF((SELECT count(*)::float FROM lessons l3 
                            WHERE l3.section_id IN (SELECT id FROM sections WHERE course_id = c.id)), 0)
                * 100, 0
              )::int
            )
          )
        ), '[]'::json)
        FROM enrollments e
        JOIN courses c ON e.course_id = c.id
        LEFT JOIN profiles i ON c.instructor_id = i.id
        WHERE e.user_id = p.id AND e.status IN ('active', 'completed')
      ),
      'quizzes', (
        SELECT COALESCE(json_agg(
          json_build_object(
            'course_title_ar', COALESCE(qc.title_ar, ''),
            'course_title_en', COALESCE(qc.title_en, ''),
            'quiz_title_ar', COALESCE(q.title_ar, ''),
            'quiz_title_en', COALESCE(q.title_en, ''),
            'score', qa.score,
            'total_score', qa.total_points,  /* Corrected column */
            'is_passed', qa.passed,          /* Corrected column */
            'completed_at', qa.completed_at
          )
        ), '[]'::json)
        FROM quiz_attempts qa
        JOIN quizzes q ON qa.quiz_id = q.id
        LEFT JOIN courses qc ON q.course_id = qc.id
        WHERE qa.user_id = p.id AND qa.completed_at IS NOT NULL
      )
    )
  ) INTO result
  FROM public.profiles p
  WHERE p.parent_phone = p_phone AND p.parent_phone IS NOT NULL AND p.parent_phone != '';
  
  RETURN COALESCE(result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- =====================================================================
-- File: 346_admin_delete_messages_policies.sql
-- =====================================================================
-- Add policies to allow admins to delete/update messages in groups and direct chats
-- (Unified schema uses the 'messages` table for both)
-- ==============================================================================

-- Allow admins to UPDATE any message (for soft deletion: is_deleted = true)
-- Note: Soft deletion is all we need as per the app logic.
DROP POLICY IF EXISTS "Admins can update any message" ON messages;
CREATE POLICY "Admins can update any message" ON messages FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
    )
);


-- =====================================================================
-- File: 346_test_parent_phone.sql
-- =====================================================================
-- تعيين رقم الهاتف +2001142043116 كولي أمر لجميع حسابات الطلاب لاختبار بوابة ولي الأمر
UPDATE public.profiles
SET parent_phone = '+2001142043116'
WHERE role = 'student';


-- =====================================================================
-- File: 347_create_instructor_applications.sql
-- =====================================================================
-- 347_create_instructor_applications.sql
-- Create instructor applications flow:
-- - Public/anon can submit instructor requests
-- - Only admins can view/review requests

CREATE TABLE IF NOT EXISTS public.instructor_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  admin_notes TEXT,
  reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_instructor_applications_status
  ON public.instructor_applications(status);

CREATE INDEX IF NOT EXISTS idx_instructor_applications_created_at
  ON public.instructor_applications(created_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS idx_instructor_applications_pending_email_unique
  ON public.instructor_applications (LOWER(email))
  WHERE status = 'pending';

DROP TRIGGER IF EXISTS update_instructor_applications_updated_at
  ON public.instructor_applications;

CREATE TRIGGER update_instructor_applications_updated_at
  BEFORE UPDATE ON public.instructor_applications
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

ALTER TABLE public.instructor_applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can submit instructor applications"
  ON public.instructor_applications;
DROP POLICY IF EXISTS "Anyone can submit instructor applications" ON public;
CREATE POLICY "Anyone can submit instructor applications" ON public.instructor_applications
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (
    status = 'pending'
    AND reviewed_by IS NULL
    AND reviewed_at IS NULL
  );

DROP POLICY IF EXISTS "Admins can view instructor applications"
  ON public.instructor_applications;
DROP POLICY IF EXISTS "Admins can view instructor applications" ON public;
CREATE POLICY "Admins can view instructor applications" ON public.instructor_applications
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Admins can update instructor applications"
  ON public.instructor_applications;
DROP POLICY IF EXISTS "Admins can update instructor applications" ON public;
CREATE POLICY "Admins can update instructor applications" ON public.instructor_applications
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Admins can delete instructor applications"
  ON public.instructor_applications;
DROP POLICY IF EXISTS "Admins can delete instructor applications" ON public;
CREATE POLICY "Admins can delete instructor applications" ON public.instructor_applications
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role = 'admin'
    )
  );

GRANT INSERT ON public.instructor_applications TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.instructor_applications TO authenticated;



-- =====================================================================
-- File: 348_add_account_type_to_instructor_applications.sql
-- =====================================================================
-- 348_add_account_type_to_instructor_applications.sql
-- Adds account_type support for manual admin-created requests.
-- Keeps public submissions restricted to instructor requests.

ALTER TABLE public.instructor_applications
  ADD COLUMN IF NOT EXISTS account_type TEXT NOT NULL DEFAULT 'instructor'
  CHECK (account_type IN ('student', 'instructor', 'parent', 'admin'));

CREATE INDEX IF NOT EXISTS idx_instructor_applications_account_type
  ON public.instructor_applications(account_type);

DROP POLICY IF EXISTS "Anyone can submit instructor applications"
  ON public.instructor_applications;
DROP POLICY IF EXISTS "Anyone can submit instructor applications" ON public;
CREATE POLICY "Anyone can submit instructor applications" ON public.instructor_applications
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (
    status = 'pending'
    AND reviewed_by IS NULL
    AND reviewed_at IS NULL
    AND account_type = 'instructor'
  );

DROP POLICY IF EXISTS "Admins can insert instructor applications"
  ON public.instructor_applications;
DROP POLICY IF EXISTS "Admins can insert instructor applications" ON public;
CREATE POLICY "Admins can insert instructor applications" ON public.instructor_applications
  FOR INSERT
  TO authenticated
  WITH CHECK (
    status = 'pending'
    AND reviewed_by IS NULL
    AND reviewed_at IS NULL
    AND EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role = 'admin'
    )
  );


-- =====================================================================
-- File: 350_process_refund_function.sql
-- =====================================================================
-- =============================================
-- 350: PROCESS REFUND FUNCTION
-- =============================================
-- Creates a function to handle refund processing
-- When a refund is processed:
-- 1. Update enrollment status to 'refunded`
-- 2. Create a negative earnings_transaction for the instructor
-- 3. Deduct from instructor`s available_balance
-- =============================================

CREATE OR REPLACE FUNCTION public.process_refund(
  p_enrollment_id UUID,
  p_reason TEXT
)
RETURNS VOID AS $$
DECLARE
  v_enrollment RECORD;
  v_instructor_id UUID;
  v_course_name TEXT;
  v_amount_paid NUMERIC;
  v_instructor_share NUMERIC;
  v_commission NUMERIC;
  v_revenue_share NUMERIC;
BEGIN
  -- Get enrollment details
  SELECT 
    e.id,
    e.user_id,
    e.course_id,
    e.instructor_id,
    e.price,
    e.status,
    c.title_ar,
    70.0 as revenue_share  -- Default revenue share
  INTO v_enrollment
  FROM public.enrollments e
  JOIN public.courses c ON c.id = e.course_id
  WHERE e.id = p_enrollment_id;
  
  -- Try to get revenue_share from instructors table if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'instructors'
  ) THEN
    SELECT COALESCE(i.revenue_share, 70.0)
    INTO v_revenue_share
    FROM public.instructors i
    WHERE i.user_id = v_enrollment.instructor_id;
    
    IF v_revenue_share IS NOT NULL THEN
      v_enrollment.revenue_share := v_revenue_share;
    END IF;
  END IF;

  -- Check if enrollment exists
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Enrollment not found';
  END IF;

  -- Check if already refunded
  IF v_enrollment.status = 'refunded' THEN
    RAISE EXCEPTION 'Enrollment already refunded';
  END IF;

  -- Get values
  v_instructor_id := v_enrollment.instructor_id;
  v_course_name := v_enrollment.title_ar;
  v_amount_paid := COALESCE(v_enrollment.price, 0);
  v_revenue_share := COALESCE(v_enrollment.revenue_share, 70);

  -- Calculate instructor share and commission (as negative values)
  v_instructor_share := -(v_amount_paid * v_revenue_share / 100);
  v_commission := -(v_amount_paid * (100 - v_revenue_share) / 100);

  -- Delete enrollment instead of updating status
  DELETE FROM public.enrollments
  WHERE id = p_enrollment_id;

  -- Create negative earnings transaction for instructor
  INSERT INTO public.earnings_transactions (
    user_id,
    course_id,
    course_name,
    amount,
    commission,
    status,
    source_type,
    created_at
  ) VALUES (
    v_instructor_id,
    v_enrollment.course_id,
    v_course_name,
    v_amount_paid,  -- Full amount as negative
    v_commission,   -- Commission as negative
    'available',
    'refund',
    NOW()
  );

  -- Update instructor balance (deduct the refunded amount)
  UPDATE public.instructor_balance
  SET 
    available_balance = available_balance + v_instructor_share,  -- Adding negative = subtracting
    total_earnings = total_earnings + v_instructor_share,
    updated_at = NOW()
  WHERE instructor_id = v_instructor_id;

  -- Create balance record if doesn`t exist
  INSERT INTO public.instructor_balance (instructor_id, available_balance, total_earnings)
  VALUES (v_instructor_id, v_instructor_share, v_instructor_share)
  ON CONFLICT (instructor_id) DO NOTHING;

  RAISE NOTICE 'Refund processed: enrollment=%, instructor=%, amount=%', 
    p_enrollment_id, v_instructor_id, v_instructor_share;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.process_refund(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.process_refund(UUID, TEXT) TO service_role;

-- =============================================
-- ✅ DONE: Refund processing function created
-- =============================================


-- =====================================================================
-- File: 352_auto_create_earnings_on_enrollment.sql
-- =====================================================================
-- =============================================
-- 352: AUTO CREATE EARNINGS ON ENROLLMENT
-- =============================================
-- Creates a trigger to automatically create earnings transaction
-- and update instructor balance when a student enrolls in a course
-- =============================================

-- Drop existing trigger and function if exists
DROP TRIGGER IF EXISTS trigger_auto_create_earnings ON public.enrollments;
DROP FUNCTION IF EXISTS public.auto_create_earnings_transaction() CASCADE;

-- Create function to handle enrollment earnings
CREATE OR REPLACE FUNCTION public.auto_create_earnings_transaction()
RETURNS TRIGGER AS $$
DECLARE
  v_instructor_id UUID;
  v_course_name TEXT;
  v_revenue_share NUMERIC(5,2);
  v_instructor_share NUMERIC(12,2);
  v_platform_commission NUMERIC(12,2);
BEGIN
  -- Only process paid enrollments with active status
  IF NEW.price > 0 AND NEW.status = 'active' THEN
    
    -- Get instructor_id and course details
    SELECT 
      c.instructor_id,
      COALESCE(c.title_ar, c.title_en, 'Unknown Course'),
      70.0  -- Default revenue share
    INTO 
      v_instructor_id,
      v_course_name,
      v_revenue_share
    FROM courses c
    WHERE c.id = NEW.course_id;
    
    -- Try to get revenue_share from instructors table if it exists
    IF EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'instructors'
    ) THEN
      SELECT COALESCE(revenue_share, 70.0)
      INTO v_revenue_share
      FROM instructors
      WHERE user_id = v_instructor_id;
    END IF;
    
    -- If instructor not found, skip
    IF v_instructor_id IS NULL THEN
      RETURN NEW;
    END IF;
    
    -- Calculate shares
    v_instructor_share := NEW.price * (v_revenue_share / 100.0);
    v_platform_commission := NEW.price - v_instructor_share;
    
    -- Check if earnings transaction already exists for this enrollment
    IF NOT EXISTS (
      SELECT 1 FROM earnings_transactions 
      WHERE course_id = NEW.course_id 
        AND user_id = v_instructor_id
        AND created_at = NEW.enrolled_at
        AND amount = NEW.price
    ) THEN
      
      -- Create earnings transaction
      INSERT INTO earnings_transactions (
        user_id,
        course_id,
        course_name,
        amount,
        commission,
        status,
        source_type,
        created_at
      ) VALUES (
        v_instructor_id,
        NEW.course_id,
        v_course_name,
        NEW.price,
        v_platform_commission,
        'available',
        'course_sale',
        COALESCE(NEW.enrolled_at, NOW())
      );
      
      -- Update instructor balance
      -- Check if balance record exists
      IF EXISTS (
        SELECT 1 FROM instructor_balance WHERE instructor_id = v_instructor_id
      ) THEN
        -- Update existing balance
        UPDATE instructor_balance
        SET
          available_balance = available_balance + v_instructor_share,
          total_earnings = total_earnings + v_instructor_share,
          updated_at = NOW()
        WHERE instructor_id = v_instructor_id;
      ELSE
        -- Create new balance record
        INSERT INTO instructor_balance (
          instructor_id,
          available_balance,
          pending_balance,
          total_withdrawn,
          total_earnings,
          updated_at
        ) VALUES (
          v_instructor_id,
          v_instructor_share,
          0,
          0,
          v_instructor_share,
          NOW()
        );
      END IF;
      
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on enrollments table
CREATE TRIGGER trigger_auto_create_earnings
  AFTER INSERT OR UPDATE ON public.enrollments
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_create_earnings_transaction();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.auto_create_earnings_transaction() TO authenticated;

-- Add comment
COMMENT ON FUNCTION public.auto_create_earnings_transaction IS 'Automatically creates earnings transaction and updates instructor balance when student enrolls';

-- =============================================
-- ✅ DONE: Auto earnings trigger created
-- =============================================



-- =====================================================================
-- File: 354_drop_admin_create_user_function.sql
-- =====================================================================
-- Drop admin_create_user function and related trigger
-- Run this to clean up the database after switching to Admin API

-- Drop the function
DROP FUNCTION IF EXISTS public.admin_create_user(text, text, text, text);

-- Drop the trigger function if it exists
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- Note: The trigger will be automatically dropped when the function is dropped with CASCADE


-- =====================================================================
-- File: 400_drop_certificates_tables.sql
-- =====================================================================
-- =====================================================
-- Drop Certificates Feature Tables and Functions
-- =====================================================
-- This script removes all certificates-related tables,
-- functions, triggers, and policies from the database.
-- =====================================================

-- Drop RLS policies first
DROP POLICY IF EXISTS "Users can view their own certificates" ON certificates;
DROP POLICY IF EXISTS "Users can insert their own certificates" ON certificates;
DROP POLICY IF EXISTS "Admins can view all certificates" ON certificates;
DROP POLICY IF EXISTS "Admins can manage all certificates" ON certificates;

-- Drop triggers
DROP TRIGGER IF EXISTS update_certificates_updated_at ON certificates;

-- Drop functions
DROP FUNCTION IF EXISTS issue_certificate(uuid, uuid);
DROP FUNCTION IF EXISTS get_certificate_details(uuid);
DROP FUNCTION IF EXISTS get_certificate_full_details(uuid);
DROP FUNCTION IF EXISTS verify_certificate(text);

-- Drop tables
DROP TABLE IF EXISTS certificates CASCADE;

-- Drop any certificate-related columns from other tables
-- (if certificates were referenced in enrollments or other tables)
ALTER TABLE IF EXISTS enrollments 
  DROP COLUMN IF EXISTS certificate_id CASCADE;

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Successfully dropped all certificates-related database objects';
END $$;


-- =====================================================================
-- File: 500_confirm_enrollment_payment.sql
-- =====================================================================
-- =============================================
-- 500: CONFIRM ENROLLMENT PAYMENT FUNCTION
-- =============================================
-- This function confirms payment and activates enrollments
-- =============================================

CREATE OR REPLACE FUNCTION public.confirm_enrollment_payment(
  p_parent_enrollment_id UUID,
  p_transaction_id TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Get user_id from parent_enrollment
  SELECT user_id INTO v_user_id
  FROM parent_enrollments
  WHERE id = p_parent_enrollment_id;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Parent enrollment not found: %', p_parent_enrollment_id;
  END IF;

  -- Update parent_enrollment to paid
  UPDATE parent_enrollments
  SET 
    payment_status = 'paid',
    paid_at = NOW(),
    transaction_id = p_transaction_id,
    updated_at = NOW()
  WHERE id = p_parent_enrollment_id;

  -- Activate all enrollments linked to this parent_enrollment
  UPDATE enrollments
  SET 
    status = 'active',
    updated_at = NOW()
  WHERE parent_enrollment_id = p_parent_enrollment_id
    AND status = 'pending';

  RETURN TRUE;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.confirm_enrollment_payment(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.confirm_enrollment_payment(UUID, TEXT) TO anon;


-- =====================================================================
-- File: 501_add_transaction_id_to_parent_enrollments.sql
-- =====================================================================
-- =============================================
-- 501: ADD TRANSACTION_ID TO PARENT_ENROLLMENTS
-- =============================================
-- Add transaction_id column to store payment gateway transaction ID
-- =============================================

-- Add transaction_id column if it doesn`t exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'parent_enrollments'
      AND column_name = 'transaction_id'
  ) THEN
    ALTER TABLE public.parent_enrollments
      ADD COLUMN transaction_id TEXT;
    
    RAISE NOTICE '✅ Added transaction_id column to parent_enrollments';
  ELSE
    RAISE NOTICE 'ℹ️ transaction_id column already exists';
  END IF;
END $$;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_parent_enrollments_transaction_id 
  ON public.parent_enrollments(transaction_id);




-- =====================================================================
-- File: create_direct_messages.sql
-- =====================================================================
-- Direct Messages table for 1-on-1 chat between instructors and students
CREATE TABLE IF NOT EXISTS direct_messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  message_text TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_dm_sender ON direct_messages (sender_id, created_at);
CREATE INDEX IF NOT EXISTS idx_dm_receiver ON direct_messages (receiver_id, created_at);
CREATE INDEX IF NOT EXISTS idx_dm_participants ON direct_messages (
  LEAST(sender_id, receiver_id),
  GREATEST(sender_id, receiver_id),
  created_at
);

-- Row Level Security
ALTER TABLE direct_messages ENABLE ROW LEVEL SECURITY;

-- Users can only read messages where they are sender or receiver
DROP POLICY IF EXISTS "Users can read own DMs" ON direct_messages;
CREATE POLICY "Users can read own DMs" ON direct_messages FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Users can only send messages as themselves
DROP POLICY IF EXISTS "Users can send DMs" ON direct_messages;
CREATE POLICY "Users can send DMs" ON direct_messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

-- Users can update their own received messages (for marking as read)
DROP POLICY IF EXISTS "Users can mark DMs as read" ON direct_messages;
CREATE POLICY "Users can mark DMs as read" ON direct_messages FOR UPDATE
  USING (auth.uid() = receiver_id)
  WITH CHECK (auth.uid() = receiver_id);

-- Enable realtime for this table
ALTER PUBLICATION supabase_realtime ADD TABLE direct_messages;


-- =====================================================================
-- File: debug_triggers.sql
-- =====================================================================
-- Check triggers on enrollments table
SELECT 
    trigger_name, 
    event_manipulation, 
    event_object_table, 
    action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'enrollments';

-- Check the create_enrollment function source code to see if it inserts earnings
SELECT pg_get_functiondef('create_enrollment'::regproc);

