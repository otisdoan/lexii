import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const AndroidNotificationChannel _fcmForegroundChannel =
    AndroidNotificationChannel(
      'fcm_foreground_channel',
      'FCM Foreground Notifications',
      description: 'Shows push notifications while app is in foreground.',
      importance: Importance.max,
    );

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Ignore duplicate init or missing configuration in background isolate.
  }

  await FcmNotificationService.showBackgroundNotification(message);
}

class FcmNotificationService {
  FcmNotificationService._();

  static final FcmNotificationService instance = FcmNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _initializeLocalNotifications();
    await _requestFcmPermission();
    await _setupForegroundPresentation();
    await _ensureAndroidChannel();
    await _logCurrentToken();

    _listenForegroundMessages();
    _listenNotificationTapFromBackground();

    _isInitialized = true;
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> _requestFcmPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _setupForegroundPresentation() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> _ensureAndroidChannel() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_fcmForegroundChannel);
  }

  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await _showLocalFromMessage(message);
    });
  }

  void _listenNotificationTapFromBackground() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log(
        'FCM opened app from background: ${message.messageId}',
        name: 'FCM',
      );
    });
  }

  Future<void> _logCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      developer.log('FCM token: $token', name: 'FCM');

      _messaging.onTokenRefresh.listen((newToken) {
        developer.log('FCM token refreshed: $newToken', name: 'FCM');
      });
    } catch (error) {
      developer.log('Cannot get FCM token: $error', name: 'FCM');
    }
  }

  Future<void> _showLocalFromMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'];
    final body = notification?.body ?? message.data['body'];

    if (title == null && body == null) return;

    await _localNotifications.show(
      message.messageId.hashCode,
      title ?? 'Lexii',
      body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fcm_foreground_channel',
          'FCM Foreground Notifications',
          channelDescription:
              'Shows push notifications while app is in foreground.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'fcm_foreground',
    );
  }

  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'];
    final body = notification?.body ?? message.data['body'];

    if (title == null && body == null) return;

    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    await plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    final androidPlugin = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_fcmForegroundChannel);

    await plugin.show(
      message.messageId.hashCode,
      title ?? 'Lexii',
      body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fcm_foreground_channel',
          'FCM Foreground Notifications',
          channelDescription:
              'Shows push notifications while app is in foreground.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'fcm_background',
    );
  }
}
