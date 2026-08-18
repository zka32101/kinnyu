import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

/// 制度・手続きの期限リマインダーをスケジュールするための入力データ。
/// core/services は features 層に依存しないよう、ProcedureInfo モデルそのものではなく
/// 必要なフィールドだけを持つ record 型で受け取る。
typedef ProcedureReminderInput = ({
  String id,
  String title,
  String applyWindow,
  List<int> reminderMonths,
});

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static const String streakChannelId = 'streak_reminder';
  static const String streakChannelName = 'ストリークリマインダー';
  static const String procedureChannelId = 'procedure_reminder';
  static const String procedureChannelName = '制度・手続きリマインダー';
  // 制度リマインダーの通知IDは他機能(0, timestampベース)と衝突しない範囲を予約する
  static const int _procedureReminderIdBase = 20000;

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

        const AndroidNotificationChannel procedureChannel = AndroidNotificationChannel(
          procedureChannelId,
          procedureChannelName,
          description: '申請できる制度・補助金の時期をお知らせする通知',
          importance: Importance.defaultImportance,
          enableVibration: true,
        );
        await androidImpl.createNotificationChannel(procedureChannel);
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

  /// 申請時期が来た制度・手続きについて、リマインダー通知をまとめてスケジュールする。
  ///
  /// 同じ制度・月の組み合わせには決定論的な通知IDを使うため、複数回呼び出しても
  /// （ライフステージ変更時の再スケジュール等）重複登録にはならず、既存の予約が
  /// 上書きされるだけになる。
  ///
  /// 制限事項: このプラグインは「毎年○月」の繰り返しスケジュールを直接サポートしない
  /// ため、直近1回分の通知のみを予約する。翌年分は次回このメソッドが呼ばれた際に
  /// 改めてスケジュールされる想定（アプリ起動時・ライフステージ変更時に呼び出すこと）。
  Future<void> scheduleProcedureReminders(
    List<ProcedureReminderInput> procedures,
  ) async {
    if (!_initialized) {
      debugPrint('NotificationService: not initialized, skipping scheduleProcedureReminders');
      return;
    }
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        procedureChannelId,
        procedureChannelName,
        channelDescription: '申請できる制度・補助金の時期をお知らせする通知',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        enableVibration: true,
        playSound: true,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      for (final procedure in procedures) {
        for (final month in procedure.reminderMonths) {
          try {
            final id = _procedureReminderNotificationId(procedure.id, month);
            final scheduledDate = _nextOccurrenceOfMonth(month);

            await flutterLocalNotificationsPlugin.zonedSchedule(
              id,
              '📋 ${procedure.title} の申請時期です',
              procedure.applyWindow,
              scheduledDate,
              platformChannelSpecifics,
              androidScheduleMode: AndroidScheduleMode.exact,
            );
          } catch (e) {
            debugPrint(
                '制度リマインダーのスケジュール失敗 (procedure=${procedure.id}, month=$month): $e');
            continue;
          }
        }
      }
    } catch (e) {
      debugPrint('制度リマインダーのスケジュール失敗: $e');
    }
  }

  /// 指定した制度のリマインダー通知をすべてキャンセルする
  Future<void> cancelProcedureReminders(ProcedureReminderInput procedure) async {
    if (!_initialized) {
      debugPrint('NotificationService: not initialized, skipping cancelProcedureReminders');
      return;
    }
    for (final month in procedure.reminderMonths) {
      await flutterLocalNotificationsPlugin
          .cancel(_procedureReminderNotificationId(procedure.id, month));
    }
  }

  int _procedureReminderNotificationId(String procedureId, int month) {
    // procedureId のハッシュを予約範囲内に折りたたみ、月ごとに枝分かれさせる。
    // String.hashCode はアプリの再起動間で安定性が保証されないため
    // （VM/isolate のハッシュシード次第で値が変わりうる）、
    // 自前の決定論的なハッシュ関数を使う。
    final hashPart = _stableStringHash(procedureId) % 1000;
    return _procedureReminderIdBase + hashPart * 12 + month;
  }

  /// `String.hashCode` の代わりに使う、アプリの再起動を跨いでも常に同じ値を
  /// 返す決定論的な文字列ハッシュ（多項式ハッシュ）。
  int _stableStringHash(String s) {
    int hash = 0;
    for (final unit in s.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  tz.TZDateTime _nextOccurrenceOfMonth(int month, {int day = 1, int hour = 9}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, month, day, hour);
    if (scheduled.isBefore(now)) {
      scheduled = tz.TZDateTime(tz.local, now.year + 1, month, day, hour);
    }
    return scheduled;
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
