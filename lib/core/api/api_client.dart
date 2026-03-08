import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

import '../env/app_config.dart';
import 'auth_interceptor.dart';

@singleton
class ApiClient {
  late final Dio _dio;

  Dio get dio => _dio;

  @factoryMethod
  ApiClient(AuthInterceptor authInterceptor, Talker talker) {
    _dio =
        Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'Content-Type': 'application/json'},
            ),
          )
          ..interceptors.add(authInterceptor)
          ..interceptors.add(
            TalkerDioLogger(
              talker: talker,
              settings: const TalkerDioLoggerSettings(
                printRequestHeaders: true,
                printResponseHeaders: false,
                printResponseData: true,
              ),
            ),
          );
  }
}
