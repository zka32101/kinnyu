import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static const String streakChannelId = 'streak_reminder';
  static const String streakChannelName = 'ストリークリマインダー';

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  Future<void> initialize() async {
    try {
      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      tzdata.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('ic_notification');

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        streakChannelId,
        streakChannelName,
        description: 'ストリークを続けるためのリマインダー通知',
        importance: Importance.defaultImportance,
        enableVibration: true,
      );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      print('NotificationService init error: $e');
    }
  }

  Future<void> scheduleStreakReminder() async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        20,
        0,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        streakChannelId,
        streakChannelName,
        channelDescription: 'ストリークを続けるためのリマインダー通知',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        ticker: 'ストリーク継続のお知らせ',
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'ストリーク継続のお時間です！',
        '今日の学習を完了してストリークを続けよう🔥',
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exact,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print('通知スケジュール失敗: $e');
    }
  }

  Future<void> showMissionCompletedNotification(String missionTitle) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'mission_completed',
      'ミッション完了通知',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'ミッション完了！',
      '$missionTitle を完了しました！',
      platformChannelSpecifics,
    );
  }

  Future<void> showDiagnosisResultNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'diagnosis_result',
      '診断結果通知',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '節約TOP3が明らかに！',
      'あなたの診断結果を確認してみましょう🎯',
      platformChannelSpecifics,
    );
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
