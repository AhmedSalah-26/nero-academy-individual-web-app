import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/user_entity.dart';
import 'signup_text_field.dart';

class SignupStep2 extends StatelessWidget {
  final TextEditingController headlineCtrl;
  final TextEditingController bioCtrl;
  final Uint8List? avatarBytes;
  final UserRole selectedRole;
  final bool isDark;
  final VoidCallback onPickAvatar;

  const SignupStep2({
    super.key,
    required this.headlineCtrl,
    required this.bioCtrl,
    required this.avatarBytes,
    required this.selectedRole,
    required this.isDark,
    required this.onPickAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'auth.complete_profile'.tr(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'auth.signup_step2_subtitle'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.grey400 : AppColors.grey500,
            ),
          ),
          const SizedBox(height: 32),

          // Avatar picker
          Center(
            child: GestureDetector(
              onTap: onPickAvatar,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.grey800 : AppColors.grey100,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                child: avatarBytes != null
                    ? ClipOval(
                        child: Image.memory(avatarBytes!, fit: BoxFit.cover))
                    : Icon(
                        Icons.add_a_photo_outlined,
                        size: 40,
                        color: isDark ? AppColors.grey400 : AppColors.grey500,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'auth.tap_to_upload_photo'.tr(),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.grey400 : AppColors.grey500,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Instructor-only fields
          if (selectedRole == UserRole.instructor) ...[
            SignupTextField(
              controller: headlineCtrl,
              label: 'auth.headline'.tr(),
              hint: 'auth.headline_placeholder'.tr(),
              icon: Icons.title_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            SignupTextField(
              controller: bioCtrl,
              label: 'auth.bio'.tr(),
              hint: 'auth.bio_placeholder'.tr(),
              icon: Icons.description_outlined,
              maxLines: 4,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
          ],

          if (selectedRole == UserRole.student)
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        ],
      ),
    );
  }
}
