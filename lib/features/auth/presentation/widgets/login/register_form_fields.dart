import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/shared_widgets/phone_input_field.dart';
import '../../../domain/entities/user_entity.dart';
import 'auth_text_field.dart';
import 'avatar_picker.dart';
import 'instructor_fields.dart';
import 'role_card.dart';

class RegisterFormFields extends StatefulWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController? headlineCtrl;
  final TextEditingController? bioCtrl;
  final TextEditingController? expertiseCtrl;
  final Uint8List? avatarBytes;
  final VoidCallback? onPickAvatar;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;
  final bool isDark;
  final ValueChanged<String>? onCountryCodeChanged;

  const RegisterFormFields({
    super.key,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    this.headlineCtrl,
    this.bioCtrl,
    this.expertiseCtrl,
    this.avatarBytes,
    this.onPickAvatar,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.isDark,
    this.onCountryCodeChanged,
  });

  @override
  State<RegisterFormFields> createState() => _RegisterFormFieldsState();
}

class _RegisterFormFieldsState extends State<RegisterFormFields> {
  String _countryDialCode = '+20';

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Avatar Picker
      if (widget.onPickAvatar != null) ...[
        Center(
          child: AvatarPicker(
            imageBytes: widget.avatarBytes,
            onTap: widget.onPickAvatar!,
            isDark: widget.isDark,
          ),
        ),
        const SizedBox(height: 20),
      ],
      // Role Selection
      Text('auth.i_am_a'.tr(),
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.isDark ? AppColors.grey300 : AppColors.grey700)),
      const SizedBox(height: 12),
      _buildRoleSelector(),
      const SizedBox(height: 20),
      // Name Field
      AuthTextField(
          controller: widget.nameCtrl,
          label: 'auth.name'.tr(),
          hint: 'auth.name_placeholder'.tr(),
          icon: Icons.person_outline_rounded,
          validator: (v) =>
              Validators.required(v, message: 'auth.name_required'.tr()),
          isDark: widget.isDark),
      const SizedBox(height: 16),
      // Phone Field with Country Code
      PhoneInputField(
        controller: widget.phoneCtrl,
        label: 'auth.phone'.tr(),
        onCountryCodeChanged: (code) {
          _countryDialCode = code;
          widget.onCountryCodeChanged?.call(code);
        },
      ),
      const SizedBox(height: 16),
      // Email Field
      AuthTextField(
          controller: widget.emailCtrl,
          label: 'auth.email'.tr(),
          hint: 'auth.email_placeholder'.tr(),
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
          isDark: widget.isDark),
      const SizedBox(height: 16),
      // Password Field
      AuthTextField(
        controller: widget.passCtrl,
        label: 'auth.password'.tr(),
        hint: 'auth.create_password_placeholder'.tr(),
        icon: Icons.lock_outline_rounded,
        obscureText: widget.obscurePassword,
        isDark: widget.isDark,
        suffixIcon: IconButton(
            icon: Icon(
                widget.obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AppColors.grey400),
            onPressed: widget.onToggleObscure),
        validator: (v) => Validators.password(v, minLength: 8),
      ),
      const SizedBox(height: 8),
      Text('auth.password_hint'.tr(),
          style: const TextStyle(fontSize: 12, color: AppColors.grey400)),
      // Role-specific fields
      if (widget.selectedRole == UserRole.instructor &&
          widget.headlineCtrl != null &&
          widget.bioCtrl != null &&
          widget.expertiseCtrl != null)
        InstructorFields(
          headlineCtrl: widget.headlineCtrl!,
          bioCtrl: widget.bioCtrl!,
          expertiseCtrl: widget.expertiseCtrl!,
          isDark: widget.isDark,
        ),
    ]);
  }

  Widget _buildRoleSelector() {
    return LayoutBuilder(builder: (_, c) {
      final s = (c.maxWidth - 12) / 2;
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        RoleCard(
            role: UserRole.instructor,
            selectedRole: widget.selectedRole,
            icon: Icons.cast_for_education_rounded,
            label: 'auth.role_instructor'.tr(),
            isDark: widget.isDark,
            size: s,
            onTap: () => widget.onRoleChanged(UserRole.instructor)),
        const SizedBox(width: 12),
        RoleCard(
            role: UserRole.student,
            selectedRole: widget.selectedRole,
            icon: Icons.school_rounded,
            label: 'auth.role_student'.tr(),
            isDark: widget.isDark,
            size: s,
            onTap: () => widget.onRoleChanged(UserRole.student)),
      ]);
    });
  }

  /// الحصول على رقم الهاتف الكامل مع كود الدولة
  String getFullPhoneNumber() {
    final phone = widget.phoneCtrl.text.trim();
    if (phone.isEmpty) return '';
    // إزالة الصفر الأول لو موجود
    final cleanPhone = phone.startsWith('0') ? phone.substring(1) : phone;
    return '$_countryDialCode$cleanPhone';
  }
}
