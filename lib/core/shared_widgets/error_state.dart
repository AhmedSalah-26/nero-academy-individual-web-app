import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';

/// Error Type
enum ErrorType {
  network,
  server,
  notFound,
  unauthorized,
  generic,
}

/// Unified Error State Widget
class ErrorState extends StatelessWidget {
  final ErrorType type;
  final String? title;
  final String? message;
  final String? retryText;
  final VoidCallback? onRetry;
  final VoidCallback? onGoBack;
  final IconData? icon;

  const ErrorState({
    super.key,
    this.type = ErrorType.generic,
    this.title,
    this.message,
    this.retryText,
    this.onRetry,
    this.onGoBack,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = _getConfig();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcon(isDark, config),
            const SizedBox(height: 24),
            Text(
              title ?? config.title,
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.textMainLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message ?? config.message,
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildActions(config),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(bool isDark, _ErrorConfig config) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon ?? config.icon,
        size: 48,
        color: AppColors.error,
      ),
    );
  }

  Widget _buildActions(_ErrorConfig config) {
    return Column(
      children: [
        if (onRetry != null)
          AppButton(
            text: retryText ?? config.retryText,
            onPressed: onRetry!,
            variant: AppButtonVariant.primary,
            size: AppButtonSize.medium,
            icon: Icons.refresh_rounded,
          ),
        if (onGoBack != null) ...[
          const SizedBox(height: 12),
          AppButton(
            text: 'Go Back',
            onPressed: onGoBack!,
            variant: AppButtonVariant.outline,
            size: AppButtonSize.medium,
          ),
        ],
      ],
    );
  }

  _ErrorConfig _getConfig() {
    switch (type) {
      case ErrorType.network:
        return _ErrorConfig(
          icon: Icons.wifi_off_rounded,
          title: 'No Internet Connection',
          message: 'Please check your connection and try again',
          retryText: 'Try Again',
        );
      case ErrorType.server:
        return _ErrorConfig(
          icon: Icons.cloud_off_rounded,
          title: 'Server Error',
          message: 'Something went wrong on our end. Please try again later',
          retryText: 'Retry',
        );
      case ErrorType.notFound:
        return _ErrorConfig(
          icon: Icons.search_off_rounded,
          title: 'Not Found',
          message: 'The content you\'re looking for doesn\'t exist',
          retryText: 'Go Home',
        );
      case ErrorType.unauthorized:
        return _ErrorConfig(
          icon: Icons.lock_outline_rounded,
          title: 'Access Denied',
          message: 'You don\'t have permission to view this content',
          retryText: 'Login',
        );
      case ErrorType.generic:
        return _ErrorConfig(
          icon: Icons.error_outline_rounded,
          title: 'Something Went Wrong',
          message: 'An unexpected error occurred. Please try again',
          retryText: 'Try Again',
        );
    }
  }
}

class _ErrorConfig {
  final IconData icon;
  final String title;
  final String message;
  final String retryText;

  _ErrorConfig({
    required this.icon,
    required this.title,
    required this.message,
    required this.retryText,
  });
}
