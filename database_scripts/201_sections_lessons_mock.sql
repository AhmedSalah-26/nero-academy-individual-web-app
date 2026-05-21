-- ============================================================
-- 🎓 LMS Mock Data - Sections & Lessons
-- Version: 1.1 | January 2026
-- Fixed UUID format
-- ============================================================

-- ============================================================
-- COURSE 1: Python الشاملة (cc100000-0000-4000-a000-000000000001)
-- ============================================================

-- Sections for Python Course
INSERT INTO sections (id, course_id, title_ar, title_en, sort_order, is_published) VALUES
('a1000000-0000-4000-a000-000000000001', 'cc100000-0000-4000-a000-000000000001', 'مقدمة في Python', 'Introduction to Python', 1, true),
('a1000000-0000-4000-a000-000000000002', 'cc100000-0000-4000-a000-000000000001', 'المتغيرات وأنواع البيانات', 'Variables and Data Types', 2, true),
('a1000000-0000-4000-a000-000000000003', 'cc100000-0000-4000-a000-000000000001', 'الجمل الشرطية والحلقات', 'Conditionals and Loops', 3, true),
('a1000000-0000-4000-a000-000000000004', 'cc100000-0000-4000-a000-000000000001', 'الدوال والوحدات', 'Functions and Modules', 4, true),
('a1000000-0000-4000-a000-000000000005', 'cc100000-0000-4000-a000-000000000001', 'البرمجة الكائنية OOP', 'Object-Oriented Programming', 5, true)
ON CONFLICT (id) DO UPDATE SET title_ar = EXCLUDED.title_ar;

-- Lessons for Section 1: مقدمة في Python
INSERT INTO lessons (id, section_id, course_id, title_ar, title_en, type, video_url, video_provider, video_duration, is_preview, sort_order, is_published) VALUES
('b1000000-0000-4000-a000-000000000001', 'a1000000-0000-4000-a000-000000000001', 'cc100000-0000-4000-a000-000000000001', 'مرحباً بك في الدورة', 'Welcome to the Course', 'video', 'https://www.youtube.com/watch?v=kqtD5dpn9C8', 'youtube', 180, true, 1, true),
('b1000000-0000-4000-a000-000000000002', 'a1000000-0000-4000-a000-000000000001', 'cc100000-0000-4000-a000-000000000001', 'تثبيت Python', 'Installing Python', 'video', 'https://www.youtube.com/watch?v=YYXdXT2l-Gg', 'youtube', 420, true, 2, true),
('b1000000-0000-4000-a000-000000000003', 'a1000000-0000-4000-a000-000000000001', 'cc100000-0000-4000-a000-000000000001', 'أول برنامج لك', 'Your First Program', 'video', 'https://www.youtube.com/watch?v=rfscVS0vtbw', 'youtube', 600, false, 3, true),
('b1000000-0000-4000-a000-000000000004', 'a1000000-0000-4000-a000-000000000001', 'cc100000-0000-4000-a000-000000000001', 'اختبار: مقدمة Python', 'Quiz: Python Introduction', 'quiz', NULL, NULL, 0, false, 4, true)
ON CONFLICT (id) DO UPDATE SET title_ar = EXCLUDED.title_ar, video_url = EXCLUDED.video_url, video_provider = EXCLUDED.video_provider;

-- Lessons for Section 2: المتغيرات
INSERT INTO lessons (id, section_id, course_id, title_ar, title_en, type, video_url, video_provider, video_duration, is_preview, sort_order, is_published) VALUES
('b1000000-0000-4000-a000-000000000005', 'a1000000-0000-4000-a000-000000000002', 'cc100000-0000-4000-a000-000000000001', 'ما هي المتغيرات؟', 'What are Variables?', 'video', 'https://www.youtube.com/watch?v=cQT33yu9pY8', 'youtube', 540, false, 1, true),
('b1000000-0000-4000-a000-000000000006', 'a1000000-0000-4000-a000-000000000002', 'cc100000-0000-4000-a000-000000000001', 'الأرقام والنصوص', 'Numbers and Strings', 'video', 'https://www.youtube.com/watch?v=khKv-8q7YmY', 'youtube', 720, false, 2, true),
('b1000000-0000-4000-a000-000000000007', 'a1000000-0000-4000-a000-000000000002', 'cc100000-0000-4000-a000-000000000001', 'القوائم Lists', 'Lists', 'video', 'https://www.youtube.com/watch?v=W8KRzm-HUcc', 'youtube', 900, false, 3, true),
('b1000000-0000-4000-a000-000000000008', 'a1000000-0000-4000-a000-000000000002', 'cc100000-0000-4000-a000-000000000001', 'القواميس Dictionaries', 'Dictionaries', 'video', 'https://www.youtube.com/watch?v=daefaLgNkw0', 'youtube', 840, false, 4, true),
('b1000000-0000-4000-a000-000000000009', 'a1000000-0000-4000-a000-000000000002', 'cc100000-0000-4000-a000-000000000001', 'تمرين عملي', 'Practical Exercise', 'assignment', NULL, NULL, 0, false, 5, true)
ON CONFLICT (id) DO UPDATE SET title_ar = EXCLUDED.title_ar, video_url = EXCLUDED.video_url, video_provider = EXCLUDED.video_provider;

-- Lessons for Section 3: الشرطية والحلقات
INSERT INTO lessons (id, section_id, course_id, title_ar, title_en, type, video_url, video_provider, video_duration, is_preview, sort_order, is_published) VALUES
('b1000000-0000-4000-a000-000000000010', 'a1000000-0000-4000-a000-000000000003', 'cc100000-0000-4000-a000-000000000001', 'جملة if الشرطية', 'If Statement', 'video', 'https://www.youtube.com/watch?v=DZwmZ8Usvnk', 'youtube', 660, false, 1, true),
('b1000000-0000-4000-a000-000000000011', 'a1000000-0000-4000-a000-000000000003', 'cc100000-0000-4000-a000-000000000001', 'حلقة for', 'For Loop', 'video', 'https://www.youtube.com/watch?v=6iF8Xb7Z3wQ', 'youtube', 780, false, 2, true),
('b1000000-0000-4000-a000-000000000012', 'a1000000-0000-4000-a000-000000000003', 'cc100000-0000-4000-a000-000000000001', 'حلقة while', 'While Loop', 'video', 'https://www.youtube.com/watch?v=6TEGxJXLAWQ', 'youtube', 600, false, 3, true),
('b1000000-0000-4000-a000-000000000013', 'a1000000-0000-4000-a000-000000000003', 'cc100000-0000-4000-a000-000000000001', 'مشروع: لعبة التخمين', 'Project: Guessing Game', 'video', 'https://www.youtube.com/watch?v=8ext9G7xspg', 'youtube', 1200, false, 4, true)
ON CONFLICT (id) DO UPDATE SET title_ar = EXCLUDED.title_ar, video_url = EXCLUDED.video_url, video_provider = EXCLUDED.video_provider;

-- Lessons for Section 4: الدوال
INSERT INTO lessons (id, section_id, course_id, title_ar, title_en, type, video_url, video_provider, video_duration, is_preview, sort_order, is_published) VALUES
('b1000000-0000-4000-a000-000000000014', 'a1000000-0000-4000-a000-000000000004', 'cc100000-0000-4000-a000-000000000001', 'تعريف الدوال', 'Defining Functions', 'video', 'https://www.youtube.com/watch?v=9Os0o3wzS_I', 'youtube', 720, false, 1, true),
('b1000000-0000-4000-a000-000000000015', 'a1000000-0000-4000-a000-000000000004', 'cc100000-0000-4000-a000-000000000001', 'المعاملات والقيم المرجعة', 'Parameters and Return Values', 'video', 'https://www.youtube.com/watch?v=u-OmVr_fT4s', 'youtube', 840, false, 2, true),
('b1000000-0000-4000-a000-000000000016', 'a1000000-0000-4000-a000-000000000004', 'cc100000-0000-4000-a000-000000000001', 'الوحدات والمكتبات', 'Modules and Libraries', 'video', 'https://www.youtube.com/watch?v=1RuMJ53CKds', 'youtube', 960, false, 3, true)
ON CONFLICT (id) DO UPDATE SET title_ar = EXCLUDED.title_ar, video_url = EXCLUDED.video_url, video_provider = EXCLUDED.video_provider;

-- Lessons for Section 5: OOP
INSERT INTO lessons (id, section_id, course_id, title_ar, title_en, type, video_url, video_provider, video_duration, is_preview, sort_order, is_published) VALUES
('b1000000-0000-4000-a000-000000000017', 'a1000000-0000-4000-a000-000000000005', 'cc100000-0000-4000-a000-000000000001', 'مقدمة في OOP', 'Introduction to OOP', 'video', 'https://www.youtube.com/watch?v=JeznW_7DlB0', 'youtube', 600, false, 1, true),
('b1000000-0000-4000-a000-000000000018', 'a1000000-0000-4000-a000-000000000005', 'cc100000-0000-4000-a000-000000000001', 'الكلاسات والكائنات', 'Classes and Objects', 'video', 'https://www.youtube.com/watch?v=apACNr7DC_s', 'youtube', 900, false, 2, true),
('b1000000-0000-4000-a000-000000000019', 'a1000000-0000-4000-a000-000000000005', 'cc100000-0000-4000-a000-000000000001', 'الوراثة Inheritance', 'Inheritance', 'video', 'https://www.youtube.com/watch?v=Cn7AkDb4pIU', 'youtube', 1080, false, 3, true),
('b1000000-0000-4000-a000-000000000020', 'a1000000-0000-4000-a000-000000000005', 'cc100000-0000-4000-a000-000000000001', 'مشروع نهائي', 'Final Project', 'assignment', NULL, NULL, 0, false, 4, true)
ON CONFLICT (id) DO UPDATE SET title_ar = EXCLUDED.title_ar, video_url = EXCLUDED.video_url, video_provider = EXCLUDED.video_provider;

-- ============================================================
-- COURSE 2: UI/UX Design (cc100000-0000-4000-a000-000000000002)
-- ============================================================

INSERT INTO sections (id, course_id, title_ar, title_en, sort_order, is_published) VALUES
('a2000000-0000-4000-a000-000000000001', 'cc100000-0000-4000-a000-000000000002', 'أساسيات التصميم', 'Design Fundamentals', 1, true),
('a2000000-0000-4000-a000-000000000002', 'cc100000-0000-4000-a000-000000000002', 'مقدمة في Figma', 'Introduction to Figma', 2, true),
('a2000000-0000-4000-a000-000000000003', 'cc100000-0000-4000-a000-000000000002', 'تصميم واجهات المستخدم', 'UI Design', 3, true),
('a2000000-0000-4000-a000-000000000004', 'cc100000-0000-4000-a000-000000000002', 'تجربة المستخدم UX', 'User Experience', 4, true)
ON CONFLICT (id) DO UPDATE SET title_ar = EXCLUDED.title_ar;

INSERT INTO lessons (id, section_id, course_id, title_ar, title_en, type, video_url, video_provider, video_duration, is_preview, sort_order, is_published) VALUES
('b2000000-0000-4000-a000-000000000001', 'a2000000-0000-4000-a000-000000000001', 'cc100000-0000-4000-a000-000000000002', 'مبادئ التصميم', 'Design Principles', 'video', 'https://www.youtube.com/watch?v=YqQx75OPRa0', 'youtube', 720, true, 1, true),
('b2000000-0000-4000-a000-000000000002', 'a2000000-0000-4000-a000-000000000001', 'cc100000-0000-4000-a000-000000000002', 'نظرية الألوان', 'Color Theory', 'video', 'https://www.youtube.com/watch?v=_2LLXnUdUIc', 'youtube', 840, true, 2, true),
('b2000000-0000-4000-a000-000000000003', 'a2000000-0000-4000-a000-000000000001', 'cc100000-0000-4000-a000-000000000002', 'الخطوط Typography', 'Typography', 'video', 'https://www.youtube.com/watch?v=sByzHoiYFX0', 'youtube', 660, false, 3, true),
('b2000000-0000-4000-a000-000000000004', 'a2000000-0000-4000-a000-000000000002', 'cc100000-0000-4000-a000-000000000002', 'واجهة Figma', 'Figma Interface', 'video', 'https://www.youtube.com/watch?v=FTFaQWZBqQ8', 'youtube', 900, false, 1, true),
('b2000000-0000-4000-a000-000000000005', 'a2000000-0000-4000-a000-000000000002', 'cc100000-0000-4000-a000-000000000002', 'الأشكال والمسارات', 'Shapes and Paths', 'video', 'https://www.youtube.com/watch?v=dXQ7IHkTiMM', 'youtube', 1080, false, 2, true),
('b2000000-0000-4000-a000-000000000006', 'a2000000-0000-4000-a000-000000000002', 'cc100000-0000-4000-a000-000000000002', 'المكونات Components', 'Components', 'video', 'https://www.youtube.com/watch?v=k74IrUNaJVk', 'youtube', 1200, false, 3, true),
('b2000000-0000-4000-a000-000000000007', 'a2000000-0000-4000-a000-000000000003', 'cc100000-0000-4000-a000-000000000002', 'تصميم الأزرار', 'Button Design', 'video', 'https://www.youtube.com/watch?v=G7cKwLWKhBY', 'youtube', 600, false, 1, true),
('b2000000-0000-4000-a000-000000000008', 'a2000000-0000-4000-a000-000000000003', 'cc100000-0000-4000-a000-000000000002', 'تصميم النماذج', 'Form Design', 'video', 'https://www.youtube.com/watch?v=2vFgZgqzc7k', 'youtube', 780, false, 2, true),
('b2000000-0000-4000-a000-000000000009', 'a2000000-0000-4000-a000-000000000004', 'cc100000-0000-4000-a000-000000000002', 'بحث المستخدم', 'User Research', 'video', 'https://www.youtube.com/watch?v=0Wy_m0hj6pM', 'youtube', 900, false, 1, true),
('b2000000-0000-4000-a000-000000000010', 'a2000000-0000-4000-a000-000000000004', 'cc100000-0000-4000-a000-000000000002', 'رحلة المستخدم', 'User Journey', 'video', 'https://www.youtube.com/watch?v=mSxpVRo3BLg', 'youtube', 840, false, 2, true)
ON CONFLICT (id) DO UPDATE SET title_ar = EXCLUDED.title_ar, video_url = EXCLUDED.video_url, video_provider = EXCLUDED.video_provider;

-- ============================================================
-- COURSE 7: Flutter (cc100000-0000-4000-a000-000000000007)
-- ============================================================

INSERT INTO sections (id, course_id, title_ar, title_en, sort_order, is_published) VALUES
('a7000000-0000-4000-a000-000000000001', 'cc100000-0000-4000-a000-000000000007', 'مقدمة في Flutter', 'Introduction to Flutter', 1, true),
('a7000000-0000-4000-a000-000000000002', 'cc100000-0000-4000-a000-000000000007', 'أساسيات Dart', 'Dart Basics', 2, true),
('a7000000-0000-4000-a000-000000000003', 'cc100000-0000-4000-a000-000000000007', 'الـ Widgets الأساسية', 'Basic Widgets', 3, true),
('a7000000-0000-4000-a000-000000000004', 'cc100000-0000-4000-a000-000000000007', 'إدارة الحالة State', 'State Management', 4, true),
('a7000000-0000-4000-a000-000000000005', 'cc100000-0000-4000-a000-000000000007', 'التنقل والـ Routing', 'Navigation & Routing', 5, true),
('a7000000-0000-4000-a000-000000000006', 'cc100000-0000-4000-a000-000000000007', 'الاتصال بالـ API', 'API Integration', 6, true)
ON CONFLICT (id) DO UPDATE SET title_ar = EXCLUDED.title_ar;

INSERT INTO lessons (id, section_id, course_id, title_ar, title_en, type, video_url, video_provider, video_duration, is_preview, sort_order, is_published) VALUES
('b7000000-0000-4000-a000-000000000001', 'a7000000-0000-4000-a000-000000000001', 'cc100000-0000-4000-a000-000000000007', 'ما هو Flutter؟', 'What is Flutter?', 'video', 'https://www.youtube.com/watch?v=I9ceqw5Ny-4', 'youtube', 480, true, 1, true),
('b7000000-0000-4000-a000-000000000002', 'a7000000-0000-4000-a000-000000000001', 'cc100000-0000-4000-a000-000000000007', 'تثبيت Flutter', 'Installing Flutter', 'video', 'https://www.youtube.com/watch?v=1ukSR1GRtMU', 'youtube', 900, true, 2, true),
('b7000000-0000-4000-a000-000000000003', 'a7000000-0000-4000-a000-000000000001', 'cc100000-0000-4000-a000-000000000007', 'أول تطبيق Flutter', 'First Flutter App', 'video', 'https://www.youtube.com/watch?v=xWV71C2kp38', 'youtube', 720, false, 3, true),
('b7000000-0000-4000-a000-000000000004', 'a7000000-0000-4000-a000-000000000002', 'cc100000-0000-4000-a000-000000000007', 'متغيرات Dart', 'Dart Variables', 'video', 'https://www.youtube.com/watch?v=Ej_Pcr4uC2Q', 'youtube', 600, false, 1, true),
('b7000000-0000-4000-a000-000000000005', 'a7000000-0000-4000-a000-000000000002', 'cc100000-0000-4000-a000-000000000007', 'الدوال في Dart', 'Functions in Dart', 'video', 'https://www.youtube.com/watch?v=7S0ilFx2Dkk', 'youtube', 780, false, 2, true),
('b7000000-0000-4000-a000-000000000006', 'a7000000-0000-4000-a000-000000000002', 'cc100000-0000-4000-a000-000000000007', 'الكلاسات في Dart', 'Classes in Dart', 'video', 'https://www.youtube.com/watch?v=s8Wy5fbljNs', 'youtube', 900, false, 3, true),
('b7000000-0000-4000-a000-000000000007', 'a7000000-0000-4000-a000-000000000003', 'cc100000-0000-4000-a000-000000000007', 'Container و Column و Row', 'Container, Column & Row', 'video', 'https://www.youtube.com/watch?v=VdkRy3yZiPo', 'youtube', 1080, false, 1, true),
('b7000000-0000-4000-a000-000000000008', 'a7000000-0000-4000-a000-000000000003', 'cc100000-0000-4000-a000-000000000007', 'Text و Image', 'Text & Image Widgets', 'video', 'https://www.youtube.com/watch?v=TSIhiZ5jRB0', 'youtube', 720, false, 2, true),
('b7000000-0000-4000-a000-000000000009', 'a7000000-0000-4000-a000-000000000003', 'cc100000-0000-4000-a000-000000000007', 'ListView و GridView', 'ListView & GridView', 'video', 'https://www.youtube.com/watch?v=bLOtZDTm4H8', 'youtube', 960, false, 3, true),
('b7000000-0000-4000-a000-000000000010', 'a7000000-0000-4000-a000-000000000004', 'cc100000-0000-4000-a000-000000000007', 'setState', 'setState', 'video', 'https://www.youtube.com/watch?v=p4dRvMkzPTs', 'youtube', 600, false, 1, true),
('b7000000-0000-4000-a000-000000000011', 'a7000000-0000-4000-a000-000000000004', 'cc100000-0000-4000-a000-000000000007', 'Provider', 'Provider', 'video', 'https://www.youtube.com/watch?v=L_QMsE2v6dw', 'youtube', 1200, false, 2, true),
('b7000000-0000-4000-a000-000000000012', 'a7000000-0000-4000-a000-000000000004', 'cc100000-0000-4000-a000-000000000007', 'BLoC Pattern', 'BLoC Pattern', 'video', 'https://www.youtube.com/watch?v=THCkkQ-V1-8', 'youtube', 1500, false, 3, true),
('b7000000-0000-4000-a000-000000000013', 'a7000000-0000-4000-a000-000000000005', 'cc100000-0000-4000-a000-000000000007', 'Navigator الأساسي', 'Basic Navigator', 'video', 'https://www.youtube.com/watch?v=nyvwx7o277U', 'youtube', 720, false, 1, true),
('b7000000-0000-4000-a000-000000000014', 'a7000000-0000-4000-a000-000000000005', 'cc100000-0000-4000-a000-000000000007', 'GoRouter', 'GoRouter', 'video', 'https://www.youtube.com/watch?v=b6Z885Z46cU', 'youtube', 900, false, 2, true),
('b7000000-0000-4000-a000-000000000015', 'a7000000-0000-4000-a000-000000000006', 'cc100000-0000-4000-a000-000000000007', 'HTTP Requests', 'HTTP Requests', 'video', 'https://www.youtube.com/watch?v=WdXcJdhWcEY', 'youtube', 840, false, 1, true),
('b7000000-0000-4000-a000-000000000016', 'a7000000-0000-4000-a000-000000000006', 'cc100000-0000-4000-a000-000000000007', 'JSON Parsing', 'JSON Parsing', 'video', 'https://www.youtube.com/watch?v=c09XiwOZKsI', 'youtube', 780, false, 2, true),
('b7000000-0000-4000-a000-000000000017', 'a7000000-0000-4000-a000-000000000006', 'cc100000-0000-4000-a000-000000000007', 'مشروع: تطبيق أخبار', 'Project: News App', 'video', 'https://www.youtube.com/watch?v=TclK5gNM-8M', 'youtube', 2400, false, 3, true)
ON CONFLICT (id) DO UPDATE SET title_ar = EXCLUDED.title_ar, video_url = EXCLUDED.video_url, video_provider = EXCLUDED.video_provider;

-- ============================================================
-- COURSE 4: React Advanced (cc100000-0000-4000-a000-000000000004)
-- ============================================================

INSERT INTO sections (id, course_id, title_ar, title_en, sort_order, is_published) VALUES
('a4000000-0000-4000-a000-000000000001', 'cc100000-0000-4000-a000-000000000004', 'React Hooks المتقدمة', 'Advanced React Hooks', 1, true),
('a4000000-0000-4000-a000-000000000002', 'cc100000-0000-4000-a000-000000000004', 'أنماط التصميم', 'Design Patterns', 2, true),
('a4000000-0000-4000-a000-000000000003', 'cc100000-0000-4000-a000-000000000004', 'تحسين الأداء', 'Performance Optimization', 3, true)
ON CONFLICT (id) DO UPDATE SET title_ar = EXCLUDED.title_ar;

INSERT INTO lessons (id, section_id, course_id, title_ar, title_en, type, video_url, video_provider, video_duration, is_preview, sort_order, is_published) VALUES
('b4000000-0000-4000-a000-000000000001', 'a4000000-0000-4000-a000-000000000001', 'cc100000-0000-4000-a000-000000000004', 'useReducer المتقدم', 'Advanced useReducer', 'video', 'https://www.youtube.com/watch?v=kK_Wqx3RnHk', 'youtube', 900, true, 1, true),
('b4000000-0000-4000-a000-000000000002', 'a4000000-0000-4000-a000-000000000001', 'cc100000-0000-4000-a000-000000000004', 'Custom Hooks', 'Custom Hooks', 'video', 'https://www.youtube.com/watch?v=J-g9ZJha8FE', 'youtube', 1200, false, 2, true),
('b4000000-0000-4000-a000-000000000003', 'a4000000-0000-4000-a000-000000000001', 'cc100000-0000-4000-a000-000000000004', 'useContext المتقدم', 'Advanced useContext', 'video', 'https://www.youtube.com/watch?v=5LrDIWkK_Bc', 'youtube', 840, false, 3, true),
('b4000000-0000-4000-a000-000000000004', 'a4000000-0000-4000-a000-000000000002', 'cc100000-0000-4000-a000-000000000004', 'Compound Components', 'Compound Components', 'video', 'https://www.youtube.com/watch?v=vPRdY87_SH0', 'youtube', 1080, false, 1, true),
('b4000000-0000-4000-a000-000000000005', 'a4000000-0000-4000-a000-000000000002', 'cc100000-0000-4000-a000-000000000004', 'Render Props', 'Render Props', 'video', 'https://www.youtube.com/watch?v=NdapMDgNhtE', 'youtube', 960, false, 2, true),
('b4000000-0000-4000-a000-000000000006', 'a4000000-0000-4000-a000-000000000003', 'cc100000-0000-4000-a000-000000000004', 'React.memo و useMemo', 'React.memo & useMemo', 'video', 'https://www.youtube.com/watch?v=THL1OPn72vo', 'youtube', 780, false, 1, true),
('b4000000-0000-4000-a000-000000000007', 'a4000000-0000-4000-a000-000000000003', 'cc100000-0000-4000-a000-000000000004', 'Code Splitting', 'Code Splitting', 'video', 'https://www.youtube.com/watch?v=tV9gvls8IP8', 'youtube', 900, false, 2, true)
ON CONFLICT (id) DO UPDATE SET title_ar = EXCLUDED.title_ar, video_url = EXCLUDED.video_url, video_provider = EXCLUDED.video_provider;

-- ============================================================
-- UPDATE SECTION STATS
-- ============================================================
UPDATE sections SET 
  total_lessons = (SELECT COUNT(*) FROM lessons WHERE lessons.section_id = sections.id AND lessons.is_published = true),
  total_duration = (SELECT COALESCE(SUM(video_duration), 0) FROM lessons WHERE lessons.section_id = sections.id AND lessons.is_published = true);

-- ============================================================
-- UPDATE COURSE STATS
-- ============================================================
UPDATE courses SET 
  total_sections = (SELECT COUNT(*) FROM sections WHERE sections.course_id = courses.id AND sections.is_published = true),
  total_lessons = (SELECT COUNT(*) FROM lessons WHERE lessons.course_id = courses.id AND lessons.is_published = true),
  total_duration = (SELECT COALESCE(SUM(video_duration) / 60, 0) FROM lessons WHERE lessons.course_id = courses.id AND lessons.is_published = true);

-- ============================================================
-- VERIFY DATA
-- ============================================================
SELECT 'Sections: ' || COUNT(*)::text FROM sections;
SELECT 'Lessons: ' || COUNT(*)::text FROM lessons;

SELECT '✅ Sections & Lessons mock data inserted successfully!' as status;
