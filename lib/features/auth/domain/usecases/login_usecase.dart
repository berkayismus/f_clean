import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginParams extends Equatable {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

@injectable
class LoginUseCase {
  final AuthRepository _repository;
  const LoginUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call(LoginParams params) =>
      _repository.login(email: params.email, password: params.password);
}
