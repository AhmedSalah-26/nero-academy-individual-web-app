import 'package:flutter/material.dart';
import 'stats_card.dart';

/// Stats Card Data Model
class StatsCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final double? changePercentage;
  final VoidCallback? onTap;

  const StatsCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.changePercentage,
    this.onTap,
  });
}

/// Stats Grid - Responsive grid of stats cards
/// Columns: 4 (large >= 1200), 3 (medium >= 768), 2 (small < 768)
class StatsGrid extends StatelessWidget {
  final List<StatsCardData> stats;
  final bool isLoading;
  final int loadingCount;

  // Breakpoints
  static const double largeBreakpoint = 1200;
  static const double mediumBreakpoint = 768;

  const StatsGrid({
    super.key,
    required this.stats,
    this.isLoading = false,
    this.loadingCount = 6,
  });

  int _getColumnCount(double width) {
    if (width >= largeBreakpoint) return 4;
    if (width >= mediumBreakpoint) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = _getColumnCount(constraints.maxWidth);
        const spacing = 16.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columnCount - 1))) /
                columnCount;

        final items =
            isLoading ? List.generate(loadingCount, (_) => null) : stats;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((data) {
            return SizedBox(
              width: itemWidth,
              child: data == null
                  ? const StatsCard(
                      title: '',
                      value: '',
                      icon: Icons.analytics,
                      isLoading: true,
                    )
                  : StatsCard(
                      title: data.title,
                      value: data.value,
                      icon: data.icon,
                      color: data.color,
                      subtitle: data.subtitle,
                      changePercentage: data.changePercentage,
                      onTap: data.onTap,
                    ),
            );
          }).toList(),
        );
      },
    );
  }
}
