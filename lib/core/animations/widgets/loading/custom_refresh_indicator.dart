import 'package:flutter/material.dart';

/// Custom refresh indicator widget
/// Provides pull-to-refresh functionality with custom styling
class CustomRefreshIndicator extends StatelessWidget {
  /// The child widget (typically a scrollable)
  final Widget child;

  /// Callback when refresh is triggered
  final Future<void> Function() onRefresh;

  /// Color of the refresh indicator
  final Color? color;

  /// Background color
  final Color? backgroundColor;

  /// Stroke width
  final double strokeWidth;

  /// Displacement from top
  final double displacement;

  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 2.0,
    this.displacement = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: effectiveColor,
      backgroundColor: backgroundColor,
      strokeWidth: strokeWidth,
      displacement: displacement,
      child: child,
    );
  }
}

/// Custom refresh indicator with custom builder
/// Allows full customization of the refresh indicator appearance
class CustomRefreshIndicatorBuilder extends StatelessWidget {
  /// The child widget (typically a scrollable)
  final Widget child;

  /// Callback when refresh is triggered
  final Future<void> Function() onRefresh;

  /// Trigger offset (how far to pull before triggering)
  final double triggerOffset;

  const CustomRefreshIndicatorBuilder({
    super.key,
    required this.child,
    required this.onRefresh,
    this.triggerOffset = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    // For now, use standard RefreshIndicator
    // Can be enhanced with custom implementation later
    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: triggerOffset,
      child: child,
    );
  }
}

/// Loading overlay widget
/// Shows a loading indicator over content
class LoadingOverlay extends StatelessWidget {
  /// Whether to show the loading overlay
  final bool isLoading;

  /// The child widget
  final Widget child;

  /// Loading indicator widget
  final Widget? loadingIndicator;

  /// Overlay color
  final Color? overlayColor;

  /// Loading message
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingIndicator,
    this.overlayColor,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: overlayColor ??
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    loadingIndicator ??
                        CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
