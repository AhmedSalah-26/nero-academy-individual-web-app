part of 'admin_commission_cubit.dart';

/// Status for admin commission operations
enum AdminCommissionStatus {
  initial,
  loading,
  success,
  error,
  processing,
}

/// State for admin commission management
class AdminCommissionState extends Equatable {
  final AdminCommissionStatus status;
  final AdminCommissionStatus actionStatus;
  final List<InstructorCommissionModel> instructors;
  final String searchQuery;
  final String? errorMessage;
  final String? successMessage;

  const AdminCommissionState({
    this.status = AdminCommissionStatus.initial,
    this.actionStatus = AdminCommissionStatus.initial,
    this.instructors = const [],
    this.searchQuery = '',
    this.errorMessage,
    this.successMessage,
  });

  AdminCommissionState copyWith({
    AdminCommissionStatus? status,
    AdminCommissionStatus? actionStatus,
    List<InstructorCommissionModel>? instructors,
    String? searchQuery,
    String? errorMessage,
    String? successMessage,
  }) {
    return AdminCommissionState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      instructors: instructors ?? this.instructors,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        instructors,
        searchQuery,
        errorMessage,
        successMessage,
      ];
}
