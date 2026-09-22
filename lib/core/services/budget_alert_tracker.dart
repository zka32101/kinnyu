import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 「カテゴリ×年月×警告/超過」の組み合わせごとに、予算アラート通知を
/// 既に送信済みかどうかを端末ローカルに記録し、同じ月に何度もアプリを
/// 開いた際の再送信を防ぐためのトラッカー。
class BudgetAlertTracker {
  static const String _sentAlertsKey = 'budget_alert_sent_keys';

  static Future<bool> shouldAlert(String alertKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sent = prefs.getStringList(_sentAlertsKey) ?? [];
      return !sent.contains(alertKey);
    } catch (e) {
      debugPrint('BudgetAlertTracker.shouldAlert failed: $e');
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
