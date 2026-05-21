/// Earnings Transaction Model — mirrors earnings_transactions table
class EarningsTransactionModel {
  final String id;
  final String userId;
  final String? courseId;
  final String courseName;
  final double amount;
  final double commission;
  final double originalPrice;
  final double couponDiscount;
  final EarningStatus status;
  final EarningSourceType sourceType;
  final DateTime createdAt;

  const EarningsTransactionModel({
    required this.id,
    required this.userId,
    this.courseId,
    required this.courseName,
    required this.amount,
    required this.commission,
    this.originalPrice = 0,
    this.couponDiscount = 0,
    required this.status,
    required this.sourceType,
    required this.createdAt,
  });

  /// Net amount after commission and coupon discount
  double get netAmount => amount - commission - couponDiscount;

  factory EarningsTransactionModel.fromJson(Map<String, dynamic> json) {
    return EarningsTransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      courseId: json['course_id'] as String?,
      courseName: json['course_name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      commission: (json['commission'] as num?)?.toDouble() ?? 0,
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? 0,
      couponDiscount: (json['coupon_discount'] as num?)?.toDouble() ?? 0,
      status: EarningStatus.fromString(json['status'] as String?),
      sourceType: EarningSourceType.fromString(json['source_type'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Earning Status
enum EarningStatus {
  available,
  pending,
  paid;

  static EarningStatus fromString(String? value) {
    switch (value) {
      case 'available':
        return EarningStatus.available;
      case 'pending':
        return EarningStatus.pending;
      case 'paid':
        return EarningStatus.paid;
      default:
        return EarningStatus.pending;
    }
  }

  String toJsonValue() {
    switch (this) {
      case EarningStatus.available:
        return 'available';
      case EarningStatus.pending:
        return 'pending';
      case EarningStatus.paid:
        return 'paid';
    }
  }

  String getLabel(bool isArabic) {
    switch (this) {
      case EarningStatus.available:
        return isArabic ? 'متاح' : 'Available';
      case EarningStatus.pending:
        return isArabic ? 'معلق' : 'Pending';
      case EarningStatus.paid:
        return isArabic ? 'مدفوع' : 'Paid';
    }
  }
}

/// Earning Source Type
enum EarningSourceType {
  courseSale,
  refund,
  adjustment;

  static EarningSourceType fromString(String? value) {
    switch (value) {
      case 'course_sale':
        return EarningSourceType.courseSale;
      case 'refund':
        return EarningSourceType.refund;
      case 'adjustment':
        return EarningSourceType.adjustment;
      default:
        return EarningSourceType.courseSale;
    }
  }

  String toJsonValue() {
    switch (this) {
      case EarningSourceType.courseSale:
        return 'course_sale';
      case EarningSourceType.refund:
        return 'refund';
      case EarningSourceType.adjustment:
        return 'adjustment';
    }
  }

  String getLabel(bool isArabic) {
    switch (this) {
      case EarningSourceType.courseSale:
        return isArabic ? 'بيع كورس' : 'Course Sale';
      case EarningSourceType.refund:
        return isArabic ? 'استرداد' : 'Refund';
      case EarningSourceType.adjustment:
        return isArabic ? 'تعديل' : 'Adjustment';
    }
  }
}
