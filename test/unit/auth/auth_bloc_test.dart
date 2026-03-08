import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:f_clean/core/error/failures.dart';
import 'package:f_clean/features/auth/domain/entities/user_entity.dart';
import 'package:f_clean/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:f_clean/features/auth/domain/usecases/login_usecase.dart';
import 'package:f_clean/features/auth/domain/usecases/logout_usecase.dart';
import 'package:f_clean/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:f_clean/features/auth/presentation/bloc/auth_event.dart';
import 'package:f_clean/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

void main() {
  late MockLoginUseCase mockLoginUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;

  const tUser = UserEntity(id: '1', email: 'test@example.com', name: 'Test');

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();

    registerFallbackValue(
      const LoginParams(email: 'test@example.com', password: '123456'),
    );
  });

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when AppStarted and user exists',
      build: () {
        when(
          () => mockGetCurrentUserUseCase(),
        ).thenAnswer((_) async => const Right(tUser));
        return AuthBloc(
          mockLoginUseCase,
          mockLogoutUseCase,
          mockGetCurrentUserUseCase,
        );
      },
      act: (bloc) => bloc.add(const AppStarted()),
      expect: () => [const AuthLoading(), const AuthAuthenticated(tUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when AppStarted and no user',
      build: () {
        when(
          () => mockGetCurrentUserUseCase(),
        ).thenAnswer((_) async => const Left(UnauthorizedFailure()));
        return AuthBloc(
          mockLoginUseCase,
          mockLogoutUseCase,
          mockGetCurrentUserUseCase,
        );
      },
      act: (bloc) => bloc.add(const AppStarted()),
      expect: () => [const AuthLoading(), const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on successful login',
      build: () {
        when(
          () => mockLoginUseCase(any()),
        ).thenAnswer((_) async => const Right(tUser));
        return AuthBloc(
          mockLoginUseCase,
          mockLogoutUseCase,
          mockGetCurrentUserUseCase,
        );
      },
      act: (bloc) => bloc.add(
        const LoginRequested(email: 'test@example.com', password: '123456'),
      ),
      expect: () => [const AuthLoading(), const AuthAuthenticated(tUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on failed login',
      build: () {
        when(() => mockLoginUseCase(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Invalid credentials')),
        );
        return AuthBloc(
          mockLoginUseCase,
          mockLogoutUseCase,
          mockGetCurrentUserUseCase,
        );
      },
      act: (bloc) => bloc.add(
        const LoginRequested(email: 'test@example.com', password: 'wrong'),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError('Invalid credentials'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] on logout',
      build: () {
        when(
          () => mockLogoutUseCase(),
        ).thenAnswer((_) async => const Right(null));
        return AuthBloc(
          mockLoginUseCase,
          mockLogoutUseCase,
          mockGetCurrentUserUseCase,
        );
      },
      act: (bloc) => bloc.add(const LogoutRequested()),
      expect: () => [const AuthLoading(), const AuthUnauthenticated()],
    );
  });
}
