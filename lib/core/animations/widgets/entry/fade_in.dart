import 'package:flutter/material.dart';
import 'base_entry_animation.dart';

/// Fade in animation widget
/// Animates opacity from begin to end value
class FadeIn extends EntryAnimation {
  /// Starting opacity value
  final double begin;

  /// Ending opacity value
  final double end;

  const FadeIn({
    super.key,
    required super.child,
    this.begin = 0.0,
    this.end = 1.0,
    super.duration,
    super.delay,
    super.curve,
    super.animate,
  });

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends EntryAnimationState<FadeIn> {
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeAnimation = Tween<double>(
      begin: widget.begin,
      end: widget.end,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: effectiveCurve,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.child,
    );
  }
}
