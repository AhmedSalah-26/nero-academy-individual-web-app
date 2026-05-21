-- تعيين رقم الهاتف +2001142043116 كولي أمر لجميع حسابات الطلاب لاختبار بوابة ولي الأمر
UPDATE public.profiles
SET parent_phone = '+2001142043116'
WHERE role = 'student';
