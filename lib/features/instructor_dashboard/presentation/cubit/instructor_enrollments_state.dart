part of 'instructor_enrollments_cubit.dart';

/// Instructor Enrollments Status
enum InstructorEnrollmentsStatus { initial, loading, success, error }

/// Enrollment Status Filter
enum EnrollmentStatusFilter { all, active, completed, refunded }

/// Instructor Enrollments State
class InstructorEnrollmentsState extends Equatable {
  final InstructorEnrollmentsStatus status;
  final List<InstructorEnrollmentModel> enrollments;
  final EnrollmentStatusFilter filter;
  final String? selectedCourseId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isLoadingMore;
  final bool hasMore;
  final double totalRevenue;
  final int totalEnrollments;
  final String? errorMessage;

  const InstructorEnrollmentsState({
    this.status = InstructorEnrollmentsStatus.initial,
    this.enrollments = const [],
    this.filter = EnrollmentStatusFilter.all,
    this.selectedCourseId,
    this.startDate,
    this.endDate,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.totalRevenue = 0,
    this.totalEnrollments = 0,
    this.errorMessage,
  });

  bool get isLoading => status == InstructorEnrollmentsStatus.loading;

  List<InstructorEnrollmentModel> get filteredEnrollments {
    switch (filter) {
      case EnrollmentStatusFilter.active:
        return enrollments.where((e) => e.status == 'active').toList();
      case EnrollmentStatusFilter.completed:
        return enrollments.where((e) => e.status == 'completed').toList();
      case EnrollmentStatusFilter.refunded:
        return enrollments.where((e) => e.status == 'refunded').toList();
      case EnrollmentStatusFilter.all:
        return enrollments;
    }
  }

  InstructorEnrollmentsState copyWith({
    InstructorEnrollmentsStatus? status,
    List<InstructorEnrollmentModel>? enrollments,
    EnrollmentStatusFilter? filter,
    String? selectedCourseId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isLoadingMore,
    bool? hasMore,
    double? totalRevenue,
    int? totalEnrollments,
    String? errorMessage,
    bool clearCourseId = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return InstructorEnrollmentsState(
      status: status ?? this.status,
      enrollments: enrollments ?? this.enrollments,
      filter: filter ?? this.filter,
      selectedCourseId:
          clearCourseId ? null : (selectedCourseId ?? this.selectedCourseId),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalEnrollments: totalEnrollments ?? this.totalEnrollments,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        enrollments,
        filter,
        selectedCourseId,
        startDate,
        endDate,
        isLoadingMore,
        hasMore,
        totalRevenue,
        totalEnrollments,
        errorMessage,
      ];
}
