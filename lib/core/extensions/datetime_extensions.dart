import 'package:easy_localization/easy_localization.dart';

/// DateTime extension methods
extension DateTimeExtensions on DateTime {
  /// Format as date string (dd/MM/yyyy)
  String toDateString() => DateFormat('dd/MM/yyyy').format(this);

  /// Format as time string (HH:mm)
  String toTimeString() => DateFormat('HH:mm').format(this);

  /// Format as date and time string
  String toDateTimeString() => DateFormat('dd/MM/yyyy HH:mm').format(this);

  /// Format with custom pattern
  String format(String pattern) => DateFormat(pattern).format(this);

  /// Check if today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Check if in past
  bool get isPast => isBefore(DateTime.now());

  /// Check if in future
  bool get isFuture => isAfter(DateTime.now());

  /// Get relative time string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'time.just_now'.tr();
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${'time.minutes_ago'.tr()}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${'time.hours_ago'.tr()}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${'time.days_ago'.tr()}';
    } else {
      return toDateString();
    }
  }

  /// Get start of day
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get end of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);

  /// Add business days (excluding weekends)
  DateTime addBusinessDays(int days) {
    var result = this;
    var addedDays = 0;
    while (addedDays < days) {
      result = result.add(const Duration(days: 1));
      if (result.weekday != DateTime.friday &&
          result.weekday != DateTime.saturday) {
        addedDays++;
      }
    }
    return result;
  }
}

/// Nullable DateTime extensions
extension NullableDateTimeExtensions on DateTime? {
  /// Format or return default
  String toDateStringOrDefault([String defaultValue = '-']) {
    return this?.toDateString() ?? defaultValue;
  }

  /// Check if not null and in future
  bool get isNotNullAndFuture => this != null && this!.isFuture;
}
