import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Registers third-party / platform dependencies that
/// cannot be auto-annotated with @injectable.
@module
abstract class CoreModule {
  @singleton
  Talker get talker => TalkerFlutter.init(
    settings: TalkerSettings(
      useConsoleLogs: kDebugMode,
      useHistory: true,
      maxHistoryItems: 500,
    ),
  );

  @singleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  @preResolve
  @singleton
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @singleton
  FlutterLocalNotificationsPlugin get localNotifications =>
      FlutterLocalNotificationsPlugin();
}
