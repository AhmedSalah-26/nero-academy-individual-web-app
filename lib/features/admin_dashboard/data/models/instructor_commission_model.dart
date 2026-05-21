/// Instructor Commission Model — for admin commission management
class InstructorCommissionModel {
  final String instructorId;
  final String? name;
  final String? email;
  final String? avatarUrl;
  final double revenueShare; // instructor's share (e.g. 70%)
  final double commissionRate; // platform's share (e.g. 30%)
  final int totalCourses;
  final int totalStudents;
  final bool isVerified;

  const InstructorCommissionModel({
    required this.instructorId,
    this.name,
    this.email,
    this.avatarUrl,
    required this.revenueShare,
    required this.commissionRate,
    this.totalCourses = 0,
    this.totalStudents = 0,
    this.isVerified = false,
  });

  factory InstructorCommissionModel.fromJson(Map<String, dynamic> json) {
    return InstructorCommissionModel(
      instructorId: json['instructor_id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      revenueShare: (json['revenue_share'] as num?)?.toDouble() ?? 70.0,
      commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 30.0,
      totalCourses: json['total_courses'] as int? ?? 0,
      totalStudents: json['total_students'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  String get displayName => name ?? email?.split('@').first ?? 'Unknown';

  String get formattedCommission => '${commissionRate.toStringAsFixed(0)}%';
  String get formattedRevenueShare => '${revenueShare.toStringAsFixed(0)}%';

  InstructorCommissionModel copyWith({
    double? revenueShare,
    double? commissionRate,
  }) {
    return InstructorCommissionModel(
      instructorId: instructorId,
      name: name,
      email: email,
      avatarUrl: avatarUrl,
      revenueShare: revenueShare ?? this.revenueShare,
      commissionRate: commissionRate ?? this.commissionRate,
      totalCourses: totalCourses,
      totalStudents: totalStudents,
      isVerified: isVerified,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InstructorCommissionModel &&
        other.instructorId == instructorId;
  }

  @override
  int get hashCode => instructorId.hashCode;
}
