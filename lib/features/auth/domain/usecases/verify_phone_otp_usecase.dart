import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class VerifyPhoneOtpParams {
  final String phoneNumber;
  final String otp;

  VerifyPhoneOtpParams({
    required this.phoneNumber,
    required this.otp,
  });
}

class VerifyPhoneOtpUseCase
    implements UseCaseWithParams<UserEntity, VerifyPhoneOtpParams> {
  final AuthRepository repository;

  VerifyPhoneOtpUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(VerifyPhoneOtpParams params) async {
    return await repository.verifyPhoneOtp(params.phoneNumber, params.otp);
  }

  /// تأكيد OTP وربط الهاتف بالحساب الموجود
  Future<Either<Failure, UserEntity>> verifyLinkOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    return await repository.verifyLinkPhoneOtp(phoneNumber, otp);
  }
}
