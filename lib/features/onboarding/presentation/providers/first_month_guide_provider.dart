import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/first_month_guide.dart';
import 'onboarding_provider.dart';

/// 最初の1ヶ月ガイド完了状況を管理するプロバイダー
final firstMonthGuideProvider = FutureProvider<List<FirstMonthGuideStep>>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);

  // SharedPreferencesから完了状況を取得
  final completedStatus = <FirstMonthGuideStepType, bool>{};
  for (final type in FirstMonthGuideStepType.values) {
    final key = 'first_month_guide_${type.name}_completed';
    completedStatus[type] = prefs.getBool(key) ?? false;
  }

  return FirstMonthGuideStep.createAllSteps(completedStatus: completedStatus);
});

/// 最初の1ヶ月ガイドの進捗率を計算するプロバイダー
final firstMonthGuideProgressProvider = FutureProvider<double>((ref) async {
  final steps = await ref.watch(firstMonthGuideProvider.future);
  final completedCount = FirstMonthGuideStep.countCompletedSteps(steps);
  return completedCount / steps.length;
});

/// すべてのステップが完了したかチェックするプロバイダー
final firstMonthGuideCompletedProvider = FutureProvider<bool>((ref) async {
  final steps = await ref.watch(firstMonthGuideProvider.future);
  return FirstMonthGuideStep.areAllStepsCompleted(steps);
});

/// 最初の1ヶ月ガイドの完了状況を更新するミューテーター
class FirstMonthGuideMutator {
  final SharedPreferences _prefs;

  FirstMonthGuideMutator(this._prefs);

  /// ステップを完了にマーク
  Future<void> completeStep(FirstMonthGuideStepType type) async {
    final key = 'first_month_guide_${type.name}_completed';
    await _prefs.setBool(key, true);
  }

  /// ステップを未完了にマーク
  Future<void> resetStep(FirstMonthGuideStepType type) async {
    final key = 'first_month_guide_${type.name}_completed';
    await _prefs.setBool(key, false);
  }

  /// すべてのステップをリセット
  Future<void> resetAllSteps() async {
    for (final type in FirstMonthGuideStepType.values) {
      final key = 'first_month_guide_${type.name}_completed';
      await _prefs.setBool(key, false);
    }
  }
}

/// 最初の1ヶ月ガイドのミューテーターを提供するプロバイダー
final firstMonthGuideMutatorProvider = FutureProvider<FirstMonthGuideMutator>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return FirstMonthGuideMutator(prefs);
});
