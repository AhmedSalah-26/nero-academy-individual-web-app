/// Withdraw Request Model — mirrors withdraw_requests table
class WithdrawRequestModel {
  final String id;
  final String userId;
  final double amount;
  final WithdrawStatus status;
  final String method;
  final Map<String, dynamic>? accountDetails;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? paidAt;
  final String? adminId;
  final String? notes;

  const WithdrawRequestModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    required this.method,
    this.accountDetails,
    required this.requestedAt,
    this.approvedAt,
    this.paidAt,
    this.adminId,
    this.notes,
  });

  factory WithdrawRequestModel.fromJson(Map<String, dynamic> json) {
    return WithdrawRequestModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: WithdrawStatus.fromString(json['status'] as String?),
      method: json['method'] as String? ?? '',
      accountDetails: json['account_details'] as Map<String, dynamic>?,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      adminId: json['admin_id'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

/// Withdraw Request Status
enum WithdrawStatus {
  pending,
  approved,
  rejected,
  paid;

  static WithdrawStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return WithdrawStatus.pending;
      case 'approved':
        return WithdrawStatus.approved;
      case 'rejected':
        return WithdrawStatus.rejected;
      case 'paid':
        return WithdrawStatus.paid;
      default:
        return WithdrawStatus.pending;
    }
  }

  String toJsonValue() {
    switch (this) {
      case WithdrawStatus.pending:
        return 'pending';
      case WithdrawStatus.approved:
        return 'approved';
      case WithdrawStatus.rejected:
        return 'rejected';
      case WithdrawStatus.paid:
        return 'paid';
    }
  }

  String getLabel(bool isArabic) {
    switch (this) {
      case WithdrawStatus.pending:
        return isArabic ? 'قيد الانتظار' : 'Pending';
      case WithdrawStatus.approved:
        return isArabic ? 'تمت الموافقة' : 'Approved';
      case WithdrawStatus.rejected:
        return isArabic ? 'مرفوض' : 'Rejected';
      case WithdrawStatus.paid:
        return isArabic ? 'تم الدفع' : 'Paid';
    }
  }

  bool get isTerminal =>
      this == WithdrawStatus.paid || this == WithdrawStatus.rejected;
}
