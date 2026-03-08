import 'package:flutter/foundation.dart';

import 'env.dart';

class AppConfig {
  static String get apiBaseUrl =>
      kReleaseMode ? ProdEnv.apiBaseUrl : DevEnv.apiBaseUrl;

  static String get sentryDsn =>
      kReleaseMode ? ProdEnv.sentryDsn : DevEnv.sentryDsn;
}
