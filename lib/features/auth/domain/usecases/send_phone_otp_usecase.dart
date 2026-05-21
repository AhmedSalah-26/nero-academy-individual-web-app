import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class SendPhoneOtpUseCase implements UseCaseWithParams<void, String> {
  final AuthRepository repository;

  SendPhoneOtpUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String phoneNumber) async {
    return await repository.sendPhoneOtp(phoneNumber);
  }

  /// إرسال OTP لربط الهاتف بحساب موجود
  Future<Either<Failure, void>> sendLinkOtp(String phoneNumber) async {
    return await repository.sendLinkPhoneOtp(phoneNumber);
  }
}
