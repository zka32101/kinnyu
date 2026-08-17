import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static const String streakChannelId = 'streak_reminder';
  static const String streakChannelName = 'ストリークリマインダー';

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  // initialize() が正常に完了した場合のみ true になる。
  // late フィールド flutterLocalNotificationsPlugin は initialize() が
  // 失敗（例外）した場合は未初期化のままになり得るため、他の公開メソッドは
  // 呼び出し前に必ずこのフラグを確認すること（LateInitializationError 対策）。
  bool _initialized = false;

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

      // Android のみ：通知チャネルを作成
      final androidImpl = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          streakChannelId,
          streakChannelName,
          description: 'ストリークを続けるためのリマインダー通知',
          importance: Importance.defaultImportance,
          enableVibration: true,
        );
        await androidImpl.createNotificationChannel(channel);
      }

      // ここまで例外なく到達した場合のみ初期化完了とみなす
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
      // 通知初期化失敗時もアプリは起動可能にする（_initialized は false のまま）
    }
  }

  Future<void> scheduleStreakReminder() async {
    if (!_initialized) {
      debugPrint('NotificationService: not initialized, skipping scheduleStreakReminder');
      return;
    }
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
      debugPrint('通知スケジュール失敗: $e');
    }
  }

  Future<void> showMissionCompletedNotification(String missionTitle) async {
    if (!_initialized) {
      debugPrint('NotificationService: not initialized, skipping showMissionCompletedNotification');
      return;
    }
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
    if (!_initialized) {
      debugPrint('NotificationService: not initialized, skipping showDiagnosisResultNotification');
      return;
    }
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
    if (!_initialized) {
      debugPrint('NotificationService: not initialized, skipping cancelAllNotifications');
      return;
    }
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    if (!_initialized) {
      debugPrint('NotificationService: not initialized, skipping cancelNotification');
      return;
    }
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
