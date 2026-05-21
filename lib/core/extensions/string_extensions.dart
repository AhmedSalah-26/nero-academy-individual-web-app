/// String extension methods
extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Check if string is valid email
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Check if string is valid phone (Egyptian format)
  bool get isValidPhone {
    return RegExp(r'^01[0125][0-9]{8}$').hasMatch(this);
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Remove all whitespace
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Check if string is numeric
  bool get isNumeric => double.tryParse(this) != null;

  /// Convert to nullable int
  int? toIntOrNull() => int.tryParse(this);

  /// Convert to nullable double
  double? toDoubleOrNull() => double.tryParse(this);

  /// Get first two words from name
  String get firstTwoWords {
    if (isEmpty) return this;
    final words = trim().split(RegExp(r'\s+'));
    if (words.length <= 2) return this;
    return '${words[0]} ${words[1]}';
  }
}

/// Nullable String extensions
extension NullableStringExtensions on String? {
  /// Check if string is null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Check if string is not null and not empty
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;

  /// Return value or default
  String orDefault([String defaultValue = '']) => this ?? defaultValue;
}
