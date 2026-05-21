import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/datasources/admin_commission_data_source.dart';
import '../../data/models/instructor_commission_model.dart';

part 'admin_commission_state.dart';

/// Admin Commission Cubit — manages instructor commission rates
class AdminCommissionCubit extends Cubit<AdminCommissionState> {
  final AdminCommissionDataSource _dataSource;

  AdminCommissionCubit(this._dataSource) : super(const AdminCommissionState());

  /// Load all instructor commissions
  Future<void> loadCommissions() async {
    emit(state.copyWith(status: AdminCommissionStatus.loading));

    try {
      final commissions = await _dataSource.getInstructorCommissions();
      emit(state.copyWith(
        status: AdminCommissionStatus.success,
        instructors: commissions,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminCommissionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Set commission rate for a specific instructor
  Future<void> setCommission(
    String instructorId,
    double commissionRate,
  ) async {
    emit(state.copyWith(actionStatus: AdminCommissionStatus.processing));

    try {
      await _dataSource.setInstructorCommission(instructorId, commissionRate);

      // Update the local list
      final updatedList = state.instructors.map((inst) {
        if (inst.instructorId == instructorId) {
          return inst.copyWith(
            commissionRate: commissionRate,
            revenueShare: 100 - commissionRate,
          );
        }
        return inst;
      }).toList();

      emit(state.copyWith(
        actionStatus: AdminCommissionStatus.success,
        instructors: updatedList,
        successMessage:
            'Commission updated to ${commissionRate.toStringAsFixed(0)}%',
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminCommissionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Filter instructors by search
  void filterInstructors(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  /// Get filtered list
  List<InstructorCommissionModel> get filteredInstructors {
    if (state.searchQuery.isEmpty) return state.instructors;
    final q = state.searchQuery.toLowerCase();
    return state.instructors.where((inst) {
      return (inst.name?.toLowerCase().contains(q) ?? false) ||
          (inst.email?.toLowerCase().contains(q) ?? false);
    }).toList();
  }
}
