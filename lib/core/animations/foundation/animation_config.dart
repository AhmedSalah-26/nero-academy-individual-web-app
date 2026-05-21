import 'package:flutter/material.dart';

/// Animation preset types
enum AnimationPreset {
  /// Shorter durations, subtle effects
  subtle,

  /// Standard Material Design 3 timings
  normal,

  /// Longer durations, more pronounced effects
  energetic,
}

/// Central configuration class for all animation settings
class AnimationConfig {
  // Duration presets (Material Design 3)
  final Duration shortDuration;
  final Duration mediumDuration;
  final Duration longDuration;
  final Duration extraLongDuration;

  // Curve presets (Material Design 3)
  final Curve emphasizedCurve;
  final Curve standardCurve;
  final Curve decelerateCurve;
  final Curve accelerateCurve;

  // Animation preset
  final AnimationPreset preset;

  // Accessibility
  final bool respectReduceMotion;
  final bool animationsEnabled;

  // RTL support
  final bool autoDetectRTL;

  // Performance
  final bool enablePerformanceMonitoring;

  const AnimationConfig({
    this.shortDuration = const Duration(milliseconds: 200),
    this.mediumDuration = const Duration(milliseconds: 300),
    this.longDuration = const Duration(milliseconds: 500),
    this.extraLongDuration = const Duration(milliseconds: 800),
    this.emphasizedCurve = Curves.easeInOutCubicEmphasized,
    this.standardCurve = Curves.easeInOut,
    this.decelerateCurve = Curves.decelerate,
    this.accelerateCurve = Curves.easeIn,
    this.preset = AnimationPreset.normal,
    this.respectReduceMotion = true,
    this.animationsEnabled = true,
    this.autoDetectRTL = true,
    this.enablePerformanceMonitoring = false,
  });

  /// Default configuration
  static const AnimationConfig _defaultConfig = AnimationConfig();

  /// Global instance
  static AnimationConfig _instance = _defaultConfig;

  /// Get global instance
  static AnimationConfig get instance => _instance;

  /// Set global instance
  static void setInstance(AnimationConfig config) {
    _instance = config;
  }

  /// Get configuration from context (if provided via InheritedWidget)
  static AnimationConfig of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_InheritedAnimationConfig>();
    return inherited?.config ?? _instance;
  }

  /// Create a copy with modified values
  AnimationConfig copyWith({
    Duration? shortDuration,
    Duration? mediumDuration,
    Duration? longDuration,
    Duration? extraLongDuration,
    Curve? emphasizedCurve,
    Curve? standardCurve,
    Curve? decelerateCurve,
    Curve? accelerateCurve,
    AnimationPreset? preset,
    bool? respectReduceMotion,
    bool? animationsEnabled,
    bool? autoDetectRTL,
    bool? enablePerformanceMonitoring,
  }) {
    return AnimationConfig(
      shortDuration: shortDuration ?? this.shortDuration,
      mediumDuration: mediumDuration ?? this.mediumDuration,
      longDuration: longDuration ?? this.longDuration,
      extraLongDuration: extraLongDuration ?? this.extraLongDuration,
      emphasizedCurve: emphasizedCurve ?? this.emphasizedCurve,
      standardCurve: standardCurve ?? this.standardCurve,
      decelerateCurve: decelerateCurve ?? this.decelerateCurve,
      accelerateCurve: accelerateCurve ?? this.accelerateCurve,
      preset: preset ?? this.preset,
      respectReduceMotion: respectReduceMotion ?? this.respectReduceMotion,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      autoDetectRTL: autoDetectRTL ?? this.autoDetectRTL,
      enablePerformanceMonitoring:
          enablePerformanceMonitoring ?? this.enablePerformanceMonitoring,
    );
  }

  /// Create configuration from preset
  factory AnimationConfig.fromPreset(AnimationPreset preset) {
    switch (preset) {
      case AnimationPreset.subtle:
        return const AnimationConfig(
          shortDuration: Duration(milliseconds: 150),
          mediumDuration: Duration(milliseconds: 250),
          longDuration: Duration(milliseconds: 400),
          extraLongDuration: Duration(milliseconds: 600),
          preset: AnimationPreset.subtle,
        );
      case AnimationPreset.normal:
        return const AnimationConfig(preset: AnimationPreset.normal);
      case AnimationPreset.energetic:
        return const AnimationConfig(
          shortDuration: Duration(milliseconds: 250),
          mediumDuration: Duration(milliseconds: 400),
          longDuration: Duration(milliseconds: 600),
          extraLongDuration: Duration(milliseconds: 1000),
          preset: AnimationPreset.energetic,
        );
    }
  }
}

/// Inherited widget to provide AnimationConfig down the widget tree
class AnimationConfigProvider extends InheritedWidget {
  final AnimationConfig config;

  const AnimationConfigProvider({
    super.key,
    required this.config,
    required super.child,
  });

  @override
  bool updateShouldNotify(AnimationConfigProvider oldWidget) {
    return config != oldWidget.config;
  }

  static AnimationConfig? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedAnimationConfig>()
        ?.config;
  }
}

class _InheritedAnimationConfig extends InheritedWidget {
  final AnimationConfig config;

  const _InheritedAnimationConfig({
    required this.config,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedAnimationConfig oldWidget) {
    return config != oldWidget.config;
  }
}
