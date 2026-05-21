import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/portfolio_item_entity.dart';
import 'portfolio_empty_state.dart';

/// Portfolio Achievements Tab Widget
class PortfolioAchievementsTab extends StatelessWidget {
  final List<PortfolioAchievementEntity> achievements;
  final bool isDark;

  const PortfolioAchievementsTab({
    super.key,
    required this.achievements,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return PortfolioEmptyState(
        title: 'No achievements yet',
        subtitle: 'Complete courses and challenges to earn achievements',
        icon: Icons.emoji_events_outlined,
        isDark: isDark,
      );
    }

    final unlockedAchievements =
        achievements.where((a) => a.isUnlocked).toList();
    final lockedAchievements =
        achievements.where((a) => !a.isUnlocked).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (unlockedAchievements.isNotEmpty) ...[
          _buildSectionTitle('Unlocked'),
          const SizedBox(height: 12),
          _buildAchievementsGrid(unlockedAchievements),
        ],
        if (lockedAchievements.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionTitle('In Progress'),
          const SizedBox(height: 12),
          _buildAchievementsGrid(lockedAchievements),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.white : AppColors.textMainLight,
      ),
    );
  }

  Widget _buildAchievementsGrid(List<PortfolioAchievementEntity> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(items[index]);
      },
    );
  }

  Widget _buildAchievementCard(PortfolioAchievementEntity achievement) {
    final isLocked = !achievement.isUnlocked;
    final iconColor = _getIconColor(achievement.iconName, isLocked);
    final bgColor = _getIconBgColor(achievement.iconName, isLocked);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.grey700 : AppColors.grey100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: isLocked ? 0.7 : 1.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconData(achievement.iconName),
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              achievement.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.textMainLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              achievement.description,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.grey400 : AppColors.grey500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isLocked && achievement.target > 1) ...[
              const SizedBox(height: 8),
              _buildProgressBar(achievement),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(PortfolioAchievementEntity achievement) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: achievement.progressPercentage,
            backgroundColor: isDark ? AppColors.grey700 : AppColors.grey200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${achievement.progress}/${achievement.target}',
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppColors.grey500 : AppColors.grey400,
          ),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'military_tech':
        return Icons.military_tech;
      case 'electric_bolt':
        return Icons.electric_bolt;
      case 'auto_stories':
        return Icons.auto_stories;
      case 'trophy':
        return Icons.emoji_events;
      default:
        return Icons.star;
    }
  }

  Color _getIconColor(String iconName, bool isLocked) {
    if (isLocked) return AppColors.grey400;

    switch (iconName) {
      case 'military_tech':
        return Colors.amber.shade600;
      case 'electric_bolt':
        return Colors.blue.shade600;
      case 'auto_stories':
        return Colors.purple.shade600;
      case 'trophy':
        return Colors.orange.shade600;
      default:
        return AppColors.primary;
    }
  }

  Color _getIconBgColor(String iconName, bool isLocked) {
    if (isLocked) {
      return isDark ? AppColors.grey700 : AppColors.grey100;
    }

    switch (iconName) {
      case 'military_tech':
        return isDark
            ? Colors.amber.shade900.withValues(alpha: 0.3)
            : Colors.amber.shade100;
      case 'electric_bolt':
        return isDark
            ? Colors.blue.shade900.withValues(alpha: 0.3)
            : Colors.blue.shade100;
      case 'auto_stories':
        return isDark
            ? Colors.purple.shade900.withValues(alpha: 0.3)
            : Colors.purple.shade100;
      case 'trophy':
        return isDark
            ? Colors.orange.shade900.withValues(alpha: 0.3)
            : Colors.orange.shade100;
      default:
        return isDark
            ? AppColors.primary.withValues(alpha: 0.2)
            : AppColors.primary.withValues(alpha: 0.1);
    }
  }
}
