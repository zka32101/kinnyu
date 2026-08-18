import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/models/procedure_info.dart';

const _lifeStagePrefsKey = 'procedures_life_stage';
const _viewedProcedureIdsPrefsKey = 'procedures_viewed_ids';

/// 現在選択中のライフステージ（未選択時は null）。SharedPreferences に永続化する。
///
/// ライフステージを選ぶことは「ライフイベントトリガー」として扱われ、
/// 関連する制度・補助金の申請期限リマインダー通知が自動でスケジュールされる。
final lifeStageProvider = NotifierProvider<LifeStageNotifier, LifeStage?>(() {
  return LifeStageNotifier();
});

class LifeStageNotifier extends Notifier<LifeStage?> {
  @override
  LifeStage? build() {
    Future.microtask(_load);
    return null;
  }

  Future<void> _load() async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final saved = prefs.getString(_lifeStagePrefsKey);
      if (saved == null) return;
      for (final stage in LifeStage.values) {
        if (stage.name == saved) {
          state = stage;
          return;
        }
      }
    } catch (e) {
      debugPrint('LifeStageNotifier: failed to load: $e');
    }
  }

  /// ライフステージを設定・変更する。関連する制度のリマインダー通知も
  /// あわせてスケジュールする（＝ライフイベントに応じた通知トリガー）。
  Future<void> setLifeStage(LifeStage? stage) async {
    state = stage;
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      if (stage == null) {
        await prefs.remove(_lifeStagePrefsKey);
        return;
      }
      await prefs.setString(_lifeStagePrefsKey, stage.name);
      await _scheduleRemindersFor(stage);
    } catch (e) {
      debugPrint('LifeStageNotifier: failed to save/schedule: $e');
    }
  }

  /// アプリ起動時に呼び出し、保存済みのライフステージがあればリマインダーを
  /// 再スケジュールする。通知プラグインは年次の繰り返しスケジュールを
  /// サポートしないため、起動のたびに「直近の発火日」へ再計算する目的。
  Future<void> rescheduleRemindersForSavedLifeStage() async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final saved = prefs.getString(_lifeStagePrefsKey);
      if (saved == null) return;
      for (final stage in LifeStage.values) {
        if (stage.name == saved) {
          await _scheduleRemindersFor(stage);
          return;
        }
      }
    } catch (e) {
      debugPrint('LifeStageNotifier: failed to reschedule on startup: $e');
    }
  }

  Future<void> _scheduleRemindersFor(LifeStage stage) async {
    final relevant = ProcedureLibrary.byLifeStage(stage)
        .where((p) => p.reminderMonths.isNotEmpty)
        .map((p) => (
              id: p.id,
              title: p.title,
              applyWindow: p.applyWindow,
              reminderMonths: p.reminderMonths,
            ))
        .toList();
    if (relevant.isNotEmpty) {
      await NotificationService().scheduleProcedureReminders(relevant);
    }
  }
}

/// ユーザーが詳細を開いて確認した制度の ID 集合。閲覧進捗の可視化に使う。
final viewedProcedureIdsProvider =
    NotifierProvider<ViewedProcedureIdsNotifier, Set<String>>(() {
  return ViewedProcedureIdsNotifier();
});

class ViewedProcedureIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    Future.microtask(_load);
    return const {};
  }

  Future<void> _load() async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final saved = prefs.getStringList(_viewedProcedureIdsPrefsKey);
      if (saved != null) {
        state = saved.toSet();
      }
    } catch (e) {
      debugPrint('ViewedProcedureIdsNotifier: failed to load: $e');
    }
  }

  Future<void> markViewed(String procedureId) async {
    if (state.contains(procedureId)) return;
    state = {...state, procedureId};
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      await prefs.setStringList(_viewedProcedureIdsPrefsKey, state.toList());
    } catch (e) {
      debugPrint('ViewedProcedureIdsNotifier: failed to save: $e');
    }
  }
}
