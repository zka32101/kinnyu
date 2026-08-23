import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';
import '../../domain/models/achievement.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';
import '../../../user_profile/presentation/providers/streak_provider.dart';
import '../../../mission/presentation/providers/mission_provider.dart';
import '../../../procedures/presentation/providers/procedures_provider.dart';
import '../../../investment/presentation/providers/investment_provider.dart';

/// 指定した uid のユーザーについて、全実績（バッジ）の進捗状況を
/// 既存のプロバイダー・サービスの値から純粋に計算して返す。
/// 実績専用の新規 Firestore コレクションは作らない。
///
/// unlocked（解除済み）を先頭に、その中ではカテゴリ順・閾値の小さい順で
/// ソートされたリストを返す。
final achievementProgressListProvider =
    FutureProvider.family<List<AchievementProgress>, String>((ref, uid) async {
  final user = ref.watch(userProvider);

  // レベル: userProvider の level を使用（未ログイン等で取得できない場合は 0）
  final level = user?.level ?? 0;

  // 連続ログイン日数: 実績は「一度でも到達したか」を判定したいため、
  // userProvider の現在のストリーク（優先）と streakProvider の
  // 過去最長ストリークの大きい方を採用する。
  int streakValue = user?.streak ?? 0;
  try {
    final streakData = await ref.watch(streakProvider(uid).future);
    if (streakData.longestStreak > streakValue) {
      streakValue = streakData.longestStreak;
    }
  } catch (e) {
    debugPrint('achievementProgressListProvider: streak fetch failed: $e');
  }

  // 完了済みミッション数
  int completedMissions = 0;
  try {
    final missionService = ref.watch(missionServiceProvider);
    completedMissions = await missionService.getCompletedMissionsCount(uid);
  } catch (e) {
    debugPrint(
        'achievementProgressListProvider: completed missions fetch failed: $e');
  }

  // 閲覧済みの制度・補助金の件数
  int viewedProceduresCount = 0;
  try {
    final viewedIds = ref.watch(viewedProcedureIdsProvider);
    viewedProceduresCount = viewedIds.length;
  } catch (e) {
    debugPrint(
        'achievementProgressListProvider: viewed procedures fetch failed: $e');
  }

  // 開始した投資件数（運用中の投資数）
  int investmentCount = 0;
  try {
    final investments = await ref.watch(activeInvestmentsProvider(uid).future);
    investmentCount = investments.length;
  } catch (e) {
    debugPrint(
        'achievementProgressListProvider: investments fetch failed: $e');
  }

  final currentValues = <AchievementCategory, int>{
    AchievementCategory.streak: streakValue,
    AchievementCategory.level: level,
    AchievementCategory.mission: completedMissions,
    AchievementCategory.procedure: viewedProceduresCount,
    AchievementCategory.investment: investmentCount,
  };

  final progressList = AchievementDefinitions.all.map((achievement) {
    final currentValue = currentValues[achievement.category] ?? 0;
    return AchievementProgress(
      achievement: achievement,
      currentValue: currentValue,
      unlocked: currentValue >= achievement.threshold,
    );
  }).toList();

  // unlocked（解除済み）優先 → カテゴリ順 → 閾値の小さい順にソート
  progressList.sort((a, b) {
    if (a.unlocked != b.unlocked) {
      return a.unlocked ? -1 : 1;
    }
    final categoryCompare =
        a.achievement.category.index.compareTo(b.achievement.category.index);
    if (categoryCompare != 0) return categoryCompare;
    return a.achievement.threshold.compareTo(b.achievement.threshold);
  });

  return progressList;
});
