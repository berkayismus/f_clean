import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../env/app_config.dart';
import 'token_storage.dart';

@singleton
class AuthInterceptor extends QueuedInterceptorsWrapper {
  final TokenStorage _tokenStorage;
  final Dio _refreshDio;

  AuthInterceptor(this._tokenStorage)
    : _refreshDio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 30),
        ),
      );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        final newToken = await _refreshToken();
        if (newToken != null) {
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final response = await _refreshDio.fetch<dynamic>(opts);
          handler.resolve(response);
          return;
        }
      } catch (_) {
        await _tokenStorage.clearTokens();
      }
    }
    handler.next(err);
  }

  Future<String?> _refreshToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) return null;

    final response = await _refreshDio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = response.data as Map<String, dynamic>;
    final accessToken = data['accessToken'] as String;
    final newRefresh = data['refreshToken'] as String?;

    await _tokenStorage.saveAccessToken(accessToken);
    if (newRefresh != null) {
      await _tokenStorage.saveRefreshToken(newRefresh);
    }
    return accessToken;
  }
}
