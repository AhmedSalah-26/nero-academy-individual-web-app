import 'package:intl/intl.dart';

/// Number Utilities
class NumberUtils {
  NumberUtils._();

  /// Format price with currency
  static String formatPrice(double price,
      {String currency = 'EGP', String locale = 'ar_EG'}) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: currency == 'EGP' ? 'ج.م' : '\$',
      decimalDigits: price.truncateToDouble() == price ? 0 : 2,
    );
    return formatter.format(price);
  }

  /// Format number with commas
  static String formatNumber(num number, {String locale = 'ar_EG'}) {
    final formatter = NumberFormat('#,###', locale);
    return formatter.format(number);
  }

  /// Format compact number (e.g., 1.2K, 5M)
  static String formatCompact(num number, {String locale = 'en'}) {
    final formatter = NumberFormat.compact(locale: locale);
    return formatter.format(number);
  }

  /// Format percentage
  static String formatPercentage(double value, {int decimals = 0}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Calculate discount percentage
  static int calculateDiscount(double originalPrice, double discountPrice) {
    if (originalPrice <= 0) return 0;
    return (((originalPrice - discountPrice) / originalPrice) * 100).round();
  }

  /// Format rating
  static String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  /// Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
