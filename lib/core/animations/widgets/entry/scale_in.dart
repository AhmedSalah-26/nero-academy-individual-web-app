import 'package:flutter/material.dart';
import 'base_entry_animation.dart';

/// Scale in animation widget
/// Animates scale from begin to end value with optional fade
class ScaleIn extends EntryAnimation {
  /// Starting scale value
  final double begin;

  /// Ending scale value
  final double end;

  /// Alignment for scale transformation
  final Alignment alignment;

  /// Whether to include fade animation
  final bool includeFade;

  const ScaleIn({
    super.key,
    required super.child,
    this.begin = 0.0,
    this.end = 1.0,
    this.alignment = Alignment.center,
    this.includeFade = true,
    super.duration,
    super.delay,
    super.curve,
    super.animate,
  });

  @override
  State<ScaleIn> createState() => _ScaleInState();
}

class _ScaleInState extends EntryAnimationState<ScaleIn> {
  late Animation<double> _scaleAnimation;
  late Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _scaleAnimation = Tween<double>(
      begin: widget.begin,
      end: widget.end,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: effectiveCurve,
      ),
    );

    if (widget.includeFade) {
      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget result = ScaleTransition(
      scale: _scaleAnimation,
      alignment: widget.alignment,
      child: widget.child,
    );

    if (widget.includeFade && _fadeAnimation != null) {
      result = FadeTransition(
        opacity: _fadeAnimation!,
        child: result,
      );
    }

    return result;
  }
}
