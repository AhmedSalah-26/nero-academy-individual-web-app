-- ============================================================
-- 🎓 Instructors Mock Data - Complete Script
-- Uses instructor_profiles table (from schema)
-- Version: 1.4 | January 2026
-- ============================================================

-- ============================================================
-- 1. UPDATE EXISTING INSTRUCTOR PROFILE (Ahmed)
-- ============================================================
UPDATE instructor_profiles SET
  display_name = 'أحمد محمد علي',
  headline_ar = 'مطور ويب محترف | خبرة +10 سنوات',
  headline_en = 'Professional Web Developer | 10+ Years Experience',
  bio_ar = 'مطور ويب متخصص في Python و JavaScript و Flutter. قمت بتدريب أكثر من 50,000 طالب حول العالم. شغوف بتبسيط المفاهيم البرمجية المعقدة.',
  bio_en = 'Web developer specializing in Python, JavaScript, and Flutter. Trained over 50,000 students worldwide. Passionate about simplifying complex programming concepts.',
  expertise = ARRAY['Python', 'JavaScript', 'Flutter', 'React', 'Node.js'],
  avatar_url = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
  cover_image_url = 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=800',
  social_links = '{"twitter": "https://twitter.com/ahmed_dev", "linkedin": "https://linkedin.com/in/ahmed-dev", "youtube": "https://youtube.com/@ahmed_dev"}',
  website_url = 'https://ahmeddev.com',
  total_students = 52340,
  total_courses = 12,
  total_reviews = 8750,
  average_rating = 4.85,
  is_verified = true,
  verified_at = NOW(),
  is_active = true,
  updated_at = NOW()
WHERE id = '9d495549-ce6f-46b3-a435-15aead9cc725';

-- ============================================================
-- 2. INSERT NEW MOCK INSTRUCTORS
-- ============================================================

-- Instructor 2: Sarah - UI/UX Designer
INSERT INTO instructor_profiles (
  id, instructor_id, display_name, headline_ar, headline_en, 
  bio_ar, bio_en, avatar_url, cover_image_url, expertise, 
  social_links, website_url, total_students, total_courses, 
  total_reviews, average_rating, is_verified, verified_at, 
  payout_method, revenue_share, is_active
) VALUES (
  gen_random_uuid(),
  gen_random_uuid(),
  'سارة أحمد',
  'مصممة UI/UX | خبيرة تجربة المستخدم',
  'UI/UX Designer | User Experience Expert',
  'مصممة واجهات مستخدم محترفة مع خبرة 8 سنوات في تصميم التطبيقات والمواقع. عملت مع شركات عالمية مثل Google و Microsoft. متخصصة في Figma و Adobe XD.',
  'Professional UI/UX designer with 8 years of experience in app and web design. Worked with global companies like Google and Microsoft. Specialized in Figma and Adobe XD.',
  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
  'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=800',
  ARRAY['UI Design', 'UX Design', 'Figma', 'Adobe XD', 'Prototyping'],
  '{"twitter": "https://twitter.com/sarah_design", "dribbble": "https://dribbble.com/sarah", "behance": "https://behance.net/sarah"}',
  'https://sarahdesign.com',
  38500,
  8,
  6200,
  4.92,
  true,
  NOW(),
  'bank_transfer',
  70.00,
  true
) ON CONFLICT DO NOTHING;

-- Instructor 3: Mohamed - Data Science Expert
INSERT INTO instructor_profiles (
  id, instructor_id, display_name, headline_ar, headline_en, 
  bio_ar, bio_en, avatar_url, cover_image_url, expertise, 
  social_links, website_url, total_students, total_courses, 
  total_reviews, average_rating, is_verified, verified_at, 
  payout_method, revenue_share, is_active
) VALUES (
  gen_random_uuid(),
  gen_random_uuid(),
  'محمد خالد',
  'خبير علوم البيانات | دكتوراه في الذكاء الاصطناعي',
  'Data Science Expert | PhD in AI',
  'حاصل على دكتوراه في الذكاء الاصطناعي من MIT. عملت كباحث في Google AI لمدة 5 سنوات. متخصص في Machine Learning و Deep Learning و Python.',
  'PhD in Artificial Intelligence from MIT. Worked as a researcher at Google AI for 5 years. Specialized in Machine Learning, Deep Learning, and Python.',
  'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200',
  'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800',
  ARRAY['Machine Learning', 'Deep Learning', 'Python', 'TensorFlow', 'Data Analysis'],
  '{"twitter": "https://twitter.com/mohamed_ai", "linkedin": "https://linkedin.com/in/mohamed-ai", "github": "https://github.com/mohamed-ai"}',
  'https://mohamedai.com',
  67800,
  15,
  12400,
  4.88,
  true,
  NOW(),
  'bank_transfer',
  75.00,
  true
) ON CONFLICT DO NOTHING;

-- Instructor 4: Fatima - Mobile Development
INSERT INTO instructor_profiles (
  id, instructor_id, display_name, headline_ar, headline_en, 
  bio_ar, bio_en, avatar_url, cover_image_url, expertise, 
  social_links, website_url, total_students, total_courses, 
  total_reviews, average_rating, is_verified, verified_at, 
  payout_method, revenue_share, is_active
) VALUES (
  gen_random_uuid(),
  gen_random_uuid(),
  'فاطمة الزهراء',
  'مطورة تطبيقات موبايل | Flutter & React Native',
  'Mobile App Developer | Flutter & React Native',
  'مطورة تطبيقات موبايل محترفة مع خبرة 6 سنوات. طورت أكثر من 50 تطبيق على App Store و Google Play. متخصصة في Flutter و React Native و Swift.',
  'Professional mobile app developer with 6 years of experience. Developed over 50 apps on App Store and Google Play. Specialized in Flutter, React Native, and Swift.',
  'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
  'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=800',
  ARRAY['Flutter', 'React Native', 'Swift', 'Kotlin', 'Firebase'],
  '{"twitter": "https://twitter.com/fatima_mobile", "linkedin": "https://linkedin.com/in/fatima-mobile", "github": "https://github.com/fatima-mobile"}',
  'https://fatimamobile.dev',
  45200,
  10,
  7800,
  4.90,
  true,
  NOW(),
  'bank_transfer',
  70.00,
  true
) ON CONFLICT DO NOTHING;

-- Instructor 5: Omar - Cybersecurity Expert
INSERT INTO instructor_profiles (
  id, instructor_id, display_name, headline_ar, headline_en, 
  bio_ar, bio_en, avatar_url, cover_image_url, expertise, 
  social_links, website_url, total_students, total_courses, 
  total_reviews, average_rating, is_verified, verified_at, 
  payout_method, revenue_share, is_active
) VALUES (
  gen_random_uuid(),
  gen_random_uuid(),
  'عمر حسن',
  'خبير أمن سيبراني | CEH & CISSP',
  'Cybersecurity Expert | CEH & CISSP Certified',
  'خبير أمن معلومات معتمد مع شهادات CEH و CISSP و OSCP. عملت في فرق الأمن السيبراني لبنوك كبرى. متخصص في اختبار الاختراق وأمن الشبكات.',
  'Certified information security expert with CEH, CISSP, and OSCP certifications. Worked in cybersecurity teams for major banks. Specialized in penetration testing and network security.',
  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
  'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=800',
  ARRAY['Cybersecurity', 'Ethical Hacking', 'Network Security', 'Penetration Testing', 'Linux'],
  '{"twitter": "https://twitter.com/omar_security", "linkedin": "https://linkedin.com/in/omar-security"}',
  'https://omarsecurity.com',
  32100,
  7,
  5400,
  4.78,
  true,
  NOW(),
  'bank_transfer',
  70.00,
  true
) ON CONFLICT DO NOTHING;

-- Instructor 6: Layla - Digital Marketing
INSERT INTO instructor_profiles (
  id, instructor_id, display_name, headline_ar, headline_en, 
  bio_ar, bio_en, avatar_url, cover_image_url, expertise, 
  social_links, website_url, total_students, total_courses, 
  total_reviews, average_rating, is_verified, verified_at, 
  payout_method, revenue_share, is_active
) VALUES (
  gen_random_uuid(),
  gen_random_uuid(),
  'ليلى محمود',
  'خبيرة تسويق رقمي | Google & Meta Certified',
  'Digital Marketing Expert | Google & Meta Certified',
  'خبيرة تسويق رقمي معتمدة من Google و Meta. ساعدت أكثر من 200 شركة في تحقيق نمو مبيعاتها. متخصصة في SEO و SEM و Social Media Marketing.',
  'Certified digital marketing expert from Google and Meta. Helped over 200 companies achieve sales growth. Specialized in SEO, SEM, and Social Media Marketing.',
  'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=200',
  'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800',
  ARRAY['Digital Marketing', 'SEO', 'Google Ads', 'Facebook Ads', 'Content Marketing'],
  '{"twitter": "https://twitter.com/layla_marketing", "linkedin": "https://linkedin.com/in/layla-marketing", "instagram": "https://instagram.com/layla_marketing"}',
  'https://laylamarketing.com',
  58900,
  11,
  9200,
  4.82,
  true,
  NOW(),
  'bank_transfer',
  70.00,
  true
) ON CONFLICT DO NOTHING;

-- Instructor 7: Youssef - Backend Development
INSERT INTO instructor_profiles (
  id, instructor_id, display_name, headline_ar, headline_en, 
  bio_ar, bio_en, avatar_url, cover_image_url, expertise, 
  social_links, website_url, total_students, total_courses, 
  total_reviews, average_rating, is_verified, verified_at, 
  payout_method, revenue_share, is_active
) VALUES (
  gen_random_uuid(),
  gen_random_uuid(),
  'يوسف إبراهيم',
  'مطور Backend | AWS Solutions Architect',
  'Backend Developer | AWS Solutions Architect',
  'مطور Backend محترف مع شهادة AWS Solutions Architect. خبرة 9 سنوات في بناء أنظمة قابلة للتوسع. متخصص في Node.js و Python و Go و Microservices.',
  'Professional Backend developer with AWS Solutions Architect certification. 9 years of experience building scalable systems. Specialized in Node.js, Python, Go, and Microservices.',
  'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200',
  'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=800',
  ARRAY['Node.js', 'Python', 'Go', 'AWS', 'Microservices', 'Docker', 'Kubernetes'],
  '{"twitter": "https://twitter.com/youssef_backend", "linkedin": "https://linkedin.com/in/youssef-backend", "github": "https://github.com/youssef-backend"}',
  'https://youssefdev.com',
  41300,
  9,
  6800,
  4.86,
  true,
  NOW(),
  'bank_transfer',
  72.00,
  true
) ON CONFLICT DO NOTHING;

-- Instructor 8: Nour - Graphic Design
INSERT INTO instructor_profiles (
  id, instructor_id, display_name, headline_ar, headline_en, 
  bio_ar, bio_en, avatar_url, cover_image_url, expertise, 
  social_links, website_url, total_students, total_courses, 
  total_reviews, average_rating, is_verified, verified_at, 
  payout_method, revenue_share, is_active
) VALUES (
  gen_random_uuid(),
  gen_random_uuid(),
  'نور الدين',
  'مصمم جرافيك | Adobe Creative Suite Expert',
  'Graphic Designer | Adobe Creative Suite Expert',
  'مصمم جرافيك محترف مع خبرة 12 سنة. عملت مع علامات تجارية عالمية مثل Nike و Adidas. متخصص في Photoshop و Illustrator و After Effects.',
  'Professional graphic designer with 12 years of experience. Worked with global brands like Nike and Adidas. Specialized in Photoshop, Illustrator, and After Effects.',
  'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200',
  'https://images.unsplash.com/photo-1626785774573-4b799315345d?w=800',
  ARRAY['Photoshop', 'Illustrator', 'After Effects', 'InDesign', 'Brand Design'],
  '{"twitter": "https://twitter.com/nour_design", "behance": "https://behance.net/nour", "dribbble": "https://dribbble.com/nour"}',
  'https://nourdesign.art',
  29800,
  6,
  4900,
  4.94,
  true,
  NOW(),
  'bank_transfer',
  70.00,
  true
) ON CONFLICT DO NOTHING;

-- Instructor 9: Hana - Business & Entrepreneurship
INSERT INTO instructor_profiles (
  id, instructor_id, display_name, headline_ar, headline_en, 
  bio_ar, bio_en, avatar_url, cover_image_url, expertise, 
  social_links, website_url, total_students, total_courses, 
  total_reviews, average_rating, is_verified, verified_at, 
  payout_method, revenue_share, is_active
) VALUES (
  gen_random_uuid(),
  gen_random_uuid(),
  'هناء السيد',
  'مستشارة أعمال | MBA من Harvard',
  'Business Consultant | Harvard MBA',
  'مستشارة أعمال حاصلة على MBA من Harvard. أسست 3 شركات ناجحة. متخصصة في ريادة الأعمال وإدارة المشاريع والتخطيط الاستراتيجي.',
  'Business consultant with Harvard MBA. Founded 3 successful companies. Specialized in entrepreneurship, project management, and strategic planning.',
  'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200',
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800',
  ARRAY['Business Strategy', 'Entrepreneurship', 'Project Management', 'Leadership', 'Finance'],
  '{"twitter": "https://twitter.com/hana_business", "linkedin": "https://linkedin.com/in/hana-business"}',
  'https://hanabusiness.com',
  72500,
  14,
  11800,
  4.80,
  true,
  NOW(),
  'bank_transfer',
  75.00,
  true
) ON CONFLICT DO NOTHING;

-- Instructor 10: Karim - Game Development
INSERT INTO instructor_profiles (
  id, instructor_id, display_name, headline_ar, headline_en, 
  bio_ar, bio_en, avatar_url, cover_image_url, expertise, 
  social_links, website_url, total_students, total_courses, 
  total_reviews, average_rating, is_verified, verified_at, 
  payout_method, revenue_share, is_active
) VALUES (
  gen_random_uuid(),
  gen_random_uuid(),
  'كريم عادل',
  'مطور ألعاب | Unity & Unreal Expert',
  'Game Developer | Unity & Unreal Expert',
  'مطور ألعاب محترف مع خبرة 7 سنوات. طورت ألعاب حققت أكثر من 10 مليون تحميل. متخصص في Unity و Unreal Engine و C# و C++.',
  'Professional game developer with 7 years of experience. Developed games with over 10 million downloads. Specialized in Unity, Unreal Engine, C#, and C++.',
  'https://images.unsplash.com/photo-1463453091185-61582044d556?w=200',
  'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800',
  ARRAY['Unity', 'Unreal Engine', 'C#', 'C++', 'Game Design', '3D Modeling'],
  '{"twitter": "https://twitter.com/karim_games", "youtube": "https://youtube.com/@karim_games", "github": "https://github.com/karim-games"}',
  'https://karimgames.dev',
  35600,
  8,
  5700,
  4.87,
  true,
  NOW(),
  'bank_transfer',
  70.00,
  true
) ON CONFLICT DO NOTHING;

-- ============================================================
-- 3. VERIFY DATA
-- ============================================================
SELECT 
  id, 
  display_name, 
  headline_ar,
  total_courses,
  total_students,
  average_rating,
  is_verified
FROM instructor_profiles
ORDER BY total_students DESC;

SELECT '✅ 10 Instructor profiles created/updated successfully!' as status;
