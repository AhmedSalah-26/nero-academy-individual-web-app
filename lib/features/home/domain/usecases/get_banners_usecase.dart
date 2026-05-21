import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/banner_entity.dart';
import '../repositories/home_repository.dart';

/// Get Banners UseCase
class GetBannersUseCase implements UseCase<List<BannerEntity>> {
  final HomeRepository repository;

  GetBannersUseCase(this.repository);

  @override
  Future<Either<Failure, List<BannerEntity>>> call() {
    return repository.getBanners();
  }
}
