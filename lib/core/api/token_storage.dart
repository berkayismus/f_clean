import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@singleton
class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  const TokenStorage(this._storage);

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
