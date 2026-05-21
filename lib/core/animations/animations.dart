/// Animations Library
///
/// A comprehensive animation system for the Flutter LMS application.
/// Provides reusable animation widgets, configuration, accessibility support,
/// RTL handling, and performance monitoring.
///
/// Usage:
/// ```dart
/// import 'package:edu/core/animations/animations.dart';
/// ```
library;

// Foundation layer
export 'foundation/foundation.dart';

// Legacy animations (deprecated - use new widgets instead)
export 'app_animations.dart'
    hide FadeIn, SlideFadeIn, ScaleIn, StaggeredList, PulseAnimation;
export 'page_transitions.dart';

// Animation widgets
export 'widgets/widgets.dart';

// Utilities
export 'utils/utils.dart';
