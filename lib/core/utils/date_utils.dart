import 'package:intl/intl.dart';

/// Date Utilities
class AppDateUtils {
  AppDateUtils._();

  /// Format date to readable string
  static String formatDate(DateTime date, {String locale = 'ar'}) {
    return DateFormat.yMMMd(locale).format(date);
  }

  /// Format date with time
  static String formatDateTime(DateTime date, {String locale = 'ar'}) {
    return DateFormat.yMMMd(locale).add_jm().format(date);
  }

  /// Format time only
  static String formatTime(DateTime date, {String locale = 'ar'}) {
    return DateFormat.jm(locale).format(date);
  }

  /// Get relative time (e.g., "منذ 5 دقائق")
  static String getRelativeTime(DateTime date, {bool isArabic = true}) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return isArabic ? 'منذ $years سنة' : '$years years ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return isArabic ? 'منذ $months شهر' : '$months months ago';
    } else if (difference.inDays > 0) {
      return isArabic
          ? 'منذ ${difference.inDays} يوم'
          : '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return isArabic
          ? 'منذ ${difference.inHours} ساعة'
          : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return isArabic
          ? 'منذ ${difference.inMinutes} دقيقة'
          : '${difference.inMinutes} minutes ago';
    } else {
      return isArabic ? 'الآن' : 'Just now';
    }
  }

  /// Format duration (e.g., "5س 30د")
  static String formatDuration(int totalMinutes, {bool isArabic = true}) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return isArabic ? '$hoursس $minutesد' : '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return isArabic ? '$hoursس' : '${hours}h';
    } else {
      return isArabic ? '$minutesد' : '${minutes}m';
    }
  }

  /// Format video duration (e.g., "5:30")
  static String formatVideoDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get countdown string
  static String getCountdown(DateTime endDate, {bool isArabic = true}) {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.isNegative) {
      return isArabic ? 'انتهى' : 'Ended';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    if (days > 0) {
      return isArabic ? '$days يوم $hours ساعة' : '${days}d ${hours}h';
    } else if (hours > 0) {
      return isArabic ? '$hours ساعة $minutes دقيقة' : '${hours}h ${minutes}m';
    } else {
      return isArabic ? '$minutes دقيقة' : '${minutes}m';
    }
  }
}
