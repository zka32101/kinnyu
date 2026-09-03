import 'package:riverpod/riverpod.dart';
import '../../domain/models/first_month_guide.dart';

/// チュートリアル視聴状態を管理するプロバイダー
final tutorialStateProvider = NotifierProvider<
    TutorialStateNotifier,
    Map<FirstMonthGuideStepType, bool>>(() {
  return TutorialStateNotifier();
});

/// チュートリアル視聴状態を管理するクラス
class TutorialStateNotifier
    extends Notifier<Map<FirstMonthGuideStepType, bool>> {
  @override
  Map<FirstMonthGuideStepType, bool> build() {
    return {};
  }

  /// チュートリアルを視聴済みにマーク
  void markTutorialAsWatched(FirstMonthGuideStepType stepType) {
    state = {
      ...state,
      stepType: true,
    };
  }

  /// チュートリアルが視聴済みかチェック
  bool isTutorialWatched(FirstMonthGuideStepType stepType) {
    return state[stepType] ?? false;
  }

  /// すべてのチュートリアルをリセット
  void resetAllTutorials() {
    state = {};
  }
}

/// 特定のステップのチュートリアル視聴状態を取得
final tutorialWatchedProvider = Provider.family<bool, FirstMonthGuideStepType>(
  (ref, stepType) {
    final tutorialState = ref.watch(tutorialStateProvider);
    return tutorialState[stepType] ?? false;
  },
);

/// 複数のチュートリアル視聴状態を取得
final allTutorialsWatchedProvider = Provider<Map<FirstMonthGuideStepType, bool>>(
  (ref) => ref.watch(tutorialStateProvider),
);

/// 視聴完了率を計算
final tutorialCompletionRateProvider = Provider<double>(
  (ref) {
    final tutorialState = ref.watch(tutorialStateProvider);
    if (tutorialState.isEmpty) return 0.0;

    final watchedCount = tutorialState.values.where((v) => v).length;
    return watchedCount / FirstMonthGuideStepType.values.length;
  },
);
