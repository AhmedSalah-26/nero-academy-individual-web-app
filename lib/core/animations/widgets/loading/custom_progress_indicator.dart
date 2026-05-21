import 'package:flutter/material.dart';

/// Custom progress indicator widget
/// Provides circular and linear progress indicators with labels
class CustomProgressIndicator extends StatelessWidget {
  /// Progress value (0.0 to 1.0), null for indeterminate
  final double? value;

  /// Color of the progress indicator
  final Color? color;

  /// Background color
  final Color? backgroundColor;

  /// Stroke width for circular indicator
  final double strokeWidth;

  /// Optional label to display
  final String? label;

  /// Label style
  final TextStyle? labelStyle;

  /// Size for circular indicator
  final double size;

  /// Type of progress indicator
  final ProgressIndicatorType type;

  const CustomProgressIndicator({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 4.0,
    this.label,
    this.labelStyle,
    this.size = 40.0,
    this.type = ProgressIndicatorType.circular,
  });

  /// Create a circular progress indicator
  factory CustomProgressIndicator.circular({
    Key? key,
    double? value,
    Color? color,
    Color? backgroundColor,
    double strokeWidth = 4.0,
    String? label,
    TextStyle? labelStyle,
    double size = 40.0,
  }) {
    return CustomProgressIndicator(
      key: key,
      value: value,
      color: color,
      backgroundColor: backgroundColor,
      strokeWidth: strokeWidth,
      label: label,
      labelStyle: labelStyle,
      size: size,
      type: ProgressIndicatorType.circular,
    );
  }

  /// Create a linear progress indicator
  factory CustomProgressIndicator.linear({
    Key? key,
    double? value,
    Color? color,
    Color? backgroundColor,
    double strokeWidth = 4.0,
    String? label,
    TextStyle? labelStyle,
  }) {
    return CustomProgressIndicator(
      key: key,
      value: value,
      color: color,
      backgroundColor: backgroundColor,
      strokeWidth: strokeWidth,
      label: label,
      labelStyle: labelStyle,
      type: ProgressIndicatorType.linear,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;
    final effectiveBackgroundColor =
        backgroundColor ?? effectiveColor.withValues(alpha: 0.2);

    Widget indicator;

    switch (type) {
      case ProgressIndicatorType.circular:
        indicator = SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            backgroundColor: effectiveBackgroundColor,
          ),
        );
        break;

      case ProgressIndicatorType.linear:
        indicator = LinearProgressIndicator(
          value: value,
          minHeight: strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
          backgroundColor: effectiveBackgroundColor,
        );
        break;
    }

    if (label != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 8),
          Text(
            label!,
            style: labelStyle ?? theme.textTheme.bodySmall,
          ),
        ],
      );
    }

    return indicator;
  }
}

/// Progress indicator type
enum ProgressIndicatorType {
  circular,
  linear,
}

/// Animated progress bar widget
/// Smoothly animates progress changes
class AnimatedProgressBar extends StatefulWidget {
  /// Current progress value (0.0 to 1.0)
  final double value;

  /// Height of the progress bar
  final double height;

  /// Color of the progress bar
  final Color? color;

  /// Background color
  final Color? backgroundColor;

  /// Border radius
  final BorderRadius? borderRadius;

  /// Animation duration
  final Duration duration;

  /// Whether to show percentage text
  final bool showPercentage;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 8.0,
    this.color,
    this.backgroundColor,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 300),
    this.showPercentage = false,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(
      begin: _previousValue,
      end: widget.value,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != oldWidget.value) {
      _previousValue = _animation.value;
      _animation = Tween<double>(
        begin: _previousValue,
        end: widget.value,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.color ?? theme.colorScheme.primary;
    final effectiveBackgroundColor =
        widget.backgroundColor ?? effectiveColor.withValues(alpha: 0.2);
    final effectiveBorderRadius =
        widget.borderRadius ?? BorderRadius.circular(widget.height / 2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Stack(
              children: [
                Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: effectiveBackgroundColor,
                    borderRadius: effectiveBorderRadius,
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: _animation.value.clamp(0.0, 1.0),
                  child: Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: effectiveColor,
                      borderRadius: effectiveBorderRadius,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        if (widget.showPercentage) ...[
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final percentage = (_animation.value * 100).toInt();
              return Text(
                '$percentage%',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.end,
              );
            },
          ),
        ],
      ],
    );
  }
}
