/// Instructor Enrollment Model
class InstructorEnrollmentModel {
  final String id;
  final String courseId;
  final String courseTitle;
  final String? courseTitleAr;
  final String studentId;
  final String studentName;
  final String? studentAvatar;
  final double? paidAmount;
  final double progressPercent;
  final String status; // pending, active, completed, expired, refunded
  final DateTime enrolledAt;
  final DateTime? completedAt;
  final DateTime? lastAccessedAt;

  const InstructorEnrollmentModel({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    this.courseTitleAr,
    required this.studentId,
    required this.studentName,
    this.studentAvatar,
    this.paidAmount,
    required this.progressPercent,
    required this.status,
    required this.enrolledAt,
    this.completedAt,
    this.lastAccessedAt,
  });

  bool get isCompleted => status == 'completed';

  factory InstructorEnrollmentModel.fromJson(Map<String, dynamic> json) {
    return InstructorEnrollmentModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      courseTitle: json['course']?['title_en'] as String? ??
          json['course']?['title_ar'] as String? ??
          '',
      courseTitleAr: json['course']?['title_ar'] as String?,
      studentId: json['user_id'] as String,
      studentName: json['user']?['name'] as String? ?? 'Unknown',
      studentAvatar: json['user']?['avatar_url'] as String?,
      paidAmount: (json['price'] as num?)?.toDouble(),
      progressPercent: (json['progress_percentage'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'active',
      enrolledAt: DateTime.parse(json['enrolled_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      lastAccessedAt: json['last_accessed_at'] != null
          ? DateTime.tryParse(json['last_accessed_at'] as String)
          : null,
    );
  }
}
