import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 「カテゴリ×年月×警告/超過」の組み合わせごとに、予算アラート通知を
/// 既に送信済みかどうかを端末ローカルに記録し、同じ月に何度もアプリを
/// 開いた際の再送信を防ぐためのトラッカー。
class BudgetAlertTracker {
  static const String _sentAlertsKey = 'budget_alert_sent_keys';

  // 同一セッション内での重複送信を防ぐためのインメモリガード。
  // shouldAlert()はSharedPreferencesへの非同期アクセスを挟むため、
  // これが無いと短時間に複数回呼ばれた際（HomePageの再ビルドによる
  // postFrameCallbackの多重登録など）に両方が「未送信」と判定してしまう
  // （TOCTOU）。同期的に即座にキーを登録することで、その隙間を塞ぐ。
  static final Set<String> _claimedThisSession = {};

  static Future<bool> shouldAlert(String alertKey) async {
    if (_claimedThisSession.contains(alertKey)) return false;
    _claimedThisSession.add(alertKey);
    try {
      final prefs = await SharedPreferences.getInstance();
      final sent = prefs.getStringList(_sentAlertsKey) ?? [];
      return !sent.contains(alertKey);
    } catch (e) {
      debugPrint('BudgetAlertTracker.shouldAlert failed: $e');
      _claimedThisSession.remove(alertKey); // 失敗時は再試行できるよう解放する
      return false;
    }
  }

  static Future<void> markAlerted(String alertKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sent = prefs.getStringList(_sentAlertsKey) ?? [];
      if (!sent.contains(alertKey)) {
        sent.add(alertKey);
        // 無制限に増え続けないよう、直近200件のみ保持する
        final trimmed =
            sent.length > 200 ? sent.sublist(sent.length - 200) : sent;
        await prefs.setStringList(_sentAlertsKey, trimmed);
      }
    } catch (e) {
      debugPrint('BudgetAlertTracker.markAlerted failed: $e');
    }
  }
}
