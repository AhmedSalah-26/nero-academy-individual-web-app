import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Auth Tab Switcher - Toggle between Login and Sign Up
class AuthTabSwitcher extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onChanged;

  const AuthTabSwitcher({
    super.key,
    required this.isLogin,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.grey800.withValues(alpha: 0.5)
            : AppColors.grey200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Login Tab
          Expanded(
            child: _TabButton(
              label: 'تسجيل الدخول',
              isSelected: isLogin,
              onTap: () => onChanged(true),
            ),
          ),
          // Sign Up Tab
          Expanded(
            child: _TabButton(
              label: 'إنشاء حساب',
              isSelected: !isLogin,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.grey700 : AppColors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.grey400 : AppColors.grey500),
            ),
          ),
        ),
      ),
    );
  }
}
