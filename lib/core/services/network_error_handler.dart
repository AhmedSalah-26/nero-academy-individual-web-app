import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// Global network error handler
class NetworkErrorHandler {
  static final NetworkErrorHandler _instance = NetworkErrorHandler._internal();
  factory NetworkErrorHandler() => _instance;
  NetworkErrorHandler._internal();

  static DateTime? _lastToastTime;
  static const _toastDebounce = Duration(seconds: 2);

  /// Check if error is a network error
  static bool isNetworkError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('socketexception') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('no address associated') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('network is unreachable') ||
        errorStr.contains('connection reset') ||
        errorStr.contains('connection timed out') ||
        errorStr.contains('clientexception');
  }

  /// Show network error toast if it's a network error
  /// Returns true if it was a network error and toast was shown
  static bool handleError(dynamic error, [BuildContext? context]) {
    if (!isNetworkError(error)) return false;
    showNetworkError(context);
    return true;
  }

  /// Show network error toast (with debounce to prevent duplicates)
  static void showNetworkError([BuildContext? context]) {
    final now = DateTime.now();
    if (_lastToastTime != null &&
        now.difference(_lastToastTime!) < _toastDebounce) {
      return; // Skip if shown recently
    }
    _lastToastTime = now;

    toastification.show(
      title: Text('error_network'.tr(),
          style: const TextStyle(color: Colors.white)),
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topCenter,
      style: ToastificationStyle.flat,
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      primaryColor: Colors.white,
      showProgressBar: false,
      closeButtonShowType: CloseButtonShowType.none,
      icon: const Icon(Icons.wifi_off, color: Colors.white),
    );
  }
}
