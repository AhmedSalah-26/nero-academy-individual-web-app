/// Number extension methods
extension IntExtensions on int {
  /// Convert to duration in milliseconds
  Duration get milliseconds => Duration(milliseconds: this);

  /// Convert to duration in seconds
  Duration get seconds => Duration(seconds: this);

  /// Convert to duration in minutes
  Duration get minutes => Duration(minutes: this);

  /// Convert to duration in hours
  Duration get hours => Duration(hours: this);

  /// Convert to duration in days
  Duration get days => Duration(days: this);

  /// Check if even
  bool get isEven => this % 2 == 0;

  /// Check if odd
  bool get isOdd => this % 2 != 0;

  /// Clamp value between min and max
  int clampTo(int min, int max) => this < min ? min : (this > max ? max : this);
}

/// Double extension methods
extension DoubleExtensions on double {
  /// Format as currency (EGP)
  String toCurrency([String? symbol]) {
    final currencySymbol = symbol ?? 'EGP';
    return '${toStringAsFixed(0)} $currencySymbol';
  }

  /// Format as percentage
  String toPercentage({int decimals = 0}) {
    return '${toStringAsFixed(decimals)}%';
  }

  /// Round to specific decimal places
  double roundTo(int places) {
    final mod = 1.0 * (10 * places);
    return (this * mod).round() / mod;
  }
}
