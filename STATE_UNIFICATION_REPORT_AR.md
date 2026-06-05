# تقرير توحيد حالات التحميل والخطأ والفراغ

## الملخص

التطبيق عنده أساس مشترك جاهز:

- `lib/core/shared_widgets/error_state.dart`
- `lib/core/shared_widgets/empty_state.dart`
- `lib/core/shared_widgets/loading_skeleton.dart`
- `lib/core/base/base_state.dart`

لكن الاستخدام غير موحد بالكامل. بعض الشاشات تستخدم الودجتس المشتركة، وبعضها يستخدم `CircularProgressIndicator` مباشر، وبعض الفيتشرز عاملة نسخ محلية مثل `CartErrorState` و`WishlistErrorState` و`PlayerErrorState`.

الهدف: نخلي كل حالة full-screen أو section-level تمشي من نفس النظام، ونسيب الحالات الصغيرة داخل الأزرار والكروت لكن نوحد شكلها وتوكنز الألوان.

## حالة التنفيذ

- تم بدء تنفيذ توحيد أسلوب الخطأ.
- تم تحديث `ErrorState` ليكون production-ready مع دعم `fullPage`, `section`, `compact`.
- تم ربط النصوص بـ `easy_localization` عبر مفاتيح `error_state`.
- تم تحويل `CartErrorState` و`WishlistErrorState` لاستخدام `ErrorState` بدل تكرار UI محلي.
- تم تحويل أخطاء `CourseDetailsScreen` و`CourseSearchScreen` لاستخدام `ErrorState`.
- تم تحويل `payment_webview.dart` لاستخدام `ErrorState` داخل شاشة الدفع.
- تم تحويل `QuizInfoScreen` و`InstructorsScreen` لاستخدام `ErrorState`.
- تم تحويل `AttachmentPreviewScreen` لاستخدام `ErrorState`.
- تم تحويل `InstructorProfileScreen` لاستخدام `ErrorState`.
- تم إنشاء `AppLoadingState` لتوحيد حالات التحميل full-page/section/compact.
- تم إنشاء `AsyncStateView` لاستخدامه في الشاشات الجديدة أو التحويلات المستقبلية.
- تم تحويل حالات التحميل المباشرة في History, Settings, Profile, Quizzes, Course Player tabs/sheets, Course Forum, Instructor Dashboard, My Learning.
- تم تحويل empty states المحلية في Notes/Bookmarks/Quiz Info/Rating إلى `EmptyState`.
- تم إنهاء المسح المستهدف لـ full-screen/section `CircularProgressIndicator`؛ لم يعد هناك استخدام مباشر في المسارات التي تم فحصها.
- تم تنظيف ملاحظات `flutter analyze` على مستوى المشروع، وأصبح التحليل الكامل يمر بدون مشاكل.

## القاعدة المستهدفة

1. حالات الخطأ العامة تستخدم `ErrorState`.
2. حالات الفراغ العامة تستخدم `EmptyState`.
3. حالات التحميل الكبيرة تستخدم `LoadingSkeleton` أو wrapper مبني عليه.
4. الحالات الخاصة بالمشغل أو الدفع تفضل متخصصة، لكنها تعتمد بصريا على نفس الألوان والنصوص والأزرار.
5. ممنوع استخدام `Center(child: CircularProgressIndicator())` في شاشة كاملة إلا لو داخل wrapper موحد.

## ملفات الأساس المقترحة

| الملف | القرار |
| --- | --- |
| `lib/core/shared_widgets/error_state.dart` | نضيف دعم عربي افتراضي أو نربطه بالكامل بـ `easy_localization`، ونضيف `compact` و`inline` modes. |
| `lib/core/shared_widgets/empty_state.dart` | موجود وقوي، نضيف types ناقصة فقط بدل بناء empty محلي. |
| `lib/core/shared_widgets/loading_skeleton.dart` | نوسعه بـ `page`, `section`, `cardList`, `table`, `player` presets. |
| `lib/core/shared_widgets/async_state_view.dart` | ملف جديد مقترح يختار بين loading/error/empty/content بناء على state. |
| `lib/core/base/base_state.dart` | نخليه المرجع في Cubit states الجديدة، ولا نغير القديم دفعة واحدة. |

## خطة التنفيذ ملف بملف

### المرحلة 1: الأساس المشترك

| الأولوية | الملف | الوضع الحالي | المطلوب |
| --- | --- | --- | --- |
| عالية | `lib/core/shared_widgets/error_state.dart` | Unified لكن نصوصه الإنجليزية hardcoded | توحيد الترجمة، إضافة `compact`, `fullPage`, `inline`. |
| عالية | `lib/core/shared_widgets/empty_state.dart` | Unified ومستخدم في أكثر من مكان | إضافة types ناقصة مثل `payments`, `history`, `forumsManagement`, `attachmentsPreview`. |
| عالية | `lib/core/shared_widgets/loading_skeleton.dart` | Unified لكن presets قليلة | إضافة presets للشاشة، الجدول، المشغل، bottom sheet. |
| عالية | `lib/core/shared_widgets/async_state_view.dart` | غير موجود | إنشاء wrapper يقلل تكرار `if loading/error/empty`. |

### المرحلة 2: Course Player

| الأولوية | الملف | الوضع الحالي | المطلوب |
| --- | --- | --- | --- |
| عالية | `lib/features/course_player/presentation/widgets/course_player/player_states.dart` | Wrapper جيد فوق shared widgets | اعتباره المرجع الخاص بالمشغل، وتوحيد النصوص والألوان داخله. |
| عالية | `lib/features/course_player/presentation/screens/course_player_screen.dart` | يستخدم `PlayerErrorState` وبعض منطق خاص | ربط loading/error/empty كلها عبر `PlayerLoadingState` و`PlayerErrorState`. |
| عالية | `lib/features/course_player/presentation/widgets/course_player/video_player_section.dart` | حساس لأنه مدخل المشغل | أي failure للفيديو يظهر من `PlayerErrorState` وليس Snackbar أو نص عشوائي. |
| عالية | `lib/features/course_player/presentation/widgets/course_player/youtube_player_widget.dart` | مشغل خاص | توحيد loading/error visual فقط، بدون أي iframe bypass أو stream extraction. |
| عالية | `lib/features/course_player/presentation/widgets/course_player/direct_video_player_widget.dart` | يحتوي spinner مباشر | استبدال spinner الكبير بـ player loading preset. |
| متوسطة | `lib/features/course_player/presentation/screens/fullscreen_player_screen.dart` | spinner مباشر | توحيد loading overlay. |
| متوسطة | `lib/features/course_player/presentation/screens/attachment_preview_screen.dart` | error/loading محلي | استخدام `ErrorState` وloading preset للمعاينة. |
| متوسطة | `lib/features/course_player/presentation/widgets/course_player/notes_tab.dart` | spinner وempty محلي | استخدام `LoadingSkeleton.listItem` و`EmptyStateType.notes`. |
| متوسطة | `lib/features/course_player/presentation/widgets/course_player/bookmarks_tab.dart` | spinner وempty محلي | استخدام `LoadingSkeleton.listItem` و`EmptyStateType.bookmarks`. |
| متوسطة | `lib/features/course_player/presentation/widgets/course_player/notes_sheet.dart` | spinner مباشر + `EmptyState` | توحيد loading bottom sheet. |
| متوسطة | `lib/features/course_player/presentation/widgets/course_player/bookmarks_sheet.dart` | spinner مباشر + `EmptyState` | توحيد loading bottom sheet. |
| متوسطة | `lib/features/course_player/presentation/widgets/course_player/attachments_sheet.dart` | empty موجود | مراجعة type والرسالة فقط. |
| متوسطة | `lib/features/course_player/presentation/widgets/course_player/quizzes_section.dart` | spinner مباشر + empty | توحيد spinner وempty type. |
| متوسطة | `lib/features/course_player/presentation/widgets/course_player/qa_section.dart` | spinner مباشر + empty | توحيد spinner وempty type. |
| منخفضة | `lib/features/course_player/presentation/widgets/course_player/bottom_action_bar.dart` | loading داخل زر | يفضل يبقى داخل `AppButton` loading mode إن أمكن. |
| منخفضة | `lib/features/course_player/presentation/widgets/course_player/rating_section.dart` | spinners داخل sections | توحيد inline loading style فقط. |

### المرحلة 3: Cart و Wishlist

| الأولوية | الملف | الوضع الحالي | المطلوب |
| --- | --- | --- | --- |
| عالية | `lib/features/cart/presentation/widgets/cart/cart_error_state.dart` | نسخة محلية | تحويله wrapper بسيط حول `ErrorState` أو حذفه واستبداله مباشرة. |
| عالية | `lib/features/cart/presentation/widgets/cart/cart_empty_state.dart` | يستخدم `EmptyState` جزئيا | تخفيف الكود المحلي والاعتماد على `EmptyStateType.cart`. |
| عالية | `lib/features/cart/presentation/widgets/cart/cart_loading_state.dart` | Skeleton محلي | تحويله لاستخدام `LoadingSkeleton` presets. |
| عالية | `lib/features/cart/presentation/screens/cart_screen.dart` | يستخدم wrappers محلية | بعد توحيد wrappers يبقى نظيف. |
| متوسطة | `lib/features/cart/presentation/screens/checkout_screen.dart` | spinner مباشر | استخدام loading overlay/shared button loading. |
| متوسطة | `lib/features/cart/presentation/widgets/cart/coupon_section.dart` | spinner داخل زر | توحيده مع button loading. |
| عالية | `lib/features/wishlist/presentation/widgets/wishlist/wishlist_error_state.dart` | نسخة محلية | تحويله wrapper حول `ErrorState`. |
| عالية | `lib/features/wishlist/presentation/widgets/wishlist/wishlist_empty_state.dart` | wrapper بسيط | إبقاؤه أو استبداله بـ `EmptyStateType.wishlist`. |
| عالية | `lib/features/wishlist/presentation/widgets/wishlist/wishlist_loading_state.dart` | Skeleton محلي | تحويله إلى `LoadingSkeleton` preset. |
| متوسطة | `lib/features/wishlist/presentation/screens/wishlist_screen.dart` | يستخدم wrappers محلية | يبقى موحد بعد تحديث wrappers. |

### المرحلة 4: Course Details و Search و Home

| الأولوية | الملف | الوضع الحالي | المطلوب |
| --- | --- | --- | --- |
| عالية | `lib/features/course_details/presentation/screens/course_details_screen.dart` | loading/error مختلط حسب الشاشة | توحيد full page states. |
| عالية | `lib/features/course_details/presentation/widgets/course_details/course_details_skeleton.dart` | Skeleton متخصص | إبقاؤه لكن يبنى على `LoadingSkeleton` أو يصبح preset. |
| متوسطة | `lib/features/course_details/presentation/widgets/course_details/course_hero_section.dart` | spinner داخل صورة/hero | توحيد inline media loading. |
| متوسطة | `lib/features/course_details/presentation/widgets/course_details/bottom_price_bar.dart` | spinner داخل زر | استخدام `AppButton` loading. |
| عالية | `lib/features/course_search/presentation/screens/course_search_screen.dart` | error محلي + empty موحد | استبدال error المحلي بـ `ErrorState`. |
| متوسطة | `lib/features/course_search/presentation/widgets/course_search/search_skeleton_widget.dart` | Skeleton متخصص | تحويله preset أو يبقى wrapper فوق `LoadingSkeleton`. |
| متوسطة | `lib/features/home/presentation/widgets/home/home_loading_skeleton.dart` | Skeleton متخصص | تحويله wrapper فوق presets. |
| متوسطة | `lib/features/home/presentation/screens/home_screen.dart` | يستخدم `HomeLoadingSkeleton` | يبقى بعد توحيد الـ skeleton. |

### المرحلة 5: Forums و Chat

| الأولوية | الملف | الوضع الحالي | المطلوب |
| --- | --- | --- | --- |
| متوسطة | `lib/features/course_forum/presentation/screens/forum_chat_screen.dart` | يستخدم `ErrorState` و`EmptyState` | مراجعة النصوص فقط. |
| متوسطة | `lib/features/course_forum/presentation/screens/forums_list_screen.dart` | يستخدم shared لكن loading محلي | توحيد loading skeleton. |
| متوسطة | `lib/features/course_forum/presentation/screens/course_group_members_screen.dart` | spinner/error محلي | استخدام shared loading/error/empty. |
| متوسطة | `lib/features/course_forum/presentation/screens/course_forums_management_screen.dart` | spinner/error محلي | استخدام shared loading/error/empty. |
| منخفضة | `lib/features/direct_chat/presentation/screens/direct_chat_screen.dart` | يستخدم `ErrorState` | مراجعة loading/empty فقط. |
| منخفضة | `lib/features/direct_chat/presentation/widgets/direct_chat_messages_list.dart` | يستخدم `EmptyState` | جيد، مراجعة النصوص. |

### المرحلة 6: Payment و History و Notifications

| الأولوية | الملف | الوضع الحالي | المطلوب |
| --- | --- | --- | --- |
| عالية | `lib/features/payment/presentation/widgets/payment_webview.dart` | loading/error overlay محلي | توحيد visual states مع الحفاظ على خصوصية WebView. |
| متوسطة | `lib/features/payments_history/presentation/screens/payments_history_screen.dart` | spinner مباشر | استخدام loading page/list preset و`EmptyStateType.payments`. |
| متوسطة | `lib/features/history/presentation/screens/history_screen.dart` | spinner مباشر + `EmptyState` | استخدام loading preset. |
| متوسطة | `lib/features/notifications/presentation/screens/notifications_screen.dart` | يستخدم shared جزئيا | توحيد loading list. |

### المرحلة 7: Quizzes و Q&A

| الأولوية | الملف | الوضع الحالي | المطلوب |
| --- | --- | --- | --- |
| متوسطة | `lib/features/quizzes/presentation/screens/quiz_info_screen.dart` | error/empty محلي | استبدال بـ shared states. |
| متوسطة | `lib/features/quizzes/presentation/screens/quiz_question_screen.dart` | spinner + `ErrorState` | توحيد loading. |
| متوسطة | `lib/features/quizzes/presentation/screens/quiz_results_screen.dart` | spinner مباشر | استخدام loading preset. |
| منخفضة | `lib/features/quizzes/presentation/widgets/quiz_question/question_card.dart` | inline spinner | توحيد inline style فقط. |
| متوسطة | `lib/features/qa/presentation/screens/qa_screen.dart` | يستخدم `EmptyState` | مراجعة loading/error. |
| متوسطة | `lib/features/qa/presentation/screens/ask_question_screen.dart` | spinner داخل زر/submit | استخدام button loading موحد. |

### المرحلة 8: Settings و Auth

| الأولوية | الملف | الوضع الحالي | المطلوب |
| --- | --- | --- | --- |
| متوسطة | `lib/features/settings/presentation/screens/profile_screen.dart` | spinner + `ErrorState` | توحيد loading. |
| متوسطة | `lib/features/settings/presentation/screens/settings_screen.dart` | spinner مباشر | استخدام loading preset. |
| منخفضة | `lib/features/settings/presentation/screens/edit_profile_screen.dart` | spinner داخل زر | استخدام `AppButton` loading. |
| منخفضة | `lib/features/auth/presentation/screens/login_screen.dart` | spinners داخل أزرار | استخدام `AppButton` loading. |
| منخفضة | `lib/features/auth/presentation/screens/forgot_password_screen.dart` | spinner داخل زر | استخدام `AppButton` loading. |
| منخفضة | `lib/features/auth/presentation/screens/interests_selection_screen.dart` | spinner مباشر | توحيد loading/submit loading. |

### المرحلة 9: Instructor Dashboard

| الأولوية | الملف | الوضع الحالي | المطلوب |
| --- | --- | --- | --- |
| متوسطة | `lib/features/instructor_dashboard/presentation/widgets/instructor_courses/instructor_courses_content.dart` | skeleton محلي + spinners | توحيد loading skeleton والinline spinners. |
| متوسطة | `lib/features/instructor_dashboard/presentation/widgets/instructor_students/instructor_students_content.dart` | skeleton + dialog spinners | توحيد loading page/dialog. |
| متوسطة | `lib/features/instructor_dashboard/presentation/widgets/instructor_enrollments/instructor_enrollments_content.dart` | spinner/empty محلي | استخدام shared states. |
| متوسطة | `lib/features/instructor_dashboard/presentation/widgets/instructor_earnings/earnings_list_widgets.dart` | Empty متخصص | تحويله wrapper حول `EmptyState`. |
| متوسطة | `lib/features/instructor_dashboard/presentation/widgets/instructor_coupons/instructor_coupons_content.dart` | skeleton + spinner | توحيد. |
| منخفضة | `lib/features/instructor_dashboard/presentation/widgets/course_editor/*.dart` | spinners داخل dialogs/forms | توحيد button/dialog loading تدريجيا. |

### المرحلة 10: Core Widgets

| الأولوية | الملف | الوضع الحالي | المطلوب |
| --- | --- | --- | --- |
| عالية | `lib/core/shared_widgets/app_button.dart` | لديه loading spinner | اعتماده كمصدر رسمي لأزرار التحميل. |
| متوسطة | `lib/core/shared_widgets/dashboard/dashboard_data_table.dart` | يستخدم `EmptyState` و`LoadingSkeleton` + spinner داخلي | توحيد spinner الداخلي. |
| متوسطة | `lib/core/shared_widgets/dashboard/action_button.dart` | spinner داخلي | توحيده مع button loading style. |
| منخفضة | `lib/core/shared_widgets/report_screen.dart` | spinner مباشر | استخدام shared loading/error. |
| منخفضة | `lib/core/shared_widgets/report_dialog.dart` | spinner مباشر | توحيد dialog loading. |
| منخفضة | `lib/core/services/performance_service.dart` | lazy loading spinner | يبقى inline، لكن يستخدم loader موحد صغير. |

## قواعد التحويل

1. Full page loading:
   - استخدم `LoadingSkeleton` preset أو `AppLoadingState`.

2. Full page error:
   - استخدم `ErrorState(type, message, onRetry)`.

3. Empty list:
   - استخدم `EmptyState(type, onAction)`.

4. Button submit:
   - استخدم `AppButton(isLoading: true)` إن كان مدعوما، أو نضيف له support موحد.

5. Player/media loading:
   - استخدم `PlayerLoadingState` أو preset خاص بالميديا.

6. WebView/payment loading:
   - استخدم overlay موحد، لكن لا تخفي تفاصيل الدفع المهمة.

## ترتيب التنفيذ المقترح

1. تحديث ملفات الأساس المشتركة.
2. تحويل Course Player لأنه أكثر مكان ظاهر للمستخدم.
3. تحويل Cart و Wishlist لأن عندهم duplicate واضح.
4. تحويل Payment و Course Details.
5. تحويل Search و Home و Forums.
6. تحويل Quizzes و Settings و Auth.
7. تنظيف Instructor Dashboard و Core widgets.

## Checklist بعد كل ملف

- لا يوجد full-screen `CircularProgressIndicator` مباشر.
- الخطأ له رسالة واضحة وزر retry عندما ينفع.
- الفراغ له action مناسب أو رسالة واضحة.
- الشكل يعمل Light/Dark.
- النصوص عربية/مترجمة وليست hardcoded بدون سبب.
- لا يوجد wrapper محلي يكرر نفس `ErrorState` بدون قيمة إضافية.
- `flutter analyze` يمر بعد كل مجموعة ملفات.

## ملاحظات مهمة

- لا نحول كل شيء مرة واحدة، لأن ده هيعمل diff كبير وصعب مراجعته.
- نبدأ بالملفات التي تظهر للمستخدم النهائي: المشغل، الدفع، السلة، تفاصيل الكورس.
- الحالات الصغيرة داخل الأزرار ليست مشكلة إنتاجية كبيرة، لكنها تتنظف في مرحلة لاحقة.
- بعض الـ skeletons المتخصصة مفيدة؛ الأفضل تحويلها إلى wrappers فوق `LoadingSkeleton` بدل حذفها مباشرة.
