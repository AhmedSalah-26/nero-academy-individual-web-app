import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final double borderRadius;
  final bool hasNotification;
  final int? badgeCount;
  final bool compactBadge;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 40,
    this.iconSize = 22,
    this.borderRadius = 14,
    this.hasNotification = false,
    this.badgeCount,
    this.compactBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final numberBadgeScale = compactBadge ? 0.78 : 1.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark.withValues(alpha: 0.92)
                        : Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: isDark ? AppColors.textMainDark : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasNotification || (badgeCount != null && badgeCount! > 0))
          Positioned(
            top: size * 0.08,
            right: size * 0.08,
            child: Container(
              padding: badgeCount != null
                  ? EdgeInsets.symmetric(
                      horizontal: size * 0.09 * numberBadgeScale,
                      vertical: size * 0.02 * numberBadgeScale,
                    )
                  : EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: size * 0.17 * numberBadgeScale,
                minHeight: size * 0.17 * numberBadgeScale,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius:
                    BorderRadius.circular(size * 0.18 * numberBadgeScale),
                border: Border.all(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  width: compactBadge ? 1.2 : 1.5,
                ),
              ),
              child: badgeCount != null
                  ? Text(
                      '$badgeCount',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize:
                            (size * 0.22 * numberBadgeScale).clamp(7.0, 10.0),
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}
