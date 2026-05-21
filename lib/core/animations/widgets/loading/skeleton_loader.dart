import 'package:flutter/material.dart';

/// Skeleton loader widget
/// Displays a placeholder shape during content loading
class SkeletonLoader extends StatelessWidget {
  /// Width of the skeleton
  final double width;

  /// Height of the skeleton
  final double height;

  /// Border radius for rounded corners
  final BorderRadius? borderRadius;

  /// Whether the skeleton is enabled (visible)
  final bool enabled;

  /// Base color of the skeleton
  final Color? baseColor;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.enabled = true,
    this.baseColor,
  });

  /// Create a circular skeleton (for avatars, icons)
  factory SkeletonLoader.circular({
    Key? key,
    required double size,
    bool enabled = true,
    Color? baseColor,
  }) {
    return SkeletonLoader(
      key: key,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
      enabled: enabled,
      baseColor: baseColor,
    );
  }

  /// Create a rectangular skeleton with rounded corners
  factory SkeletonLoader.rounded({
    Key? key,
    required double width,
    required double height,
    double radius = 8.0,
    bool enabled = true,
    Color? baseColor,
  }) {
    return SkeletonLoader(
      key: key,
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(radius),
      enabled: enabled,
      baseColor: baseColor,
    );
  }

  /// Create a text line skeleton
  factory SkeletonLoader.text({
    Key? key,
    double width = double.infinity,
    double height = 16.0,
    bool enabled = true,
    Color? baseColor,
  }) {
    return SkeletonLoader(
      key: key,
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(4.0),
      enabled: enabled,
      baseColor: baseColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return SizedBox(width: width, height: height);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveBaseColor =
        baseColor ?? (isDark ? Colors.grey[800]! : const Color(0xFFE0E0E0));

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: effectiveBaseColor,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Skeleton card widget
/// Pre-configured skeleton for card layouts
class SkeletonCard extends StatelessWidget {
  /// Whether to show an image placeholder
  final bool hasImage;

  /// Image height
  final double imageHeight;

  /// Number of text lines
  final int lines;

  /// Whether the skeleton is enabled
  final bool enabled;

  const SkeletonCard({
    super.key,
    this.hasImage = true,
    this.imageHeight = 200.0,
    this.lines = 3,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImage)
          SkeletonLoader(
            width: double.infinity,
            height: imageHeight,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLoader.text(width: double.infinity, height: 20),
              const SizedBox(height: 8),
              ...List.generate(
                lines,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SkeletonLoader.text(
                    width: index == lines - 1
                        ? MediaQuery.of(context).size.width * 0.6
                        : double.infinity,
                    height: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Skeleton list item widget
/// Pre-configured skeleton for list items
class SkeletonListItem extends StatelessWidget {
  /// Whether to show a leading avatar
  final bool hasLeading;

  /// Whether to show a trailing widget
  final bool hasTrailing;

  /// Number of text lines
  final int lines;

  /// Whether the skeleton is enabled
  final bool enabled;

  const SkeletonListItem({
    super.key,
    this.hasLeading = true,
    this.hasTrailing = false,
    this.lines = 2,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          if (hasLeading) ...[
            SkeletonLoader.circular(size: 48),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                lines,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SkeletonLoader.text(
                    width: index == 0
                        ? double.infinity
                        : MediaQuery.of(context).size.width * 0.7,
                    height: index == 0 ? 16 : 14,
                  ),
                ),
              ),
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: 16),
            SkeletonLoader.rounded(width: 60, height: 32, radius: 16),
          ],
        ],
      ),
    );
  }
}
