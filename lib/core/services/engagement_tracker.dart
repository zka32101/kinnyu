import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// アプリの起動時刻（時間帯）をローカルに記録し、ユーザーが最も
/// アプリを開く頻度が高い時間帯を推定するためのトラッカー。
/// Firestore同期は行わず、端末ローカルのSharedPreferencesのみを使う
/// （デバイス間同期は不要な軽量な学習データのため）。
class EngagementTracker {
  static const String _hourCountsKey = 'engagement_hour_counts';

  /// 現在時刻の時間帯カウントを1つ増やす。main.dart等、アプリ起動時に呼ぶ。
  static Future<void> recordAppOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_hourCountsKey) ?? List.filled(24, '0');
      final counts = raw.map((s) => int.tryParse(s) ?? 0).toList();
      // 念のため長さを24に補正
      while (counts.length < 24) {
        counts.add(0);
      }
      final hour = DateTime.now().hour;
      counts[hour] = counts[hour] + 1;
      await prefs.setStringList(
          _hourCountsKey, counts.map((c) => c.toString()).toList());
    } catch (e) {
      debugPrint('EngagementTracker.recordAppOpen failed: $e');
    }
  }

  /// 最も頻度の高い時間帯（0〜23）を返す。記録が無ければnull。
  static Future<int?> getPreferredHour() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_hourCountsKey);
      if (raw == null) return null;
      final counts = raw.map((s) => int.tryParse(s) ?? 0).toList();
      if (counts.every((c) => c == 0)) return null;
      var maxIndex = 0;
      for (var i = 1; i < counts.length; i++) {
        if (counts[i] > counts[maxIndex]) maxIndex = i;
      }
      return maxIndex;
    } catch (e) {
      debugPrint('EngagementTracker.getPreferredHour failed: $e');
      return null;
    }
  }
}
