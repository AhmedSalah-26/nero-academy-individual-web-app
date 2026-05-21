import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../../../../core/base/base_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

/// Auth Repository Implementation
class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required NetworkInfo networkInfo,
  }) : super(networkInfo);

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    _logger.i('🔐 Login attempt for: $email');
    return safeCall(() async {
      final user = await remoteDataSource.login(
        email: email,
        password: password,
      );
      await localDataSource.cacheUser(user);
      _logger.i('✅ Login successful for: ${user.email}');
      return user;
    });
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
    String? headline,
    String? bio,
    List<String>? expertise,
    Uint8List? avatarBytes,
  }) async {
    _logger.i('📝 Register attempt:');
    _logger.d('  Email: $email');
    _logger.d('  Name: $name');
    _logger.d('  Role: ${role.name}');
    _logger.d('  Phone: $phone');
    _logger.d('  Headline: $headline');
    _logger.d('  Bio: ${bio != null ? '${bio.length} chars' : 'null'}');
    _logger.d('  Expertise: $expertise');
    _logger.d(
        '  Avatar: ${avatarBytes != null ? '${avatarBytes.length} bytes' : 'null'}');

    return safeCall(() async {
      final user = await remoteDataSource.register(
        email: email,
        password: password,
        name: name,
        role: role,
        phone: phone,
        headline: headline,
        bio: bio,
        expertise: expertise,
        avatarBytes: avatarBytes,
      );
      await localDataSource.cacheUser(user);
      _logger.i('✅ Registration successful for: ${user.email}');
      return user;
    });
  }

  @override
  Future<Either<Failure, void>> logout() async {
    return safeCall(() async {
      await remoteDataSource.logout();
      await localDataSource.clearCache();
    }, checkConnection: false);
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    // Try to get from remote first
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.getCurrentUser();
        if (user != null) {
          await localDataSource.cacheUser(user);
        }
        return Right(user);
      } catch (e) {
        // Fall back to cache
        final cachedUser = await localDataSource.getCachedUser();
        return Right(cachedUser);
      }
    } else {
      // No network, use cache
      final cachedUser = await localDataSource.getCachedUser();
      return Right(cachedUser);
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final result = await getCurrentUser();
    return result.fold(
      (_) => false,
      (user) => user != null,
    );
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    return safeCall(() => remoteDataSource.forgotPassword(email));
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return safeCall(() => remoteDataSource.resetPassword(
          token: token,
          newPassword: newPassword,
        ));
  }

  @override
  Future<Either<Failure, UserEntity>> updateInterests(
      List<String> interests) async {
    return safeCall(() async {
      final user = await remoteDataSource.updateInterests(interests);
      await localDataSource.cacheUser(user);
      await localDataSource.cacheInterests(interests);
      return user;
    });
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    return safeCall(() async {
      final user = await remoteDataSource.updateProfile(
        name: name,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      await localDataSource.cacheUser(user);
      return user;
    });
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithGoogle() async {
    return safeCall(() async {
      final user = await remoteDataSource.loginWithGoogle();
      await localDataSource.cacheUser(user);
      return user;
    });
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithApple() async {
    return safeCall(() async {
      final user = await remoteDataSource.loginWithApple();
      await localDataSource.cacheUser(user);
      return user;
    });
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithFacebook() async {
    return safeCall(() async {
      final user = await remoteDataSource.loginWithFacebook();
      await localDataSource.cacheUser(user);
      return user;
    });
  }

  @override
  Future<Either<Failure, void>> sendPhoneOtp(String phoneNumber) async {
    return safeCall(() => remoteDataSource.sendPhoneOtp(phoneNumber));
  }

  @override
  Future<Either<Failure, UserEntity>> verifyPhoneOtp(
      String phoneNumber, String otp) async {
    _logger.i('🔐 [Repository] Verifying phone OTP');
    _logger.d('  Phone: $phoneNumber');
    _logger.d('  OTP: $otp');

    return safeCall(() async {
      _logger.d('  Calling remote data source...');
      final user = await remoteDataSource.verifyPhoneOtp(phoneNumber, otp);

      _logger.i('✅ [Repository] User verified: ${user.name}');
      _logger.d('  Caching user...');
      await localDataSource.cacheUser(user);

      _logger.i('✅ [Repository] User cached successfully');
      return user;
    });
  }

  @override
  Future<Either<Failure, void>> sendLinkPhoneOtp(String phoneNumber) async {
    _logger.i('📱 [Repository] Sending OTP to link phone: $phoneNumber');
    return safeCall(() => remoteDataSource.sendLinkPhoneOtp(phoneNumber));
  }

  @override
  Future<Either<Failure, UserEntity>> verifyLinkPhoneOtp(
      String phoneNumber, String otp) async {
    _logger.i('🔐 [Repository] Verifying OTP to link phone');
    return safeCall(() async {
      final user = await remoteDataSource.verifyLinkPhoneOtp(phoneNumber, otp);
      await localDataSource.cacheUser(user);
      _logger.i('✅ [Repository] Phone linked successfully');
      return user;
    });
  }

  @override
  Stream<UserEntity?> get authStateChanges => remoteDataSource.authStateChanges;
}
