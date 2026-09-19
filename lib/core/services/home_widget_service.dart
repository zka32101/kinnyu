import 'package:flutter/foundation.dart';

/// ホーム画面ウィジェット（Android）にストリーク・レベル・今日のミッションを
/// 同期するサービス。
///
/// NOTE: `home_widget` パッケージは現在 pubspec.yaml でコメントアウトされている
/// （0.5.0 が現行 Flutter エンジンと非互換のためビルド失敗を起こす）。パッケージが
/// 復帰するまでの間、このサービスは呼び出し元のAPIを保ったまま何も行わないスタブ
/// として動作する。
class HomeWidgetService {
  static Future<void> updateWidgetData({
    required int streak,
    required int totalXP,
    required int level,
    String? todayMissionTitle,
  }) async {
    debugPrint(
        'HomeWidgetService.updateWidgetData: home_widget package disabled, skipping sync');
  }
}
