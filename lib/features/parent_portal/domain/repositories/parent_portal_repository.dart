import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/parent_dashboard_entity.dart';

abstract class ParentPortalRepository {
  Future<Either<Failure, List<StudentDashboardData>>> getStudentsByParentPhone(
      String phone);
}
