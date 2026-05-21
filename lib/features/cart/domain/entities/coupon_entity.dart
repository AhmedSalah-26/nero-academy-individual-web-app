import 'package:equatable/equatable.dart';

/// Discount Type Enum
enum DiscountType {
  percentage,
  fixed;

  static DiscountType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'percentage':
        return DiscountType.percentage;
      case 'fixed':
        return DiscountType.fixed;
      default:
        return DiscountType.percentage;
    }
  }
}

/// Coupon Entity - Pure Dart Object
class CouponEntity extends Equatable {
  final String id;
  final String code;
  final String? nameAr;
  final String? nameEn;
  final DiscountType discountType;
  final double discountValue;
  final double? maxDiscountAmount;
  final double? minOrderAmount;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  const CouponEntity({
    required this.id,
    required this.code,
    this.nameAr,
    this.nameEn,
    this.discountType = DiscountType.percentage,
    this.discountValue = 0,
    this.maxDiscountAmount,
    this.minOrderAmount,
    this.startDate,
    this.endDate,
    this.isActive = true,
  });

  /// Get name based on locale
  String getName(String locale) =>
      locale == 'ar' ? (nameAr ?? nameEn ?? code) : (nameEn ?? nameAr ?? code);

  /// Calculate discount amount for a given subtotal
  double calculateDiscount(double subtotal) {
    if (!isActive) return 0;
    if (minOrderAmount != null && subtotal < minOrderAmount!) return 0;

    double discount;
    if (discountType == DiscountType.percentage) {
      discount = subtotal * (discountValue / 100);
    } else {
      discount = discountValue;
    }

    if (maxDiscountAmount != null && discount > maxDiscountAmount!) {
      discount = maxDiscountAmount!;
    }

    return discount > subtotal ? subtotal : discount;
  }

  /// Check if coupon is valid
  bool get isValid {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  @override
  List<Object?> get props => [id, code, discountType, discountValue, isActive];
}
