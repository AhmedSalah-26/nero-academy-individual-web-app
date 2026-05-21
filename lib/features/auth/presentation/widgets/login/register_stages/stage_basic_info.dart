import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/validators.dart';
import '../auth_text_field.dart';

class StageBasicInfo extends StatelessWidget {
  final TextEditingController nameCtrl;
  final bool isDark;

  const StageBasicInfo({
    super.key,
    required this.nameCtrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'auth.whats_your_name'.tr(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'auth.name_subtitle'.tr(),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.grey400 : AppColors.grey500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        AuthTextField(
          controller: nameCtrl,
          label: 'auth.name'.tr(),
          hint: 'auth.name_placeholder'.tr(),
          icon: Icons.person_outline_rounded,
          validator: (v) =>
              Validators.required(v, message: 'auth.name_required'.tr()),
          isDark: isDark,
        ),
      ],
    );
  }
}
