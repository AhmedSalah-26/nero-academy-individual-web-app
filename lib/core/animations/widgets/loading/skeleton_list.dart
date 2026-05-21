import 'package:flutter/material.dart';
import 'skeleton_loader.dart';
import 'shimmer_effect.dart';

/// Skeleton list widget
/// Displays a list of skeleton items with shimmer effect
class SkeletonList extends StatelessWidget {
  /// Number of skeleton items to display
  final int itemCount;

  /// Builder for each skeleton item
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Padding around the list
  final EdgeInsets? padding;

  /// Whether to enable shimmer effect
  final bool enableShimmer;

  /// Whether the skeleton is enabled
  final bool enabled;

  const SkeletonList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.enableShimmer = true,
    this.enabled = true,
  });

  /// Create a skeleton list with default list items
  factory SkeletonList.defaultList({
    Key? key,
    int itemCount = 5,
    bool hasLeading = true,
    bool hasTrailing = false,
    int lines = 2,
    EdgeInsets? padding,
    bool enableShimmer = true,
    bool enabled = true,
  }) {
    return SkeletonList(
      key: key,
      itemCount: itemCount,
      padding: padding,
      enableShimmer: enableShimmer,
      enabled: enabled,
      itemBuilder: (context, index) {
        return SkeletonListItem(
          hasLeading: hasLeading,
          hasTrailing: hasTrailing,
          lines: lines,
        );
      },
    );
  }

  /// Create a skeleton list with card items
  factory SkeletonList.cards({
    Key? key,
    int itemCount = 3,
    bool hasImage = true,
    double imageHeight = 200.0,
    int lines = 3,
    EdgeInsets? padding,
    bool enableShimmer = true,
    bool enabled = true,
  }) {
    return SkeletonList(
      key: key,
      itemCount: itemCount,
      padding: padding,
      enableShimmer: enableShimmer,
      enabled: enabled,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: SkeletonCard(
            hasImage: hasImage,
            imageHeight: imageHeight,
            lines: lines,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const SizedBox.shrink();
    }

    final listView = ListView.builder(
      padding: padding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );

    if (enableShimmer) {
      return ShimmerEffect(child: listView);
    }

    return listView;
  }
}

/// Skeleton grid widget
/// Displays a grid of skeleton items with shimmer effect
class SkeletonGrid extends StatelessWidget {
  /// Number of skeleton items to display
  final int itemCount;

  /// Builder for each skeleton item
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Number of columns
  final int crossAxisCount;

  /// Spacing between items
  final double spacing;

  /// Padding around the grid
  final EdgeInsets? padding;

  /// Whether to enable shimmer effect
  final bool enableShimmer;

  /// Whether the skeleton is enabled
  final bool enabled;

  const SkeletonGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.spacing = 16.0,
    this.padding,
    this.enableShimmer = true,
    this.enabled = true,
  });

  /// Create a skeleton grid with default card items
  factory SkeletonGrid.cards({
    Key? key,
    int itemCount = 6,
    int crossAxisCount = 2,
    double spacing = 16.0,
    bool hasImage = true,
    double imageHeight = 150.0,
    int lines = 2,
    EdgeInsets? padding,
    bool enableShimmer = true,
    bool enabled = true,
  }) {
    return SkeletonGrid(
      key: key,
      itemCount: itemCount,
      crossAxisCount: crossAxisCount,
      spacing: spacing,
      padding: padding,
      enableShimmer: enableShimmer,
      enabled: enabled,
      itemBuilder: (context, index) {
        return SkeletonCard(
          hasImage: hasImage,
          imageHeight: imageHeight,
          lines: lines,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const SizedBox.shrink();
    }

    final gridView = GridView.builder(
      padding: padding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 0.75,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );

    if (enableShimmer) {
      return ShimmerEffect(child: gridView);
    }

    return gridView;
  }
}
