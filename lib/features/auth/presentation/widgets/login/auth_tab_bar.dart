import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class AuthTabBar extends StatelessWidget {
  final bool isLogin;
  final String loginLabel;
  final String registerLabel;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const AuthTabBar({
    super.key,
    required this.isLogin,
    required this.loginLabel,
    required this.registerLabel,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTab(loginLabel, isLogin, () => onChanged(true)),
          _buildTab(registerLabel, !isLogin, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.cardDark : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.grey400 : AppColors.grey500),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
