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
  static const String recommendationChannelId = 'weekly_recommendation';
  static const String recommendationChannelName = 'おすすめ通知';
  // 制度リマインダーの通知IDは他機能(0, timestampベース)と衝突しない範囲を予約する
  static const int _procedureReminderIdBase = 20000;
  // 週次おすすめ通知の固定通知ID（streakReminderの0番、mission/diagnosisの
  // timestampベースID、制度リマインダーの20000番台と衝突しない値を使う）
  static const int _weeklyRecommendationId = 1;

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
          importance: Importance.high,
          enableVibration: true,
        );
        await androidImpl.createNotificationChannel(channel);

        const AndroidNotificationChannel procedureChannel = AndroidNotificationChannel(
          procedureChannelId,
          procedureChannelName,
          description: '申請できる制度・補助金の時期をお知らせする通知',
          importance: Importance.high,
          enableVibration: true,
        );
        await androidImpl.createNotificationChannel(procedureChannel);

        const AndroidNotificationChannel recommendationChannel = AndroidNotificationChannel(
          recommendationChannelId,
          recommendationChannelName,
          description: '未達成のミッションや未確認の制度・補助金をお知らせするおすすめ通知',
          importance: Importance.high,
          enableVibration: true,
        );
        await androidImpl.createNotificationChannel(recommendationChannel);
      }

      // ここまで例外なく到達した場合のみ初期化完了とみなす
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
      // 通知初期化失敗時もアプリは起動可能にする（_initialized は false のまま）
    }
  }

  Future<void> scheduleStreakReminder({int hour = 20, int currentStreak = 0}) async {
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
        hour,
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
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'ストリーク継続のお知らせ',
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      final body = currentStreak > 0
          ? '🔥${currentStreak}日連続中！今日も続けて記録を伸ばそう'
          : '今日の学習を完了してストリークを続けよう🔥';

      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'ストリーク継続のお時間です！',
        body,
        scheduledDate,
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('通知スケジュール失敗: $e');
    }
  }

  /// 週次おすすめ通知をスケジュールする。
  ///
  /// 未達成のミッションや未確認の制度・補助金がある場合のみ、次の月曜10:00に
  /// 固定通知ID(_weeklyRecommendationId)で通知をスケジュールする。両方0件の
  /// 場合は既存の予約をキャンセルするのみで、新規スケジュールは行わない。
  Future<void> scheduleWeeklyRecommendation({
    required int pendingMissionCount,
    required int unviewedProcedureCount,
  }) async {
    if (!_initialized) {
      debugPrint('NotificationService: not initialized, skipping scheduleWeeklyRecommendation');
      return;
    }
    try {
      if (pendingMissionCount == 0 && unviewedProcedureCount == 0) {
        await flutterLocalNotificationsPlugin.cancel(_weeklyRecommendationId);
        return;
      }

      final messages = <String>[];
      if (pendingMissionCount > 0) {
        messages.add('今週の未達成ミッションが${pendingMissionCount}件あります');
      }
      if (unviewedProcedureCount > 0) {
        messages.add('まだチェックしていない制度・補助金が${unviewedProcedureCount}件あります');
      }
      final body = messages.join('。');

      final scheduledDate = _nextMonday9AM();

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        recommendationChannelId,
        recommendationChannelName,
        channelDescription: '未達成のミッションや未確認の制度・補助金をお知らせするおすすめ通知',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        _weeklyRecommendationId,
        '今週のおすすめ',
        body,
        scheduledDate,
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('週次おすすめ通知のスケジュール失敗: $e');
    }
  }

  /// 次の月曜日の指定時刻(デフォルト10:00)を返す。
  /// 今日が月曜日かつ指定時刻より前であれば今日を、それ以外は翌週以降の
  /// 直近の月曜日を返す。
  tz.TZDateTime _nextMonday9AM({int hour = 10}) {
    final now = tz.TZDateTime.now(tz.local);
    var candidate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);

    // DateTime.weekday: 月曜=1 ... 日曜=7
    var daysUntilMonday = (DateTime.monday - candidate.weekday) % 7;
    if (daysUntilMonday < 0) {
      daysUntilMonday += 7;
    }
    if (daysUntilMonday == 0 && candidate.isBefore(now)) {
      daysUntilMonday = 7;
    }

    return candidate.add(Duration(days: daysUntilMonday));
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
        importance: Importance.high,
        priority: Priority.high,
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
              '📋 ${procedure.title}の申請時期です',
              procedure.applyWindow,
              scheduledDate,
              platformChannelSpecifics,
              androidAllowWhileIdle: true,
              uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
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

  /// 財務健全性スコアマイルストーン通知をスケジュールする
  /// スコアが特定の値に到達時に祝賀通知を送信
  Future<void> showScoreMilestoneNotification(int score) async {
    if (!_initialized) {
      debugPrint('NotificationService: not initialized, skipping showScoreMilestoneNotification');
      return;
    }

    // マイルストーン: 70, 75, 80, 85, 90
    final milestones = [70, 75, 80, 85, 90];
    if (!milestones.contains(score)) {
      return; // Only notify on milestone scores
    }

    try {
      String title = '🎉 スコアアップおめでとう！';
      String body;
      String emoji;

      if (score >= 90) {
        emoji = '🏆';
        body = 'スコア90を達成！あなたは優秀な財務管理者です。このレベルを維持してください。';
      } else if (score >= 85) {
        emoji = '⭐';
        body = 'スコア85に到達！財務健全性が優良水準です。目標達成まであと一歩です。';
      } else if (score >= 80) {
        emoji = '👍';
        body = 'スコア80を突破！財務管理が上手くいっています。さらに上を目指しましょう。';
      } else if (score >= 75) {
        emoji = '📈';
        body = 'スコア75達成！着実に改善が進んでいます。このペースで続けてください。';
      } else {
        emoji = '🚀';
        body = 'スコア70に到達！財務健全性の改善が始まっています。頑張りましょう！';
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'score_milestone',
        'スコアマイルストーン通知',
        channelDescription: '財務スコアがマイルストーンに到達時の祝賀通知',
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
        score * 1000, // Unique ID based on score
        '$emoji $title',
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      debugPrint('スコアマイルストーン通知エラー: $e');
    }
  }

  /// 財務改善提案通知
  /// ユーザーが改善アクションを取ったときにお祝い通知
  Future<void> showImprovementActionNotification({
    required String actionType,
    required String category,
    required int estimatedScoreGain,
  }) async {
    if (!_initialized) {
      debugPrint('NotificationService: not initialized, skipping showImprovementActionNotification');
      return;
    }

    try {
      String title = '改善アクション実行！';
      String body;
      String emoji;

      switch (actionType) {
        case 'savings':
          emoji = '💰';
          body = '貯蓄を開始しました。約$estimatedScoreGainポイントスコアが向上する見込みです。';
          break;
        case 'budget':
          emoji = '📊';
          body = '予算設定が完了！予算管理によりスコアが改善する見込みです。';
          break;
        case 'investment':
          emoji = '📈';
          body = '投資を開始しました。投資参加度スコアが向上する見込みです。';
          break;
        case 'donation':
          emoji = '🤝';
          body = '寄付をしていただきました。社会貢献度スコアが向上する見込みです。';
          break;
        default:
          emoji = '✅';
          body = '改善アクションを実行しました。スコアが向上する見込みです。';
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'improvement_action',
        '改善アクション通知',
        channelDescription: 'ユーザーが改善アクションを取った時のお祝い通知',
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
        '$emoji $title',
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      debugPrint('改善アクション通知エラー: $e');
    }
  }

  /// 月間目標達成通知
  /// ユーザーが月間目標を達成したときに通知
  Future<void> showMonthlyGoalAchievedNotification({
    required String goalName,
    required int currentScore,
    required int previousScore,
  }) async {
    if (!_initialized) {
      debugPrint('NotificationService: not initialized, skipping showMonthlyGoalAchievedNotification');
      return;
    }

    try {
      final scoreImprovement = currentScore - previousScore;
      final title = '🎯 月間目標達成！';
      final body = '$goalNameを達成しました！\nスコア: $previousScore → $currentScore (+$scoreImprovement)';

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'monthly_goal',
        '月間目標達成通知',
        channelDescription: '月間目標達成時のお祝い通知',
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
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      debugPrint('月間目標達成通知エラー: $e');
    }
  }
}
