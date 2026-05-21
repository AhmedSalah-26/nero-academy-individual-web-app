import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility Constants
class AccessibilityConstants {
  AccessibilityConstants._();

  /// Minimum touch target size (WCAG 2.1 Level AAA)
  static const double minTouchTarget = 48.0;

  /// Minimum contrast ratio for normal text (WCAG AA)
  static const double minContrastRatioAA = 4.5;

  /// Minimum contrast ratio for large text (WCAG AA)
  static const double minContrastRatioLargeAA = 3.0;

  /// Large text threshold (18sp or 14sp bold)
  static const double largeTextThreshold = 18.0;
}

/// Semantic wrapper for better screen reader support
class SemanticWrapper extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? hint;
  final String? value;
  final bool? button;
  final bool? header;
  final bool? link;
  final bool? image;
  final bool? textField;
  final bool? slider;
  final bool? toggled;
  final bool? checked;
  final bool? selected;
  final bool? enabled;
  final bool? readOnly;
  final bool? focused;
  final bool? hidden;
  final bool excludeSemantics;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final int? sortKey;

  const SemanticWrapper({
    super.key,
    required this.child,
    this.label,
    this.hint,
    this.value,
    this.button,
    this.header,
    this.link,
    this.image,
    this.textField,
    this.slider,
    this.toggled,
    this.checked,
    this.selected,
    this.enabled,
    this.readOnly,
    this.focused,
    this.hidden,
    this.excludeSemantics = false,
    this.onTap,
    this.onLongPress,
    this.sortKey,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: button,
      header: header,
      link: link,
      image: image,
      textField: textField,
      slider: slider,
      toggled: toggled,
      checked: checked,
      selected: selected,
      enabled: enabled,
      readOnly: readOnly,
      focused: focused,
      hidden: hidden,
      excludeSemantics: excludeSemantics,
      onTap: onTap,
      onLongPress: onLongPress,
      sortKey: sortKey != null ? OrdinalSortKey(sortKey!.toDouble()) : null,
      child: child,
    );
  }
}

/// Accessible touch target wrapper
class AccessibleTouchTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final String? semanticHint;
  final double minSize;

  const AccessibleTouchTarget({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.semanticHint,
    this.minSize = AccessibilityConstants.minTouchTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minSize,
            minHeight: minSize,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Focus highlight wrapper for keyboard navigation
class FocusHighlight extends StatefulWidget {
  final Widget child;
  final Color? focusColor;
  final BorderRadius? borderRadius;

  const FocusHighlight({
    super.key,
    required this.child,
    this.focusColor,
    this.borderRadius,
  });

  @override
  State<FocusHighlight> createState() => _FocusHighlightState();
}

class _FocusHighlightState extends State<FocusHighlight> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final focusColor = widget.focusColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.12));

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          border: _isFocused
              ? Border.all(color: focusColor, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Accessible image with alt text
class AccessibleImage extends StatelessWidget {
  final ImageProvider image;
  final String altText;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AccessibleImage({
    super.key,
    required this.image,
    required this.altText,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Image(
      image: image,
      width: width,
      height: height,
      fit: fit,
      semanticLabel: altText,
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return Semantics(
      image: true,
      label: altText,
      child: ExcludeSemantics(child: imageWidget),
    );
  }
}

/// Text scale factor wrapper for dynamic font scaling
class ScalableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double maxScaleFactor;

  const ScalableText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.maxScaleFactor = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      textScaler: TextScaler.linear(
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, maxScaleFactor),
      ),
    );
  }
}

/// Announce message to screen readers
void announceToScreenReader(BuildContext context, String message) {
  SemanticsService.announce(message, Directionality.of(context));
}

/// Extension for accessibility helpers
extension AccessibilityExtensions on Widget {
  /// Wrap with semantic label
  Widget withSemanticLabel(String label) {
    return Semantics(label: label, child: this);
  }

  /// Wrap with button semantics
  Widget asSemanticButton({String? label, String? hint}) {
    return Semantics(
      button: true,
      label: label,
      hint: hint,
      child: this,
    );
  }

  /// Wrap with header semantics
  Widget asSemanticHeader({String? label}) {
    return Semantics(
      header: true,
      label: label,
      child: this,
    );
  }

  /// Ensure minimum touch target
  Widget withMinTouchTarget([double size = 48]) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      child: Center(child: this),
    );
  }

  /// Exclude from semantics tree
  Widget excludeFromSemantics() {
    return ExcludeSemantics(child: this);
  }
}
