import 'package:flutter/material.dart';

/// Manages RTL-aware animations
class RTLHandler {
  const RTLHandler();

  /// Check if current text direction is RTL
  bool isRTL(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl;
  }

  /// Check if a locale is RTL
  bool isRTLLocale(Locale locale) {
    final rtlLanguages = ['ar', 'he', 'fa', 'ur'];
    return rtlLanguages.contains(locale.languageCode);
  }

  /// Adjust offset for RTL
  /// Reverses horizontal offsets in RTL mode
  Offset adjustOffset(Offset offset, BuildContext context) {
    if (!isRTL(context)) return offset;

    // Reverse horizontal direction in RTL
    return Offset(-offset.dx, offset.dy);
  }

  /// Adjust alignment for RTL
  AlignmentGeometry adjustAlignment(
    AlignmentGeometry alignment,
    BuildContext context,
  ) {
    if (!isRTL(context)) return alignment;

    // Convert alignment to Alignment if possible
    if (alignment is Alignment) {
      return Alignment(-alignment.x, alignment.y);
    }

    return alignment;
  }

  /// Get offset for sliding from start (logical direction)
  /// In LTR: slides from left
  /// In RTL: slides from right
  Offset slideFromStart(BuildContext context) {
    return isRTL(context) ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
  }

  /// Get offset for sliding from end (logical direction)
  /// In LTR: slides from right
  /// In RTL: slides from left
  Offset slideFromEnd(BuildContext context) {
    return isRTL(context) ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
  }

  /// Get offset for sliding to start (logical direction)
  Offset slideToStart(BuildContext context) {
    return isRTL(context) ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
  }

  /// Get offset for sliding to end (logical direction)
  Offset slideToEnd(BuildContext context) {
    return isRTL(context) ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
  }

  /// Convert logical horizontal offset to physical
  /// Positive values mean "towards end" in logical terms
  Offset logicalToPhysical(double logicalX, double y, BuildContext context) {
    final physicalX = isRTL(context) ? -logicalX : logicalX;
    return Offset(physicalX, y);
  }

  /// Get alignment for start (logical)
  AlignmentGeometry alignmentStart(BuildContext context) {
    return isRTL(context) ? Alignment.centerRight : Alignment.centerLeft;
  }

  /// Get alignment for end (logical)
  AlignmentGeometry alignmentEnd(BuildContext context) {
    return isRTL(context) ? Alignment.centerLeft : Alignment.centerRight;
  }
}
