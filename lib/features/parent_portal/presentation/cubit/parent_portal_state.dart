import 'package:equatable/equatable.dart';
import '../../domain/entities/parent_dashboard_entity.dart';

abstract class ParentPortalState extends Equatable {
  const ParentPortalState();

  @override
  List<Object> get props => [];
}

class ParentPortalInitial extends ParentPortalState {}

class ParentPortalLoading extends ParentPortalState {}

class ParentPortalLoaded extends ParentPortalState {
  final List<StudentDashboardData> students;

  const ParentPortalLoaded({required this.students});

  @override
  List<Object> get props => [students];
}

class ParentPortalError extends ParentPortalState {
  final String message;

  const ParentPortalError({required this.message});

  @override
  List<Object> get props => [message];
}
