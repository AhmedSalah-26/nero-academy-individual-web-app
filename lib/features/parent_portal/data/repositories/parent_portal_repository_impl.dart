import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/parent_dashboard_entity.dart';
import '../../domain/repositories/parent_portal_repository.dart';
import '../datasources/parent_portal_data_source.dart';

class ParentPortalRepositoryImpl implements ParentPortalRepository {
  final ParentPortalDataSource dataSource;

  ParentPortalRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<StudentDashboardData>>> getStudentsByParentPhone(
      String phone) async {
    try {
      AppLogger.i(
          '👨‍👩‍👦 [ParentPortalRepo] Fetching students for parent phone: $phone');
      final result = await dataSource.getStudentsByParentPhone(phone);
      AppLogger.success(
          '👨‍👩‍👦 [ParentPortalRepo] Found ${result.length} students');
      return Right(result);
    } catch (e) {
      AppLogger.e('[ParentPortalRepo] Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
