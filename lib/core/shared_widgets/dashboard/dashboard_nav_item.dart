import 'package:flutter/material.dart';

/// Dashboard Navigation Item Model
class DashboardNavItem {
  final String label;
  final String labelAr;
  final IconData icon;
  final String? badge;

  const DashboardNavItem({
    required this.label,
    required this.labelAr,
    required this.icon,
    this.badge,
  });

  String getLabel(bool isArabic) => isArabic ? labelAr : label;
}
