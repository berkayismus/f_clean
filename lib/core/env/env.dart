import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env.dev', obfuscate: true)
abstract class DevEnv {
  @EnviedField(varName: 'API_BASE_URL')
  static final String apiBaseUrl = _DevEnv.apiBaseUrl;

  @EnviedField(varName: 'SENTRY_DSN')
  static final String sentryDsn = _DevEnv.sentryDsn;
}

@Envied(path: '.env.prod', obfuscate: true)
abstract class ProdEnv {
  @EnviedField(varName: 'API_BASE_URL')
  static final String apiBaseUrl = _ProdEnv.apiBaseUrl;

  @EnviedField(varName: 'SENTRY_DSN')
  static final String sentryDsn = _ProdEnv.sentryDsn;
}
