import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/portfolio_entity.dart';
import '../repositories/portfolio_repository.dart';

/// Get Portfolio Use Case
class GetPortfolioUseCase
    implements UseCaseWithParams<PortfolioEntity, GetPortfolioParams> {
  final PortfolioRepository repository;

  GetPortfolioUseCase(this.repository);

  @override
  Future<Either<Failure, PortfolioEntity>> call(GetPortfolioParams params) {
    return repository.getPortfolio(userId: params.userId);
  }
}

/// Get Portfolio Params
class GetPortfolioParams {
  final String userId;

  const GetPortfolioParams({required this.userId});
}
