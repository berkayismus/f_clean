import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/token_storage.dart';
import '../../../../core/error/exceptions.dart';
import '../models/token_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<({TokenModel tokens, UserModel user})> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<UserModel> getCurrentUser();
}

@Injectable(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  const AuthRemoteDataSourceImpl(this._apiClient, this._tokenStorage);

  // Debug-only test credentials — production build'de derlenmez
  static const _debugEmail = 'test@email.com';
  static const _debugPassword = '123456';
  static const _debugAccessToken = 'debug-access-token';

  @override
  Future<({TokenModel tokens, UserModel user})> login({
    required String email,
    required String password,
  }) async {
    if (kDebugMode && email == _debugEmail && password == _debugPassword) {
      return (
        tokens: const TokenModel(
          accessToken: _debugAccessToken,
          refreshToken: 'debug-refresh-token',
        ),
        user: const UserModel(
          id: 'debug-user-1',
          email: _debugEmail,
          name: 'Debug User',
        ),
      );
    }

    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data!;
      return (
        tokens: TokenModel.fromJson(data),
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Login failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.dio.post<void>('/auth/logout');
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Logout failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    if (kDebugMode) {
      final token = await _tokenStorage.getAccessToken();
      if (token == _debugAccessToken) {
        return const UserModel(
          id: 'debug-user-1',
          email: _debugEmail,
          name: 'Debug User',
        );
      }
    }

    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/auth/me',
      );
      return UserModel.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException();
      }
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Failed to get user',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
