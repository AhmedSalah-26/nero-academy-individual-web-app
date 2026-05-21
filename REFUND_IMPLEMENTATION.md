# تنفيذ نظام الاسترداد (Refund Implementation)

## التغييرات المنفذة

### 1. قاعدة البيانات (Database)

تم إنشاء ملف SQL جديد: `database_scripts/350_process_refund_function.sql`

#### الوظيفة الرئيسية: `process_refund`

```sql
process_refund(p_enrollment_id UUID, p_reason TEXT)
```

**ما تفعله الوظيفة:**

1. تحديث حالة التسجيل إلى `refunded`
2. إنشاء معاملة أرباح سالبة للمدرس في جدول `earnings_transactions`
3. خصم المبلغ من رصيد المدرس المتاح في `instructor_balance`

**التفاصيل:**
- المبلغ المسترد يظهر كقيمة سالبة في أرباح المدرس
- العمولة أيضاً تظهر كقيمة سالبة
- نوع المصدر يكون `refund` بدلاً من `course_sale`
- يتم خصم المبلغ من `available_balance` و `total_earnings`

### 2. واجهة المستخدم (UI)

#### أ. عرض الأرباح للمدرس

تم تحديث ملف: `lib/features/instructor_dashboard/presentation/widgets/instructor_earnings/earnings_list_widgets.dart`

**التحسينات:**
- عرض الاسترداد بلون أحمر (error color) بدلاً من الأخضر
- إضافة علامة `-` قبل المبلغ للاسترداد
- إضافة أيقونة `money_off_rounded` للاسترداد
- إضافة شارة "استرداد" / "Refund" بجانب اسم الكورس
- استخدام `abs()` لعرض القيم المطلقة بشكل صحيح

**مثال على العرض:**
```
❌ [أيقونة استرداد] اسم الكورس [شارة: استرداد]
   التاريخ | الحالة
   -500 ج.م  (باللون الأحمر)
```

#### ب. إصلاح الوضع الداكن والخطوط

تم تحديث ملف: `lib/features/admin_dashboard/presentation/widgets/admin_instructor_requests/admin_instructor_requests_content.dart`

**التحسينات:**
- إضافة دعم كامل للوضع الداكن (Dark Mode)
- استخدام الألوان المناسبة حسب الثيم:
  - `AppColors.textMainDark` / `AppColors.textMainLight` للنصوص الرئيسية
  - `AppColors.textMutedDark` / `AppColors.textMutedLight` للنصوص الثانوية
  - `AppColors.cardDark` / `AppColors.white` للبطاقات
  - `AppColors.borderDark` / `AppColors.borderLight` للحدود
  - `AppColors.surfaceDark` / `AppColors.grey100` للخلفيات
- تطبيق الخط `Almarai` بشكل صحيح عبر الثيم

### 3. كيفية الاستخدام

#### تشغيل السكريبت في قاعدة البيانات:

```bash
# في Supabase SQL Editor
-- قم بتشغيل الملف:
database_scripts/350_process_refund_function.sql
```

#### معالجة الاسترداد من لوحة الأدمن:

1. اذهب إلى صفحة التسجيلات (Enrollments)
2. اختر التسجيل المراد استرداده
3. اضغط على زر "استرداد" / "Refund"
4. أدخل سبب الاسترداد
5. تأكيد العملية

#### ما يحدث تلقائياً:

1. ✅ تحديث حالة التسجيل إلى `refunded`
2. ✅ إنشاء معاملة سالبة في أرباح المدرس
3. ✅ خصم المبلغ من رصيد المدرس
4. ✅ ظهور الاسترداد في لوحة تحكم المدرس باللون الأحمر
5. ✅ تحديث الإحصائيات والرسوم البيانية

### 4. الاختبار

#### اختبار الاسترداد:

```sql
-- 1. إنشاء تسجيل تجريبي
INSERT INTO enrollments (user_id, course_id, instructor_id, amount_paid, status)
VALUES ('user-id', 'course-id', 'instructor-id', 500, 'active');

-- 2. معالجة الاسترداد
SELECT process_refund('enrollment-id', 'طلب العميل');

-- 3. التحقق من النتائج
SELECT * FROM enrollments WHERE id = 'enrollment-id';
SELECT * FROM earnings_transactions WHERE course_id = 'course-id' AND source_type = 'refund';
SELECT * FROM instructor_balance WHERE instructor_id = 'instructor-id';
```

### 5. الملاحظات المهمة

⚠️ **تحذيرات:**
- لا يمكن استرداد تسجيل مسترد مسبقاً
- الاسترداد يؤثر فوراً على رصيد المدرس
- إذا كان رصيد المدرس أقل من المبلغ المسترد، سيصبح الرصيد سالباً

✅ **مميزات:**
- تتبع كامل لجميع عمليات الاسترداد
- ظهور واضح في لوحة تحكم المدرس
- دعم كامل للوضع الداكن
- واجهة مستخدم متسقة مع باقي التطبيق

### 6. الملفات المعدلة

```
database_scripts/
  └── 350_process_refund_function.sql (جديد)

lib/features/instructor_dashboard/presentation/widgets/instructor_earnings/
  └── earnings_list_widgets.dart (محدث)

lib/features/admin_dashboard/presentation/widgets/admin_instructor_requests/
  └── admin_instructor_requests_content.dart (محدث)
```

## الخطوات التالية (اختياري)

1. إضافة إشعارات للمدرس عند حدوث استرداد
2. إضافة تقرير شامل بجميع عمليات الاسترداد
3. إضافة إمكانية الاسترداد الجزئي
4. إضافة فترة سماح قبل خصم المبلغ من رصيد المدرس

---

تم التنفيذ بنجاح ✅
