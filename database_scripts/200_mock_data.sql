-- ============================================================
-- 🎓 LMS Mock Data - بيانات تجريبية للتطوير
-- Version: 1.0 | January 2026
-- ============================================================

-- ============================================================
-- 1. BANNERS TABLE (Create if not exists)
-- ============================================================
CREATE TABLE IF NOT EXISTS banners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title_ar TEXT,
  title_en TEXT,
  subtitle_ar TEXT,
  subtitle_en TEXT,
  image_url TEXT NOT NULL,
  link_type TEXT DEFAULT 'none' CHECK (link_type IN ('none', 'course', 'category', 'url', 'instructor')),
  link_value TEXT,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  clicks_count INTEGER DEFAULT 0,
  views_count INTEGER DEFAULT 0,
  target_audience TEXT DEFAULT 'all',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_banners_active ON banners(is_active, sort_order);

-- ============================================================
-- 2. INSERT CATEGORIES
-- ============================================================
INSERT INTO categories (id, name_ar, name_en, description_ar, description_en, icon_name, image_url, sort_order, is_active, courses_count) VALUES
('c1000000-0000-4000-a000-000000000001', 'البرمجة والتطوير', 'Development', 'تعلم البرمجة وتطوير التطبيقات', 'Learn programming and app development', 'code', 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=400', 1, true, 45),
('c1000000-0000-4000-a000-000000000002', 'التصميم', 'Design', 'تصميم الجرافيك وواجهات المستخدم', 'Graphic design and UI/UX', 'palette', 'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=400', 2, true, 32),
('c1000000-0000-4000-a000-000000000003', 'الأعمال', 'Business', 'إدارة الأعمال والتسويق', 'Business management and marketing', 'business', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400', 3, true, 28),
('c1000000-0000-4000-a000-000000000004', 'التسويق الرقمي', 'Marketing', 'التسويق الإلكتروني والسوشيال ميديا', 'Digital marketing and social media', 'campaign', 'https://images.unsplash.com/photo-1533750349088-cd871a92f312?w=400', 4, true, 24),
('c1000000-0000-4000-a000-000000000005', 'المالية', 'Finance', 'المحاسبة والتحليل المالي', 'Accounting and financial analysis', 'account_balance', 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=400', 5, true, 18),
('c1000000-0000-4000-a000-000000000006', 'الذكاء الاصطناعي', 'AI & ML', 'تعلم الآلة والذكاء الاصطناعي', 'Machine learning and artificial intelligence', 'psychology', 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=400', 6, true, 15)
ON CONFLICT (id) DO UPDATE SET
  name_ar = EXCLUDED.name_ar,
  name_en = EXCLUDED.name_en,
  courses_count = EXCLUDED.courses_count;

-- ============================================================
-- 3. INSERT BANNERS
-- ============================================================
INSERT INTO banners (id, title_ar, title_en, subtitle_ar, subtitle_en, image_url, link_type, sort_order, is_active) VALUES
('b1000000-0000-4000-a000-000000000001', 'أطلق إمكانياتك', 'Unlock Your Potential', 'دورات تبدأ من 9.99$ فقط - ينتهي الليلة!', 'Courses starting from just $9.99. Ends tonight!', 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800&h=400&fit=crop', 'none', 1, true),
('b1000000-0000-4000-a000-000000000002', 'تعلم البرمجة من الصفر', 'Learn Programming from Scratch', 'ابدأ رحلتك في عالم البرمجة اليوم', 'Start your programming journey today', 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=800&h=400&fit=crop', 'category', 2, true),
('b1000000-0000-4000-a000-000000000003', 'مهارات التصميم الاحترافي', 'Professional Design Skills', 'أتقن Figma و Adobe XD', 'Master Figma & Adobe XD', 'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=800&h=400&fit=crop', 'category', 3, true)
ON CONFLICT (id) DO UPDATE SET
  title_ar = EXCLUDED.title_ar,
  title_en = EXCLUDED.title_en,
  image_url = EXCLUDED.image_url;

-- ============================================================
-- 4. GET OR CREATE INSTRUCTOR FROM EXISTING USER
-- ============================================================
DO $$
DECLARE
  v_instructor_id UUID;
BEGIN
  -- Try to get an existing user from profiles
  SELECT id INTO v_instructor_id FROM profiles WHERE role = 'instructor' LIMIT 1;
  
  -- If no instructor exists, get any user
  IF v_instructor_id IS NULL THEN
    SELECT id INTO v_instructor_id FROM profiles LIMIT 1;
  END IF;
  
  -- If still no user, get from auth.users
  IF v_instructor_id IS NULL THEN
    SELECT id INTO v_instructor_id FROM auth.users LIMIT 1;
  END IF;
  
  -- If we found a user, update their profile to be instructor
  IF v_instructor_id IS NOT NULL THEN
    UPDATE profiles SET 
      role = 'instructor',
      name = COALESCE(name, 'أحمد محمد'),
      headline_ar = 'مطور ويب محترف',
      headline_en = 'Professional Web Developer',
      bio_ar = 'مطور ويب بخبرة أكثر من 10 سنوات',
      bio_en = 'Web developer with 10+ years experience',
      expertise = ARRAY['Python', 'JavaScript', 'React', 'Flutter'],
      is_verified_instructor = true
    WHERE id = v_instructor_id;
    
    -- Store instructor_id for courses
    PERFORM set_config('app.instructor_id', v_instructor_id::text, false);
    RAISE NOTICE 'Using instructor ID: %', v_instructor_id;
  ELSE
    RAISE NOTICE 'No users found. Please create a user first via Supabase Auth.';
  END IF;
END $$;


-- ============================================================
-- 5. INSERT COURSES (using first available instructor)
-- ============================================================
INSERT INTO courses (
  id, instructor_id, category_id, title_ar, title_en, subtitle_ar, subtitle_en,
  thumbnail_url, price, discount_price, is_free, level, language,
  total_duration, total_lessons, rating, rating_count, enrolled_count,
  is_published, is_featured, is_flash_sale, flash_sale_price, flash_sale_start, flash_sale_end,
  published_at, requirements, objectives
)
SELECT 
  'cc100000-0000-4000-a000-000000000001'::uuid,
  p.id,
  'c1000000-0000-4000-a000-000000000001'::uuid,
  'دورة Python الشاملة: من الصفر إلى الاحتراف',
  'The Complete Python Bootcamp: From Zero to Hero',
  'تعلم Python 3 بطريقة عملية مع مشاريع حقيقية',
  'Learn Python 3 the practical way with real projects',
  'https://images.unsplash.com/photo-1526379095098-d400fd0bf935?w=400',
  199.99, 12.99, false, 'beginner', 'ar',
  330, 156, 4.6, 12500, 45000,
  true, true, false, null, null, null,
  NOW() - INTERVAL '30 days',
  '["معرفة أساسية بالكمبيوتر"]'::jsonb,
  '["إتقان Python 3 من الصفر"]'::jsonb
FROM profiles p WHERE p.role = 'instructor' OR EXISTS (SELECT 1 FROM profiles) LIMIT 1
ON CONFLICT (id) DO UPDATE SET title_ar = EXCLUDED.title_ar;

INSERT INTO courses (
  id, instructor_id, category_id, title_ar, title_en, subtitle_ar, subtitle_en,
  thumbnail_url, price, discount_price, is_free, level, language,
  total_duration, total_lessons, rating, rating_count, enrolled_count,
  is_published, is_featured, is_flash_sale, flash_sale_price, flash_sale_start, flash_sale_end,
  published_at, requirements, objectives
)
SELECT 
  'cc100000-0000-4000-a000-000000000002'::uuid,
  p.id,
  'c1000000-0000-4000-a000-000000000002'::uuid,
  'احتراف تصميم UI/UX: Figma و Adobe XD',
  'UI/UX Design Masterclass: Adobe XD & Figma',
  'صمم واجهات مستخدم احترافية من الصفر',
  'Design professional user interfaces from scratch',
  'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=400',
  149.99, 14.99, false, 'intermediate', 'ar',
  280, 98, 4.8, 8500, 32000,
  true, true, false, null, null, null,
  NOW() - INTERVAL '45 days',
  '["معرفة أساسية بالتصميم"]'::jsonb,
  '["إتقان Figma و Adobe XD"]'::jsonb
FROM profiles p LIMIT 1
ON CONFLICT (id) DO UPDATE SET title_ar = EXCLUDED.title_ar;

INSERT INTO courses (
  id, instructor_id, category_id, title_ar, title_en, subtitle_ar, subtitle_en,
  thumbnail_url, price, discount_price, is_free, level, language,
  total_duration, total_lessons, rating, rating_count, enrolled_count,
  is_published, is_featured, is_flash_sale, flash_sale_price, flash_sale_start, flash_sale_end,
  published_at, requirements, objectives
)
SELECT 
  'cc100000-0000-4000-a000-000000000003'::uuid,
  p.id,
  'c1000000-0000-4000-a000-000000000005'::uuid,
  'دورة المحلل المالي الشاملة 2026',
  'The Complete Financial Analyst Course 2026',
  'تعلم التحليل المالي والاستثمار',
  'Learn financial analysis and investment',
  'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=400',
  179.99, 11.99, false, 'intermediate', 'ar',
  240, 120, 4.7, 21000, 38000,
  true, false, false, null, null, null,
  NOW() - INTERVAL '60 days',
  '["معرفة أساسية بالرياضيات"]'::jsonb,
  '["فهم القوائم المالية"]'::jsonb
FROM profiles p LIMIT 1
ON CONFLICT (id) DO UPDATE SET title_ar = EXCLUDED.title_ar;

-- Flash Sale Course: React
INSERT INTO courses (
  id, instructor_id, category_id, title_ar, title_en, subtitle_ar, subtitle_en,
  thumbnail_url, price, discount_price, is_free, level, language,
  total_duration, total_lessons, rating, rating_count, enrolled_count,
  is_published, is_featured, is_flash_sale, flash_sale_price, flash_sale_start, flash_sale_end,
  published_at, requirements, objectives
)
SELECT 
  'cc100000-0000-4000-a000-000000000004'::uuid,
  p.id,
  'c1000000-0000-4000-a000-000000000001'::uuid,
  'أنماط React المتقدمة والأداء',
  'Advanced React Patterns & Performance',
  'أتقن React مع أفضل الممارسات',
  'Master React with best practices',
  'https://images.unsplash.com/photo-1633356122544-f134324a6cee?w=400',
  89.99, null, false, 'advanced', 'en',
  180, 85, 4.9, 5200, 18000,
  true, false, true, 19.99, NOW() - INTERVAL '1 day', NOW() + INTERVAL '2 days',
  NOW() - INTERVAL '15 days',
  '["خبرة في JavaScript"]'::jsonb,
  '["React Hooks المتقدمة"]'::jsonb
FROM profiles p LIMIT 1
ON CONFLICT (id) DO UPDATE SET 
  is_flash_sale = true,
  flash_sale_price = 19.99,
  flash_sale_start = NOW() - INTERVAL '1 day',
  flash_sale_end = NOW() + INTERVAL '2 days';


-- New Course: Business Strategy
INSERT INTO courses (
  id, instructor_id, category_id, title_ar, title_en, subtitle_ar, subtitle_en,
  thumbnail_url, price, discount_price, is_free, level, language,
  total_duration, total_lessons, rating, rating_count, enrolled_count,
  is_published, is_featured, is_flash_sale, flash_sale_price, flash_sale_start, flash_sale_end,
  published_at, requirements, objectives
)
SELECT 
  'cc100000-0000-4000-a000-000000000005'::uuid,
  p.id,
  'c1000000-0000-4000-a000-000000000003'::uuid,
  'MBA في صندوق: استراتيجية الأعمال',
  'MBA in a Box: Business Strategy',
  'تعلم استراتيجيات الأعمال من كبار الخبراء',
  'Learn business strategies from top experts',
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
  129.99, 14.99, false, 'intermediate', 'ar',
  200, 75, 4.5, 3200, 12000,
  true, false, false, null, null, null,
  NOW() - INTERVAL '5 days',
  '["لا تحتاج خبرة سابقة"]'::jsonb,
  '["فهم استراتيجيات الأعمال"]'::jsonb
FROM profiles p LIMIT 1
ON CONFLICT (id) DO UPDATE SET title_ar = EXCLUDED.title_ar;

-- New Course: Digital Marketing
INSERT INTO courses (
  id, instructor_id, category_id, title_ar, title_en, subtitle_ar, subtitle_en,
  thumbnail_url, price, discount_price, is_free, level, language,
  total_duration, total_lessons, rating, rating_count, enrolled_count,
  is_published, is_featured, is_flash_sale, flash_sale_price, flash_sale_start, flash_sale_end,
  published_at, requirements, objectives
)
SELECT 
  'cc100000-0000-4000-a000-000000000006'::uuid,
  p.id,
  'c1000000-0000-4000-a000-000000000004'::uuid,
  'احتراف التسويق الرقمي 2026',
  'Digital Marketing Masterclass 2026',
  'تعلم التسويق الإلكتروني من الألف إلى الياء',
  'Learn digital marketing from A to Z',
  'https://images.unsplash.com/photo-1533750349088-cd871a92f312?w=400',
  99.99, 16.99, false, 'beginner', 'ar',
  220, 95, 4.7, 7800, 25000,
  true, false, false, null, null, null,
  NOW() - INTERVAL '3 days',
  '["حساب على السوشيال ميديا"]'::jsonb,
  '["إتقان إعلانات Facebook"]'::jsonb
FROM profiles p LIMIT 1
ON CONFLICT (id) DO UPDATE SET title_ar = EXCLUDED.title_ar;

-- Flash Sale Course: Flutter
INSERT INTO courses (
  id, instructor_id, category_id, title_ar, title_en, subtitle_ar, subtitle_en,
  thumbnail_url, price, discount_price, is_free, level, language,
  total_duration, total_lessons, rating, rating_count, enrolled_count,
  is_published, is_featured, is_flash_sale, flash_sale_price, flash_sale_start, flash_sale_end,
  published_at, requirements, objectives
)
SELECT 
  'cc100000-0000-4000-a000-000000000007'::uuid,
  p.id,
  'c1000000-0000-4000-a000-000000000001'::uuid,
  'تطوير تطبيقات Flutter الشاملة',
  'Complete Flutter App Development',
  'ابنِ تطبيقات iOS و Android بكود واحد',
  'Build iOS & Android apps with one codebase',
  'https://images.unsplash.com/photo-1551650975-87deedd944c3?w=400',
  159.99, null, false, 'intermediate', 'ar',
  350, 180, 4.8, 9500, 28000,
  true, true, true, 24.99, NOW() - INTERVAL '1 day', NOW() + INTERVAL '3 days',
  NOW() - INTERVAL '20 days',
  '["معرفة أساسية بالبرمجة"]'::jsonb,
  '["بناء تطبيقات كاملة"]'::jsonb
FROM profiles p LIMIT 1
ON CONFLICT (id) DO UPDATE SET 
  is_flash_sale = true,
  flash_sale_price = 24.99,
  flash_sale_start = NOW() - INTERVAL '1 day',
  flash_sale_end = NOW() + INTERVAL '3 days';

-- Featured Course: AI & ML
INSERT INTO courses (
  id, instructor_id, category_id, title_ar, title_en, subtitle_ar, subtitle_en,
  thumbnail_url, price, discount_price, is_free, level, language,
  total_duration, total_lessons, rating, rating_count, enrolled_count,
  is_published, is_featured, is_flash_sale, flash_sale_price, flash_sale_start, flash_sale_end,
  published_at, requirements, objectives
)
SELECT 
  'cc100000-0000-4000-a000-000000000008'::uuid,
  p.id,
  'c1000000-0000-4000-a000-000000000006'::uuid,
  'مقدمة في الذكاء الاصطناعي وتعلم الآلة',
  'Introduction to AI & Machine Learning',
  'ابدأ رحلتك في عالم الذكاء الاصطناعي',
  'Start your journey in AI world',
  'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=400',
  199.99, 29.99, false, 'beginner', 'ar',
  280, 110, 4.6, 6200, 22000,
  true, true, false, null, null, null,
  NOW() - INTERVAL '25 days',
  '["Python أساسي"]'::jsonb,
  '["فهم أساسيات ML"]'::jsonb
FROM profiles p LIMIT 1
ON CONFLICT (id) DO UPDATE SET title_ar = EXCLUDED.title_ar;

-- Free Course
INSERT INTO courses (
  id, instructor_id, category_id, title_ar, title_en, subtitle_ar, subtitle_en,
  thumbnail_url, price, discount_price, is_free, level, language,
  total_duration, total_lessons, rating, rating_count, enrolled_count,
  is_published, is_featured, is_flash_sale, flash_sale_price, flash_sale_start, flash_sale_end,
  published_at, requirements, objectives
)
SELECT 
  'cc100000-0000-4000-a000-000000000009'::uuid,
  p.id,
  'c1000000-0000-4000-a000-000000000001'::uuid,
  'أساسيات البرمجة للمبتدئين',
  'Programming Basics for Beginners',
  'دورة مجانية لتعلم أساسيات البرمجة',
  'Free course to learn programming basics',
  'https://images.unsplash.com/photo-1515879218367-8466d910aaa4?w=400',
  0, null, true, 'beginner', 'ar',
  60, 25, 4.4, 15000, 85000,
  true, false, false, null, null, null,
  NOW() - INTERVAL '90 days',
  '["لا تحتاج أي خبرة سابقة"]'::jsonb,
  '["فهم مفاهيم البرمجة"]'::jsonb
FROM profiles p LIMIT 1
ON CONFLICT (id) DO UPDATE SET title_ar = EXCLUDED.title_ar;

-- ============================================================
-- 6. UPDATE CATEGORY COURSE COUNTS
-- ============================================================
UPDATE categories SET courses_count = (
  SELECT COUNT(*) FROM courses 
  WHERE courses.category_id = categories.id AND courses.is_published = true
);

-- ============================================================
-- 7. VERIFY DATA
-- ============================================================
SELECT 'Categories: ' || COUNT(*)::text FROM categories WHERE is_active = true;
SELECT 'Banners: ' || COUNT(*)::text FROM banners WHERE is_active = true;
SELECT 'Courses: ' || COUNT(*)::text FROM courses WHERE is_published = true;
SELECT 'Flash Sale Courses: ' || COUNT(*)::text FROM courses WHERE is_flash_sale = true;

SELECT '✅ Mock data inserted successfully!' as status;
