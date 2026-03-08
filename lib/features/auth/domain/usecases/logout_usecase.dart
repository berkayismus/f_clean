import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

@injectable
class LogoutUseCase {
  final AuthRepository _repository;
  const LogoutUseCase(this._repository);

  Future<Either<Failure, void>> call() => _repository.logout();
}
