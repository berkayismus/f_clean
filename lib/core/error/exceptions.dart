class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException(this.message, {this.statusCode});
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error']);
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([this.message = 'Unauthorized']);
}
