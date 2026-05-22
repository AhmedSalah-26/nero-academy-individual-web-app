import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Dashboard Search Bar - Search input with debounce
class DashboardSearchBar extends StatefulWidget {
  final String? hintText;
  final String? hintTextAr;
  final ValueChanged<String> onSearch;
  final Duration debounceDuration;
  final String? initialValue;

  const DashboardSearchBar({
    super.key,
    this.hintText,
    this.hintTextAr,
    required this.onSearch,
    this.debounceDuration = const Duration(milliseconds: 500),
    this.initialValue,
  });

  @override
  State<DashboardSearchBar> createState() => _DashboardSearchBarState();
}

class _DashboardSearchBarState extends State<DashboardSearchBar> {
  late TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onSearch(value);
    });
  }

  void _clear() {
    _controller.clear();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final hint = isArabic
        ? (widget.hintTextAr ?? 'بحث...')
        : (widget.hintText ?? 'Search...');

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.7)
              : AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            size: 20,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  onPressed: _clear,
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}
