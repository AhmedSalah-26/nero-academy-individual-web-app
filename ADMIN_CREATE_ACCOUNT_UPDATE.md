# تحديث نموذج إنشاء حساب المدرس

## التغييرات المطلوبة

استبدل دالة `_openCreateAccountDialog` في ملف:
`lib/features/admin_dashboard/presentation/widgets/admin_instructor_requests/admin_instructor_requests_content.dart`

بالكود التالي:

```dart
  Future<void> _openCreateAccountDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    var selectedAccountType = 'instructor';
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
              title: Text(
                _isArabic ? 'إنشاء حساب جديد' : 'Create New Account',
                style: TextStyle(
                  color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: _isArabic ? 'الاسم' : 'Name',
                          hintText: _isArabic ? 'أدخل الاسم الكامل' : 'Enter full name',
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (value) => Validators.required(
                          value,
                          message: _isArabic ? 'الاسم مطلوب' : 'Name is required',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: _isArabic ? 'البريد الإلكتروني' : 'Email',
                          hintText: 'example@email.com',
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: (value) => Validators.email(
                          value,
                          emptyMessage: _isArabic ? 'البريد الإلكتروني مطلوب' : 'Email is required',
                          invalidMessage: _isArabic ? 'البريد الإلكتروني غير صالح' : 'Invalid email address',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: _isArabic ? 'كلمة المرور' : 'Password',
                          hintText: _isArabic ? 'أدخل كلمة المرور' : 'Enter password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return _isArabic ? 'كلمة المرور مطلوبة' : 'Password is required';
                          }
                          if (value.length < 8) {
                            return _isArabic ? 'كلمة المرور يجب أن تكون 8 أحرف على الأقل' : 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: _isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password',
                          hintText: _isArabic ? 'أعد إدخال كلمة المرور' : 'Re-enter password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureConfirmPassword = !obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return _isArabic ? 'تأكيد كلمة المرور مطلوب' : 'Confirm password is required';
                          }
                          if (value != passwordController.text) {
                            return _isArabic ? 'كلمات المرور غير متطابقة' : 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedAccountType,
                        decoration: InputDecoration(
                          labelText: _isArabic ? 'نوع الحساب' : 'Account type',
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                        items: _accountTypes
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(_accountTypeLabel(type)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedAccountType = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(_isArabic ? 'إلغاء' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) return;
                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(_isArabic ? 'إنشاء' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldCreate != true) {
      nameController.dispose();
      emailController.dispose();
      passwordController.dispose();
      confirmPasswordController.dispose();
      return;
    }

    await _createAccount(
      name: nameController.text.trim(),
      email: emailController.text.trim().toLowerCase(),
      password: passwordController.text,
      accountType: selectedAccountType,
    );
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  // أضف هذه الدالة الجديدة بعد _openCreateAccountDialog
  Future<void> _createAccount({
    required String name,
    required String email,
    required String password,
    required String accountType,
  }) async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    try {
      // Check if user already exists
      final existingUser = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (existingUser != null) {
        ToastUtils.showError(
          _isArabic
              ? 'البريد الإلكتروني مستخدم بالفعل'
              : 'Email already exists',
        );
        return;
      }

      // Create user using Supabase Admin API
      final response = await _supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
          userMetadata: {
            'name': name,
            'role': accountType,
          },
        ),
      );

      if (response.user == null) {
        throw Exception('Failed to create user');
      }

      final userId = response.user!.id;

      // Update profile with additional info
      await _supabase.from('profiles').upsert({
        'id': userId,
        'name': name,
        'email': email,
        'role': accountType,
        'created_at': DateTime.now().toIso8601String(),
      });

      // If instructor, create instructor record
      if (accountType == 'instructor') {
        await _supabase.from('instructors').insert({
          'user_id': userId,
          'headline': '',
          'bio': '',
          'revenue_share': 70.0,
        });

        // Create instructor balance
        await _supabase.from('instructor_balance').insert({
          'instructor_id': userId,
          'available_balance': 0,
          'pending_balance': 0,
          'total_earnings': 0,
        });
      }

      ToastUtils.showSuccess(
        _isArabic
            ? 'تم إنشاء الحساب بنجاح'
            : 'Account created successfully',
      );
      
      await _loadRequests(showLoader: false);
    } on AuthException catch (e) {
      ToastUtils.showError(
        _isArabic
            ? 'فشل إنشاء الحساب: ${e.message}'
            : 'Failed to create account: ${e.message}',
      );
    } on PostgrestException catch (e) {
      ToastUtils.showError(
        _isArabic
            ? 'خطأ في قاعدة البيانات: ${e.message}'
            : 'Database error: ${e.message}',
      );
    } catch (e) {
      ToastUtils.showError(
        _isArabic
            ? 'حدث خطأ غير متوقع'
            : 'Unexpected error occurred',
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
```

## ملاحظات

1. النموذج الآن يطلب:
   - الاسم
   - البريد الإلكتروني
   - كلمة المرور
   - تأكيد كلمة المرور
   - نوع الحساب

2. يدعم الترجمة الكاملة للعربية والإنجليزية

3. يستخدم Supabase Admin API لإنشاء الحساب مباشرة

4. إذا كان الحساب مدرس، يتم إنشاء:
   - سجل في جدول instructors
   - سجل في جدول instructor_balance

5. التحقق من صحة البيانات:
   - كلمة المرور 8 أحرف على الأقل
   - تطابق كلمتي المرور
   - صحة البريد الإلكتروني
