import 'package:flutter/material.dart';
import 'empty_state.dart';
import 'error_state.dart';
import 'loading_state.dart';

class AsyncStateView extends StatelessWidget {
  final bool isLoading;
  final bool isError;
  final bool isEmpty;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final ErrorType errorType;
  final EmptyStateType emptyType;
  final Widget child;
  final Widget? loading;
  final Widget? error;
  final Widget? empty;

  const AsyncStateView({
    super.key,
    required this.isLoading,
    required this.isError,
    required this.isEmpty,
    required this.child,
    this.errorMessage,
    this.onRetry,
    this.errorType = ErrorType.generic,
    this.emptyType = EmptyStateType.generic,
    this.loading,
    this.error,
    this.empty,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loading ?? const AppLoadingState();
    }

    if (isError) {
      return error ??
          ErrorState(
            type: errorType,
            message: errorMessage,
            onRetry: onRetry,
          );
    }

    if (isEmpty) {
      return empty ?? EmptyState(type: emptyType);
    }

    return child;
  }
}
