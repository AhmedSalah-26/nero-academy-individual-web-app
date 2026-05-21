/// Instructor Dashboard Entities
library instructor_entities;

/// Instructor Dashboard Statistics Entity
class InstructorDashboardStats {
  final int totalCourses;
  final int publishedCourses;
  final int totalStudents;
  final int totalEnrollments;
  final int monthlyEnrollments;
  final double totalEarnings;
  final double availableBalance;
  final double pendingBalance;
  final double averageRating;
  final int totalReviews;
  final int unansweredQuestions;

  const InstructorDashboardStats({
    required this.totalCourses,
    required this.publishedCourses,
    required this.totalStudents,
    required this.totalEnrollments,
    required this.monthlyEnrollments,
    required this.totalEarnings,
    required this.availableBalance,
    required this.pendingBalance,
    required this.averageRating,
    required this.totalReviews,
    required this.unansweredQuestions,
  });

  static const empty = InstructorDashboardStats(
    totalCourses: 0,
    publishedCourses: 0,
    totalStudents: 0,
    totalEnrollments: 0,
    monthlyEnrollments: 0,
    totalEarnings: 0,
    availableBalance: 0,
    pendingBalance: 0,
    averageRating: 0,
    totalReviews: 0,
    unansweredQuestions: 0,
  );
}

/// Instructor Course Status
enum InstructorCourseStatus { all, published, draft, suspended }

extension InstructorCourseStatusExtension on InstructorCourseStatus {
  String getLabel(bool isArabic) {
    switch (this) {
      case InstructorCourseStatus.all:
        return isArabic ? 'الكل' : 'All';
      case InstructorCourseStatus.published:
        return isArabic ? 'منشور' : 'Published';
      case InstructorCourseStatus.draft:
        return isArabic ? 'مسودة' : 'Draft';
      case InstructorCourseStatus.suspended:
        return isArabic ? 'موقوف' : 'Suspended';
    }
  }
}

/// Instructor Enrollment Status
enum InstructorEnrollmentStatus { all, active, completed }

extension InstructorEnrollmentStatusExtension on InstructorEnrollmentStatus {
  String getLabel(bool isArabic) {
    switch (this) {
      case InstructorEnrollmentStatus.all:
        return isArabic ? 'الكل' : 'All';
      case InstructorEnrollmentStatus.active:
        return isArabic ? 'نشط' : 'Active';
      case InstructorEnrollmentStatus.completed:
        return isArabic ? 'مكتمل' : 'Completed';
    }
  }
}

/// Withdraw Request Status (NEW SCHEMA)
enum WithdrawRequestStatus { pending, approved, rejected, paid }

extension WithdrawRequestStatusExtension on WithdrawRequestStatus {
  String getLabel(bool isArabic) {
    switch (this) {
      case WithdrawRequestStatus.pending:
        return isArabic ? 'قيد الانتظار' : 'Pending';
      case WithdrawRequestStatus.approved:
        return isArabic ? 'تمت الموافقة' : 'Approved';
      case WithdrawRequestStatus.rejected:
        return isArabic ? 'مرفوض' : 'Rejected';
      case WithdrawRequestStatus.paid:
        return isArabic ? 'تم الدفع' : 'Paid';
    }
  }
}

/// Q&A Status
enum QAStatus { all, unanswered, answered }

extension QAStatusExtension on QAStatus {
  String getLabel(bool isArabic) {
    switch (this) {
      case QAStatus.all:
        return isArabic ? 'الكل' : 'All';
      case QAStatus.unanswered:
        return isArabic ? 'بدون إجابة' : 'Unanswered';
      case QAStatus.answered:
        return isArabic ? 'تمت الإجابة' : 'Answered';
    }
  }
}

/// Quiz Question Type
enum QuizQuestionType { singleChoice, multipleChoice, trueFalse, shortAnswer }

extension QuizQuestionTypeExtension on QuizQuestionType {
  String getLabel(bool isArabic) {
    switch (this) {
      case QuizQuestionType.singleChoice:
        return isArabic ? 'اختيار واحد' : 'Single Choice';
      case QuizQuestionType.multipleChoice:
        return isArabic ? 'اختيار متعدد' : 'Multiple Choice';
      case QuizQuestionType.trueFalse:
        return isArabic ? 'صح/خطأ' : 'True/False';
      case QuizQuestionType.shortAnswer:
        return isArabic ? 'إجابة قصيرة' : 'Short Answer';
    }
  }
}
