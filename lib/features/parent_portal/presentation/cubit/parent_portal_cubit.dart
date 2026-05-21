import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/parent_portal_repository.dart';
import 'parent_portal_state.dart';

class ParentPortalCubit extends Cubit<ParentPortalState> {
  final ParentPortalRepository repository;

  ParentPortalCubit({required this.repository}) : super(ParentPortalInitial());

  Future<void> fetchStudentsByPhone(String phone) async {
    emit(ParentPortalLoading());

    final result = await repository.getStudentsByParentPhone(phone);

    result.fold(
      (failure) => emit(ParentPortalError(message: failure.message)),
      (students) => emit(ParentPortalLoaded(students: students)),
    );
  }
}
