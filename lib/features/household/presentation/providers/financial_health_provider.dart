import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/financial_health_score.dart';
import '../../domain/models/household_budget.dart';
import '../../domain/models/household_expense_summary.dart';
import '../../domain/models/household_group.dart';
import '../../domain/services/financial_health_calculator.dart';
import '../../data/household_service.dart';
import './household_budget_provider.dart';
import './household_provider.dart';
import './social_contribution_provider.dart';
import '../../../core/services/notification_provider.dart';

/// 現在月の家計情報プロバイダー
/// 実装の最適化：
/// - keepAlive: Firestore クエリのキャッシュを保持
/// - Firestoreから月別の家計サマリーを取得する際の再計算を防止
/// - 実データ：HouseholdServiceから実際のレシート集計データを取得
final monthlyExpenseSummaryProvider = FutureProvider.autoDispose
    .family<HouseholdExpenseSummary?, String>((ref, groupId) async {
  try {
    final service = HouseholdService();
    final now = DateTime.now();
    return await service.getMonthlyExpenseSummary(
      groupId: groupId,
      month: DateTime(now.year, now.month),
    );
  } catch (e) {
    // エラー時はnullを返す（詳細ページでエラーハンドリング）
    return null;
  }
}).keepAlive();

/// 投資額プロバイダー
/// 実装の最適化：
/// - keepAlive: ポートフォリオ計算のキャッシュを保持
/// - 投資額は頻繁には変わらないため、キャッシュは有効
///
/// TODO Priority 5.1: Investment Portfolio Integration
/// - 現在のポートフォリオから合計投資額を計算する
/// - 注意：投資モジュールはuid（個人ID）を使用するため、
///   グループ内の全メンバーの投資額を集計する必要がある
/// - 実装例：
///   1. グループのメンバーリストを取得
///   2. 各メンバーのactiveInvestmentsProviderを監視
///   3. 全投資額を合計
final investmentAmountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, groupId) async {
  // TODO: Implement to fetch from investment portfolio
  // 現在のところプレースホルダー値を返す
  return 50000; // プレースホルダー: 月額5万円の投資
}).keepAlive();

/// 社会貢献額プロバイダー
/// 実装の最適化：
/// - keepAlive: 寄付履歴のキャッシュを保持
/// - 社会貢献額は月単位で集計できる
/// - 実データ：totalDonationsProviderから総寄付額を取得
final socialContributionAmountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, groupId) async {
  try {
    // 社会貢献モジュールから実際の寄付総額を取得
    final totalDonations = await ref.watch(totalDonationsProvider(groupId).future);
    return totalDonations;
  } catch (e) {
    // エラー時はプレースホルダー値を返す
    return 0;
  }
}).keepAlive();

/// 財務健全性スコアプロバイダー（メインプロバイダー）
final financialHealthScoreProvider = FutureProvider.autoDispose
    .family<FinancialHealthScore?, String>((ref, groupId) async {
  // 依存するプロバイダーから情報を取得
  final budgetAsync = ref.watch(householdBudgetProvider(groupId));
  final summaryAsync = ref.watch(monthlyExpenseSummaryProvider(groupId));
  final investmentAsync = ref.watch(investmentAmountProvider(groupId));
  final socialAsync = ref.watch(socialContributionAmountProvider(groupId));

  // すべての非同期処理が完了するまで待機
  final budget = budgetAsync.when(
    data: (data) => data,
    error: (error, stack) => null,
    loading: () => null,
  );

  final summary = summaryAsync.when(
    data: (data) => data,
    error: (error, stack) => null,
    loading: () => null,
  );

  final investment = investmentAsync.when(
    data: (data) => data,
    error: (error, stack) => 0,
    loading: () => 0,
  );

  final social = socialAsync.when(
    data: (data) => data,
    error: (error, stack) => 0,
    loading: () => 0,
  );

  // 必要なデータがない場合はnullを返す
  if (budget == null || summary == null) {
    return null;
  }

  // スコアを計算
  return FinancialHealthCalculator.calculateScore(
    groupId: groupId,
    budget: budget,
    summary: summary,
    investmentAmount: investment,
    socialContributionAmount: social,
  );
});

/// 財務健全性スコアの詳細情報プロバイダー
/// 実装の最適化：
/// - keepAlive: スコア計算結果のキャッシュを保持
/// - スコアが変わらない限り、詳細情報は再計算しない
final financialHealthScoreDetailProvider = FutureProvider.autoDispose
    .family<FinancialHealthScoreDetail?, String>((ref, groupId) async {
  final scoreAsync = ref.watch(financialHealthScoreProvider(groupId));

  final score = scoreAsync.when(
    data: (data) => data,
    error: (error, stack) => null,
    loading: () => null,
  );

  if (score == null) {
    return null;
  }

  // カテゴリ情報を構築
  final categories = [
    HealthScoreCategory(
      categoryName: 'savingsRatio',
      displayName: '貯蓄率',
      score: score.savingsRatioScore,
      description: '毎月の収入に対する貯蓄額の割合',
    ),
    HealthScoreCategory(
      categoryName: 'budgetAdherence',
      displayName: '予算遵守率',
      score: score.budgetAdherenceScore,
      description: '予算に対する実際の支出の比率',
    ),
    HealthScoreCategory(
      categoryName: 'expenseControl',
      displayName: '支出管理',
      score: score.expenseControlScore,
      description: '支出パターンの安定性',
    ),
    HealthScoreCategory(
      categoryName: 'investmentEngagement',
      displayName: '投資参加度',
      score: score.investmentEngagementScore,
      description: '収入に対する投資額の割合',
    ),
    HealthScoreCategory(
      categoryName: 'socialImpact',
      displayName: '社会貢献度',
      score: score.socialImpactScore,
      description: '寄付などの社会貢献活動',
    ),
  ];

  // 推奨事項を生成
  final recommendations = FinancialHealthCalculator.generateRecommendations(score);

  // 月別トレンドを計算（プレースホルダー）
  // 実装では複数月のデータから前月比を計算
  const monthlyTrend = 2.5; // プレースホルダー

  return FinancialHealthScoreDetail(
    score: score,
    categories: categories,
    recommendations: recommendations,
    monthlyTrend: monthlyTrend,
  );
}).keepAlive();

/// 財務健全性スコア推奨事項プロバイダー
/// 実装の最適化：
/// - keepAlive: 推奨事項のキャッシュを保持
/// - 詳細情報が変わらない限り推奨事項も再生成しない
final financialHealthRecommendationsProvider = FutureProvider.autoDispose
    .family<List<HealthScoreRecommendation>, String>((ref, groupId) async {
  final detailAsync = ref.watch(financialHealthScoreDetailProvider(groupId));

  final detail = detailAsync.when(
    data: (data) => data,
    error: (error, stack) => null,
    loading: () => null,
  );

  return detail?.recommendations ?? [];
}).keepAlive();

/// 財務健全性スコア月別トレンドプロバイダー（プレースホルダー）
/// 実装の最適化：
/// - keepAlive: トレンド履歴のキャッシュを保持
/// - 6ヶ月のトレンドデータは頻繁には変わらない
/// - TODO: 将来の最適化で遅延読み込みを実装（当月分を優先、その後過去月分を読み込む）
final financialHealthScoreTrendProvider = FutureProvider.autoDispose
    .family<List<FinancialHealthScoreTrend>, String>((ref, groupId) async {
  // TODO: Implement Firestore query to fetch score history
  // For now, return placeholder data for the past 6 months
  final now = DateTime.now();

  return List.generate(6, (index) {
    final month = DateTime(now.year, now.month - (5 - index), 1);
    return FinancialHealthScoreTrend(
      groupId: groupId,
      month: '${month.year}-${month.month.toString().padLeft(2, '0')}',
      overallScore: 70 + (index * 3), // 70から徐々に増加
      categoryScores: {
        'savingsRatio': 65 + (index * 4),
        'budgetAdherence': 75 + (index * 2),
        'expenseControl': 70 + (index * 3),
        'investmentEngagement': 60 + (index * 3),
        'socialImpact': 55 + (index * 2),
      },
    );
  });
}).keepAlive();

/// 目標達成時のスコア予測プロバイダー
/// Priority 5.3: Goal-Score Relationship
/// 実装の最適化：
/// - keepAlive: 目標-スコア関連性のキャッシュを保持
/// - 現在の目標達成進度とそれが及ぼすスコア影響を計算
/// TODO: 完全な実装では、groupStreamProviderを監視して実際の月次目標を使用する
final goalScorePredictionProvider = FutureProvider.autoDispose
    .family<({int currentScore, int projectedScore, int scoreGain}), String>((ref, groupId) async {
  try {
    // 現在のスコア情報を取得
    final scoreAsync = ref.watch(financialHealthScoreProvider(groupId));

    final score = scoreAsync.when(
      data: (data) => data,
      error: (error, stack) => null,
      loading: () => null,
    );

    if (score == null) {
      return (currentScore: 0, projectedScore: 0, scoreGain: 0);
    }

    // 貯蓄目標達成時のスコア向上を計算
    // 現在のスコアに基づいて推定される向上を計算（プレースホルダー月次目標: 30000）
    const placeholderMonthlyGoal = 30000;
    final savingRatioBoost = _calculateGoalAchievementBoost(
      score.savingsRatioScore,
      placeholderMonthlyGoal,
    );

    const budgetAdherenceBoost = 3; // 目標達成で予算遵守率が向上
    final totalBoost = savingRatioBoost + budgetAdherenceBoost;
    final projectedScore = (score.overallScore + totalBoost).clamp(0, 100);

    return (
      currentScore: score.overallScore,
      projectedScore: projectedScore.toInt(),
      scoreGain: (projectedScore - score.overallScore).toInt(),
    );
  } catch (e) {
    return (currentScore: 0, projectedScore: 0, scoreGain: 0);
  }
}).keepAlive();

/// 目標達成によるスコア向上を計算するヘルパー関数
int _calculateGoalAchievementBoost(int currentSavingRatioScore, int monthlyGoal) {
  // 目標達成で貯蓄率スコアが5-10ポイント向上すると仮定
  if (currentSavingRatioScore < 50) return 10;
  if (currentSavingRatioScore < 70) return 7;
  if (currentSavingRatioScore < 90) return 5;
  return 2; // 既に高いスコアではわずかな向上のみ
}

/// スコアマイルストーン通知プロバイダー
/// Priority 5.4: Milestone Notifications
/// 実装の最適化：
/// - keepAlive: マイルストーン追跡情報をキャッシュ保持
/// - スコア改善時に重要な達成を通知
final scoreMilestoneNotificationProvider = FutureProvider.autoDispose
    .family<List<ScoreMilestone>, String>((ref, groupId) async {
  try {
    final scoreAsync = ref.watch(financialHealthScoreProvider(groupId));
    final notificationService = ref.watch(notificationServiceProvider);

    final score = scoreAsync.when(
      data: (data) => data,
      error: (error, stack) => null,
      loading: () => null,
    );

    if (score == null) {
      return [];
    }

    // スコアマイルストーン（75, 80, 85, 90）
    const milestones = [75, 80, 85, 90];
    final reachedMilestones = <ScoreMilestone>[];

    for (final milestone in milestones) {
      if (score.overallScore >= milestone) {
        reachedMilestones.add(
          ScoreMilestone(
            milestone: milestone,
            reached: true,
            message: _getMilestoneMessage(milestone),
          ),
        );
      }
    }

    return reachedMilestones;
  } catch (e) {
    return [];
  }
}).keepAlive();

/// スコアマイルストーンモデル
class ScoreMilestone {
  final int milestone;
  final bool reached;
  final String message;

  ScoreMilestone({
    required this.milestone,
    required this.reached,
    required this.message,
  });
}

/// マイルストーンメッセージを生成するヘルパー関数
String _getMilestoneMessage(int milestone) {
  switch (milestone) {
    case 75:
      return '素晴らしい！財務健全性スコアが75に到達しました！';
    case 80:
      return '優秀です！スコアが80に到達。あなたの財務管理は素晴らしい成績です！';
    case 85:
      return '素晴らしい達成！スコアが85に。優秀な財務健全性です！';
    case 90:
      return '最高峰！スコアが90に到達。あなたの財務管理は最優秀です！🎉';
    default:
      return 'スコアマイルストーン: $milestone に到達';
  }
}
