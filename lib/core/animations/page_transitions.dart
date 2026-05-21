import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Custom Page Route with Slide Transition
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;

  SlidePageRoute({
    required this.page,
    this.direction = SlideDirection.right,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final begin = _getOffset(direction);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            final offsetAnimation = animation.drive(tween);

            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
        );

  static Offset _getOffset(SlideDirection direction) {
    switch (direction) {
      case SlideDirection.right:
        return const Offset(1.0, 0.0);
      case SlideDirection.left:
        return const Offset(-1.0, 0.0);
      case SlideDirection.up:
        return const Offset(0.0, 1.0);
      case SlideDirection.down:
        return const Offset(0.0, -1.0);
    }
  }
}

enum SlideDirection { right, left, up, down }

/// Custom Page Route with Fade Transition
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        );
}

/// Custom Page Route with Scale Transition
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScalePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
            final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(scale: scaleAnimation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        );
}

/// Custom Page Route with Shared Axis Transition (Material 3)
class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SharedAxisType type;

  SharedAxisPageRoute({
    required this.page,
    this.type = SharedAxisType.horizontal,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
              ),
            );

            final slideIn = Tween<Offset>(
              begin: _getBeginOffset(type),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

            return FadeTransition(
              opacity: fadeIn,
              child: SlideTransition(position: slideIn, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );

  static Offset _getBeginOffset(SharedAxisType type) {
    switch (type) {
      case SharedAxisType.horizontal:
        return const Offset(0.3, 0.0);
      case SharedAxisType.vertical:
        return const Offset(0.0, 0.3);
      case SharedAxisType.scaled:
        return Offset.zero;
    }
  }
}

enum SharedAxisType { horizontal, vertical, scaled }

/// Modal Bottom Sheet Transition
class ModalBottomSheetRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ModalBottomSheetRoute({
    required this.page,
    Color barrierColor = Colors.black54,
  }) : super(
          opaque: false,
          barrierColor: barrierColor,
          barrierDismissible: true,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

            return SlideTransition(position: slideAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

// ==================== GoRouter Integration ====================

/// Helper class for GoRouter page transitions
class AnimatedPageTransitions {
  /// Slide transition for GoRouter
  static Page<T> slide<T>({
    required Widget child,
    required LocalKey key,
    SlideDirection direction = SlideDirection.right,
    String? name,
    Object? arguments,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final begin = _getSlideOffset(direction);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    );
  }

  /// Fade transition for GoRouter
  static Page<T> fade<T>({
    required Widget child,
    required LocalKey key,
    String? name,
    Object? arguments,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 200),
    );
  }

  /// Scale transition for GoRouter
  static Page<T> scale<T>({
    required Widget child,
    required LocalKey key,
    String? name,
    Object? arguments,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(scale: scaleAnimation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 200),
    );
  }

  /// Shared axis transition for GoRouter (Material 3)
  static Page<T> sharedAxis<T>({
    required Widget child,
    required LocalKey key,
    SharedAxisType type = SharedAxisType.horizontal,
    String? name,
    Object? arguments,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          ),
        );

        final slideIn = Tween<Offset>(
          begin: _getSharedAxisOffset(type),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

        return FadeTransition(
          opacity: fadeIn,
          child: SlideTransition(position: slideIn, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Modal bottom sheet transition for GoRouter
  static Page<T> modalBottomSheet<T>({
    required Widget child,
    required LocalKey key,
    String? name,
    Object? arguments,
    Color barrierColor = Colors.black54,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      opaque: false,
      barrierColor: barrierColor,
      barrierDismissible: true,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

        return SlideTransition(position: slideAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Offset _getSlideOffset(SlideDirection direction) {
    switch (direction) {
      case SlideDirection.right:
        return const Offset(1.0, 0.0);
      case SlideDirection.left:
        return const Offset(-1.0, 0.0);
      case SlideDirection.up:
        return const Offset(0.0, 1.0);
      case SlideDirection.down:
        return const Offset(0.0, -1.0);
    }
  }

  static Offset _getSharedAxisOffset(SharedAxisType type) {
    switch (type) {
      case SharedAxisType.horizontal:
        return const Offset(0.3, 0.0);
      case SharedAxisType.vertical:
        return const Offset(0.0, 0.3);
      case SharedAxisType.scaled:
        return Offset.zero;
    }
  }
}
