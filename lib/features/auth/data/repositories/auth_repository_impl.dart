import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/api/token_storage.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

@Injectable(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  const AuthRepositoryImpl(this._remoteDataSource, this._tokenStorage);

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      await _tokenStorage.saveAccessToken(result.tokens.accessToken);
      await _tokenStorage.saveRefreshToken(result.tokens.refreshToken);
      return Right(result.user.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
      await _tokenStorage.clearTokens();
      return const Right(null);
    } on ServerException catch (e) {
      // Clear tokens regardless
      await _tokenStorage.clearTokens();
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      return Right(user.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    }
  }
}
