import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:developer' as developer;

class StudyReminderSettings {
  final bool enabled;
  final int hour;
  final int minute;

  const StudyReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  StudyReminderSettings copyWith({bool? enabled, int? hour, int? minute}) {
    return StudyReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}

class StudyReminderService {
  StudyReminderService._();

  static final StudyReminderService instance = StudyReminderService._();

  static const int _notificationId = 9001;
  static const int _testScheduledNotificationId = 9003;
  static const String _prefsEnabledKey = 'study_reminder_enabled';
  static const String _prefsHourKey = 'study_reminder_hour';
  static const String _prefsMinuteKey = 'study_reminder_minute';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _timezoneReady = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    _initialized = true;
  }

  Future<void> _ensureTimezoneReady() async {
    if (_timezoneReady) return;

    tz.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }
    _timezoneReady = true;
  }

  Future<StudyReminderSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return StudyReminderSettings(
      enabled: prefs.getBool(_prefsEnabledKey) ?? false,
      hour: prefs.getInt(_prefsHourKey) ?? 20,
      minute: prefs.getInt(_prefsMinuteKey) ?? 0,
    );
  }

  Future<void> saveSettings(StudyReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsEnabledKey, settings.enabled);
    await prefs.setInt(_prefsHourKey, settings.hour);
    await prefs.setInt(_prefsMinuteKey, settings.minute);
  }

  Future<bool> requestPermission() async {
    await initialize();

    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final iosImpl = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    final androidGranted = await androidImpl?.requestNotificationsPermission();
    try {
      await androidImpl?.requestExactAlarmsPermission();
    } catch (_) {}
    final iosGranted = await iosImpl?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  Future<void> syncReminderFromSettings() async {
    final settings = await loadSettings();
    await initialize();

    if (!settings.enabled) {
      await disableReminder();
      return;
    }

    await scheduleDailyReminder(settings.time);
  }

  Future<void> disableReminder() async {
    await initialize();
    await _notifications.cancel(_notificationId);
  }

  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await initialize();
    await _ensureTimezoneReady();

    final scheduleAt = _nextInstanceOfTime(time);

    const androidDetails = AndroidNotificationDetails(
      'study_reminder_channel',
      'Nhắc nhở học tập',
      channelDescription: 'Thông báo nhắc nhở học TOEIC mỗi ngày',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    final scheduleMode = await _resolveAndroidScheduleMode();

    await _notifications.zonedSchedule(
      _notificationId,
      'Đến giờ học TOEIC rồi!',
      'Mở Lexii 20 phút để giữ nhịp học hằng ngày nhé.',
      scheduleAt,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: scheduleMode,
      payload: 'study-reminder',
    );

    final isScheduled = await isReminderScheduled();
    if (!isScheduled) {
      developer.log(
        'Reminder schedule verification returned false. Device may still keep the alarm internally.',
        name: 'StudyReminder',
      );
    }
  }

  Future<DateTime> getNextReminderTime(TimeOfDay time) async {
    await _ensureTimezoneReady();
    return _nextInstanceOfTime(time);
  }

  Future<bool> canSchedulePrecisely() async {
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImpl == null) {
      return true;
    }

    try {
      final canExact = await androidImpl.canScheduleExactNotifications();
      return canExact ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> isReminderScheduled() async {
    await initialize();
    final pending = await _notifications.pendingNotificationRequests();
    return pending.any((item) => item.id == _notificationId);
  }

  Future<DateTime> scheduleOneMinuteTestReminder() async {
    await initialize();
    await _ensureTimezoneReady();

    const androidDetails = AndroidNotificationDetails(
      'study_reminder_channel',
      'Nhắc nhở học tập',
      channelDescription: 'Thông báo nhắc nhở học TOEIC mỗi ngày',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    final mode = await _resolveAndroidScheduleMode();
    final now = tz.TZDateTime.now(tz.local);
    final testAt = now.add(const Duration(minutes: 1));

    await _notifications.zonedSchedule(
      _testScheduledNotificationId,
      'Nhắc học thử tự động',
      'Nếu bạn nhận được thông báo này, lịch tự động đang hoạt động.',
      testAt,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: mode,
      payload: 'study-reminder-scheduled-test',
    );

    return testAt;
  }

  Future<void> showTestNotification() async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'study_reminder_channel',
      'Nhắc nhở học tập',
      channelDescription: 'Thông báo nhắc nhở học TOEIC mỗi ngày',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _notifications.show(
      9002,
      'Thông báo thử',
      'Nhắc học đã được bật thành công.',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: 'study-reminder-test',
    );
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImpl == null) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }

    try {
      var canExact = await androidImpl.canScheduleExactNotifications();
      if (canExact == false) {
        await androidImpl.requestExactAlarmsPermission();
        canExact = await androidImpl.canScheduleExactNotifications();
      }

      if (canExact ?? true) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }

      return AndroidScheduleMode.alarmClock;
    } catch (_) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }
}
