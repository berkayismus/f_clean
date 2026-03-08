import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

@singleton
class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications;

  const NotificationService(this._localNotifications);

  Future<void> initialize({
    required void Function(String? route) onNotificationTap,
  }) async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (details) {
        onNotificationTap(details.payload);
      },
    );
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload,
    );
  }

  Future<void> cancel(int id) => _localNotifications.cancel(id: id);

  Future<void> cancelAll() => _localNotifications.cancelAll();
}
