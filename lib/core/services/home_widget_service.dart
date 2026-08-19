import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// ホーム画面ウィジェット（Android）にストリーク・レベル・今日のミッションを
/// 同期するサービス。iOS側はWidgetExtension未実装のため、データ保存のみ行い
/// 実際の表示は行われない。
class HomeWidgetService {
  static const String _androidWidgetProviderName = 'HomeWidgetProvider';

  static Future<void> updateWidgetData({
    required int streak,
    required int totalXP,
    required int level,
    String? todayMissionTitle,
  }) async {
    try {
      await HomeWidget.saveWidgetData<int>('streak', streak);
      await HomeWidget.saveWidgetData<int>('totalXP', totalXP);
      await HomeWidget.saveWidgetData<int>('level', level);
      await HomeWidget.saveWidgetData<String>(
          'todayMissionTitle', todayMissionTitle ?? 'ミッションを確認しよう');
      await HomeWidget.updateWidget(
        androidName: _androidWidgetProviderName,
      );
    } catch (e) {
      debugPrint('HomeWidgetService.updateWidgetData failed: $e');
    }
  }
}
