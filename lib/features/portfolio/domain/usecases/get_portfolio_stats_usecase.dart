import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/portfolio_entity.dart';
import '../repositories/portfolio_repository.dart';

/// Get Portfolio Stats Use Case
class GetPortfolioStatsUseCase
    implements
        UseCaseWithParams<PortfolioStatsEntity, GetPortfolioStatsParams> {
  final PortfolioRepository repository;

  GetPortfolioStatsUseCase(this.repository);

  @override
  Future<Either<Failure, PortfolioStatsEntity>> call(
      GetPortfolioStatsParams params) {
    return repository.getPortfolioStats(userId: params.userId);
  }
}

/// Get Portfolio Stats Params
class GetPortfolioStatsParams {
  final String userId;

  const GetPortfolioStatsParams({required this.userId});
}
