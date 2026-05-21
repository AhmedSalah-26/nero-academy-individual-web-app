part of 'instructor_dashboard_cubit.dart';

enum InstructorDashboardStatus { initial, loading, success, error }

class InstructorDashboardState extends Equatable {
  final InstructorDashboardStatus status;
  final InstructorDashboardStats stats;
  final List<ChartDataPoint> revenueChart;
  final List<ChartDataPoint> enrollmentsChart;
  final DateTime startDate;
  final DateTime endDate;
  final String? errorMessage;

  InstructorDashboardState({
    this.status = InstructorDashboardStatus.initial,
    this.stats = InstructorDashboardStats.empty,
    this.revenueChart = const [],
    this.enrollmentsChart = const [],
    DateTime? startDate,
    DateTime? endDate,
    this.errorMessage,
  })  : startDate =
            startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate = endDate ?? DateTime.now();

  bool get isLoading => status == InstructorDashboardStatus.loading;
  bool get hasError => status == InstructorDashboardStatus.error;

  InstructorDashboardState copyWith({
    InstructorDashboardStatus? status,
    InstructorDashboardStats? stats,
    List<ChartDataPoint>? revenueChart,
    List<ChartDataPoint>? enrollmentsChart,
    DateTime? startDate,
    DateTime? endDate,
    String? errorMessage,
  }) {
    return InstructorDashboardState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
      revenueChart: revenueChart ?? this.revenueChart,
      enrollmentsChart: enrollmentsChart ?? this.enrollmentsChart,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        stats,
        revenueChart,
        enrollmentsChart,
        startDate,
        endDate,
        errorMessage
      ];
}
