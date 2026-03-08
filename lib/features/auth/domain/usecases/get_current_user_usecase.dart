import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

@injectable
class GetCurrentUserUseCase {
  final AuthRepository _repository;
  const GetCurrentUserUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call() => _repository.getCurrentUser();
}
