-- ============================================================
-- Mock Data: Flutter Course Quizzes
-- Course ID: cc100000-0000-4000-a000-000000000007 (Flutter Course)
-- ============================================================

-- Create temporary variables for quiz IDs
DO $$
DECLARE
  v_quiz1_id UUID;
  v_quiz2_id UUID;
  v_quiz3_id UUID;
  v_course_id UUID := 'cc100000-0000-4000-a000-000000000007';
BEGIN

-- Quiz 1: Flutter Basics Quiz (Course Level - no lesson_id)
INSERT INTO quizzes (
  lesson_id, course_id, 
  title_ar, title_en, 
  description_ar, description_en,
  passing_score, time_limit, max_attempts,
  shuffle_questions, shuffle_answers, show_correct_answers,
  total_questions, total_points, is_published, is_mandatory
) VALUES (
  NULL, -- Course level quiz
  v_course_id,
  'اختبار أساسيات Flutter',
  'Flutter Basics Quiz',
  'اختبر معرفتك بأساسيات Flutter و Dart',
  'Test your knowledge of Flutter and Dart basics',
  70, 15, 3,
  true, true, true,
  5, 10, true, false
) RETURNING id INTO v_quiz1_id;

-- Quiz 1 Questions
INSERT INTO quiz_questions (quiz_id, question_ar, question_en, question_type, options, points, explanation_ar, explanation_en, sort_order) VALUES
(v_quiz1_id,
 'ما هي لغة البرمجة المستخدمة في Flutter؟',
 'What programming language is used in Flutter?',
 'single',
 '[
   {"id": "a", "text_ar": "Java", "text_en": "Java", "is_correct": false},
   {"id": "b", "text_ar": "Kotlin", "text_en": "Kotlin", "is_correct": false},
   {"id": "c", "text_ar": "Dart", "text_en": "Dart", "is_correct": true},
   {"id": "d", "text_ar": "Swift", "text_en": "Swift", "is_correct": false}
 ]'::jsonb,
 2, 'Flutter يستخدم لغة Dart التي طورتها Google', 'Flutter uses Dart language developed by Google', 1),

(v_quiz1_id,
 'ما هو الـ Widget الأساسي لعرض نص في Flutter؟',
 'What is the basic Widget to display text in Flutter?',
 'single',
 '[
   {"id": "a", "text_ar": "Label", "text_en": "Label", "is_correct": false},
   {"id": "b", "text_ar": "Text", "text_en": "Text", "is_correct": true},
   {"id": "c", "text_ar": "TextView", "text_en": "TextView", "is_correct": false},
   {"id": "d", "text_ar": "String", "text_en": "String", "is_correct": false}
 ]'::jsonb,
 2, 'Text widget هو الـ widget الأساسي لعرض النصوص', 'Text widget is the basic widget for displaying text', 2),

(v_quiz1_id,
 'Flutter يمكنه بناء تطبيقات لـ iOS و Android فقط',
 'Flutter can only build apps for iOS and Android',
 'true_false',
 '[
   {"id": "true", "text_ar": "صح", "text_en": "True", "is_correct": false},
   {"id": "false", "text_ar": "خطأ", "text_en": "False", "is_correct": true}
 ]'::jsonb,
 2, 'Flutter يدعم أيضاً Web و Desktop (Windows, macOS, Linux)', 'Flutter also supports Web and Desktop (Windows, macOS, Linux)', 3),

(v_quiz1_id,
 'أي من التالي يُستخدم لإدارة الحالة في Flutter؟',
 'Which of the following is used for state management in Flutter?',
 'multiple',
 '[
   {"id": "a", "text_ar": "setState", "text_en": "setState", "is_correct": true},
   {"id": "b", "text_ar": "Provider", "text_en": "Provider", "is_correct": true},
   {"id": "c", "text_ar": "BLoC", "text_en": "BLoC", "is_correct": true},
   {"id": "d", "text_ar": "HTML", "text_en": "HTML", "is_correct": false}
 ]'::jsonb,
 2, 'setState, Provider, و BLoC كلها طرق لإدارة الحالة في Flutter', 'setState, Provider, and BLoC are all state management solutions in Flutter', 4),

(v_quiz1_id,
 'ما هو الفرق بين StatelessWidget و StatefulWidget؟',
 'What is the difference between StatelessWidget and StatefulWidget?',
 'single',
 '[
   {"id": "a", "text_ar": "لا يوجد فرق", "text_en": "No difference", "is_correct": false},
   {"id": "b", "text_ar": "StatefulWidget يمكنه تغيير حالته", "text_en": "StatefulWidget can change its state", "is_correct": true},
   {"id": "c", "text_ar": "StatelessWidget أسرع دائماً", "text_en": "StatelessWidget is always faster", "is_correct": false},
   {"id": "d", "text_ar": "StatefulWidget للـ iOS فقط", "text_en": "StatefulWidget is for iOS only", "is_correct": false}
 ]'::jsonb,
 2, 'StatefulWidget يحتفظ بحالة يمكن تغييرها، بينما StatelessWidget ثابت', 'StatefulWidget maintains mutable state, while StatelessWidget is immutable', 5);


-- Quiz 2: Flutter UI Quiz (Course Level)
INSERT INTO quizzes (
  lesson_id, course_id, 
  title_ar, title_en, 
  description_ar, description_en,
  passing_score, time_limit, max_attempts,
  shuffle_questions, shuffle_answers, show_correct_answers,
  total_questions, total_points, is_published, is_mandatory
) VALUES (
  NULL,
  v_course_id,
  'اختبار واجهات المستخدم في Flutter',
  'Flutter UI Quiz',
  'اختبر معرفتك ببناء واجهات المستخدم',
  'Test your knowledge of building user interfaces',
  60, 10, NULL,
  false, true, true,
  4, 8, true, false
) RETURNING id INTO v_quiz2_id;

-- Quiz 2 Questions
INSERT INTO quiz_questions (quiz_id, question_ar, question_en, question_type, options, points, explanation_ar, explanation_en, sort_order) VALUES
(v_quiz2_id,
 'أي Widget يُستخدم لترتيب العناصر أفقياً؟',
 'Which Widget is used to arrange items horizontally?',
 'single',
 '[
   {"id": "a", "text_ar": "Column", "text_en": "Column", "is_correct": false},
   {"id": "b", "text_ar": "Row", "text_en": "Row", "is_correct": true},
   {"id": "c", "text_ar": "Stack", "text_en": "Stack", "is_correct": false},
   {"id": "d", "text_ar": "ListView", "text_en": "ListView", "is_correct": false}
 ]'::jsonb,
 2, 'Row يرتب العناصر أفقياً، بينما Column يرتبها رأسياً', 'Row arranges items horizontally, while Column arranges them vertically', 1),

(v_quiz2_id,
 'ما هو الـ Widget المستخدم لإضافة padding؟',
 'What Widget is used to add padding?',
 'single',
 '[
   {"id": "a", "text_ar": "Margin", "text_en": "Margin", "is_correct": false},
   {"id": "b", "text_ar": "Padding", "text_en": "Padding", "is_correct": true},
   {"id": "c", "text_ar": "Space", "text_en": "Space", "is_correct": false},
   {"id": "d", "text_ar": "Gap", "text_en": "Gap", "is_correct": false}
 ]'::jsonb,
 2, 'Padding widget يضيف مسافة داخلية حول الـ child', 'Padding widget adds internal spacing around its child', 2),

(v_quiz2_id,
 'Container يمكنه أن يحتوي على child واحد فقط',
 'Container can only have one child',
 'true_false',
 '[
   {"id": "true", "text_ar": "صح", "text_en": "True", "is_correct": true},
   {"id": "false", "text_ar": "خطأ", "text_en": "False", "is_correct": false}
 ]'::jsonb,
 2, 'Container يقبل child واحد فقط، استخدم Column أو Row لعدة عناصر', 'Container accepts only one child, use Column or Row for multiple items', 3),

(v_quiz2_id,
 'أي من التالي يُستخدم للتنقل بين الشاشات؟',
 'Which of the following is used for navigation between screens?',
 'single',
 '[
   {"id": "a", "text_ar": "Navigator", "text_en": "Navigator", "is_correct": true},
   {"id": "b", "text_ar": "Router", "text_en": "Router", "is_correct": false},
   {"id": "c", "text_ar": "Screen", "text_en": "Screen", "is_correct": false},
   {"id": "d", "text_ar": "Page", "text_en": "Page", "is_correct": false}
 ]'::jsonb,
 2, 'Navigator هو الـ widget الأساسي للتنقل في Flutter', 'Navigator is the basic widget for navigation in Flutter', 4);


-- Quiz 3: Advanced Flutter Quiz (Course Level)
INSERT INTO quizzes (
  lesson_id, course_id, 
  title_ar, title_en, 
  description_ar, description_en,
  passing_score, time_limit, max_attempts,
  shuffle_questions, shuffle_answers, show_correct_answers,
  total_questions, total_points, is_published, is_mandatory
) VALUES (
  NULL,
  v_course_id,
  'اختبار Flutter المتقدم',
  'Advanced Flutter Quiz',
  'اختبار للمفاهيم المتقدمة في Flutter',
  'Quiz for advanced Flutter concepts',
  80, 20, 2,
  true, true, true,
  5, 15, true, true
) RETURNING id INTO v_quiz3_id;

-- Quiz 3 Questions
INSERT INTO quiz_questions (quiz_id, question_ar, question_en, question_type, options, points, explanation_ar, explanation_en, sort_order) VALUES
(v_quiz3_id,
 'ما هو الـ BuildContext في Flutter؟',
 'What is BuildContext in Flutter?',
 'single',
 '[
   {"id": "a", "text_ar": "متغير عام", "text_en": "Global variable", "is_correct": false},
   {"id": "b", "text_ar": "موقع الـ Widget في شجرة الـ Widgets", "text_en": "Location of Widget in the Widget tree", "is_correct": true},
   {"id": "c", "text_ar": "نوع من الـ State", "text_en": "Type of State", "is_correct": false},
   {"id": "d", "text_ar": "طريقة للـ Navigation", "text_en": "Navigation method", "is_correct": false}
 ]'::jsonb,
 3, 'BuildContext يمثل موقع الـ Widget في شجرة الـ Widgets', 'BuildContext represents the location of a Widget in the Widget tree', 1),

(v_quiz3_id,
 'أي من التالي صحيح عن Future في Dart؟',
 'Which of the following is correct about Future in Dart?',
 'multiple',
 '[
   {"id": "a", "text_ar": "يمثل عملية غير متزامنة", "text_en": "Represents an asynchronous operation", "is_correct": true},
   {"id": "b", "text_ar": "يمكن استخدام await معه", "text_en": "Can use await with it", "is_correct": true},
   {"id": "c", "text_ar": "يُرجع قيمة فوراً", "text_en": "Returns value immediately", "is_correct": false},
   {"id": "d", "text_ar": "يمكن أن يكون له حالة completed أو error", "text_en": "Can have completed or error state", "is_correct": true}
 ]'::jsonb,
 3, 'Future يمثل عملية غير متزامنة قد تكتمل بنجاح أو بخطأ', 'Future represents an async operation that may complete successfully or with error', 2),

(v_quiz3_id,
 'ما الفرق بين hot reload و hot restart؟',
 'What is the difference between hot reload and hot restart?',
 'single',
 '[
   {"id": "a", "text_ar": "لا يوجد فرق", "text_en": "No difference", "is_correct": false},
   {"id": "b", "text_ar": "hot reload يحافظ على الـ state", "text_en": "hot reload preserves state", "is_correct": true},
   {"id": "c", "text_ar": "hot restart أسرع", "text_en": "hot restart is faster", "is_correct": false},
   {"id": "d", "text_ar": "hot reload يعيد تشغيل التطبيق", "text_en": "hot reload restarts the app", "is_correct": false}
 ]'::jsonb,
 3, 'hot reload يحافظ على حالة التطبيق، بينما hot restart يعيد تهيئة الحالة', 'hot reload preserves app state, while hot restart reinitializes state', 3),

(v_quiz3_id,
 'InheritedWidget يُستخدم لـ:',
 'InheritedWidget is used for:',
 'single',
 '[
   {"id": "a", "text_ar": "الرسوم المتحركة", "text_en": "Animations", "is_correct": false},
   {"id": "b", "text_ar": "مشاركة البيانات عبر شجرة الـ Widgets", "text_en": "Sharing data across Widget tree", "is_correct": true},
   {"id": "c", "text_ar": "التنقل", "text_en": "Navigation", "is_correct": false},
   {"id": "d", "text_ar": "إدارة الملفات", "text_en": "File management", "is_correct": false}
 ]'::jsonb,
 3, 'InheritedWidget يسمح بمشاركة البيانات مع الـ descendants بكفاءة', 'InheritedWidget allows efficient data sharing with descendants', 4),

(v_quiz3_id,
 'dispose() method يُستدعى عندما:',
 'dispose() method is called when:',
 'single',
 '[
   {"id": "a", "text_ar": "يتم إنشاء الـ Widget", "text_en": "Widget is created", "is_correct": false},
   {"id": "b", "text_ar": "يتم تحديث الـ Widget", "text_en": "Widget is updated", "is_correct": false},
   {"id": "c", "text_ar": "يتم إزالة الـ Widget من الشجرة نهائياً", "text_en": "Widget is permanently removed from tree", "is_correct": true},
   {"id": "d", "text_ar": "يتم بناء الـ Widget", "text_en": "Widget is built", "is_correct": false}
 ]'::jsonb,
 3, 'dispose() يُستدعى لتنظيف الموارد عند إزالة الـ State نهائياً', 'dispose() is called to clean up resources when State is permanently removed', 5);

-- Output created quiz IDs
RAISE NOTICE 'Quiz 1 (Basics) ID: %', v_quiz1_id;
RAISE NOTICE 'Quiz 2 (UI) ID: %', v_quiz2_id;
RAISE NOTICE 'Quiz 3 (Advanced) ID: %', v_quiz3_id;

END $$;

-- Verify
SELECT q.title_en, q.total_questions, COUNT(qq.id) as actual_questions
FROM quizzes q
LEFT JOIN quiz_questions qq ON qq.quiz_id = q.id
WHERE q.course_id = 'cc100000-0000-4000-a000-000000000007'
GROUP BY q.id, q.title_en, q.total_questions;
