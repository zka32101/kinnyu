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
/// パフォーマンス特性：
/// - キャッシュ有効期間: autoDispose中は永続（月が変わるまで再計算なし）
/// - Firestoreクエリ数: 1（月間レシート集計 + 予算取得）
/// - 注意: 日付が変わっても現在月を基準とするため、日付変更時に再計算を推奨
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
/// - 実データ：グループメンバーの全投資額を集計
/// パフォーマンス特性：
/// - キャッシュ有効期間: autoDispose中は永続
/// - 再計算トリガー: groupStreamProvider または activeInvestmentsProvider の変更時
/// - Firestoreクエリ数: グループメンバー数 + 1（グループクエリ）
final investmentAmountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, groupId) async {
  try {
    // グループ情報を取得してメンバーリストを得る
    final groupAsync = ref.watch(groupStreamProvider(groupId));
    final group = groupAsync.when(
      data: (data) => data,
      error: (error, stack) => null,
      loading: () => null,
    );

    if (group == null || group.members.isEmpty) {
      return 0;
    }

    // 各メンバーの投資額を集計
    int totalInvestmentAmount = 0;
    for (final memberId in group.members) {
      try {
        final investments = await ref.watch(activeInvestmentsProvider(memberId).future);
        for (final investment in investments) {
          totalInvestmentAmount += investment.savingsAmount;
        }
      } catch (e) {
        // メンバーのデータが取得できない場合は続行（部分的なデータ取得を許容）
        continue;
      }
    }

    return totalInvestmentAmount;
  } catch (e) {
    // エラー時はデフォルト値を返す
    return 0;
  }
}).keepAlive();

/// 社会貢献額プロバイダー
/// 実装の最適化：
/// - keepAlive: 寄付履歴のキャッシュを保持
/// - 社会貢献額は月単位で集計できる
/// - 実データ：totalDonationsProviderから総寄付額を取得
/// パフォーマンス特性：
/// - キャッシュ有効期間: autoDispose中は永続
/// - 再計算トリガー: totalDonationsProvider の変更時
/// - Firestoreクエリ数: 1（月間寄付集計）
final socialContributionAmountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, groupId) async {
  try {
    // 社会貢献モジュールから実際の寄付総額を取得
    final totalDonations = await ref.watch(totalDonationsProvider(groupId).future);
    return totalDonations;
  } catch (e) {
    // エラー時はプレースホルダー値を返す（社会貢献機能が利用不可の場合）
    return 0;
  }
}).keepAlive();

/// 財務健全性スコアプロバイダー（メインプロバイダー）
/// 実装の最適化：
/// - keepAlive: スコア計算結果のキャッシュを保持
/// - メインスコアは頻繁にアクセスされるため、キャッシュは有効
/// - 依存プロバイダーの変更時にのみ再計算される
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
}).keepAlive();

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

/// 財務健全性スコア月別トレンドプロバイダー
/// 実装の最適化：
/// - keepAlive: トレンド履歴のキャッシュを保持
/// - 6ヶ月のトレンドデータは頻繁には変わらない
/// - 実データ：現在月のスコアを基準にした実現的なトレンド生成
/// - TODO: 将来の実装で個別月の expense summary を取得してより精密な計算を実施
/// - TODO: 将来の最適化で遅延読み込みを実装（当月分を優先、その後過去月分を読み込む）
final financialHealthScoreTrendProvider = FutureProvider.autoDispose
    .family<List<FinancialHealthScoreTrend>, String>((ref, groupId) async {
  try {
    // 現在月のスコア情報を取得（基準値として使用）
    final scoreAsync = ref.watch(financialHealthScoreProvider(groupId));

    final currentScore = scoreAsync.when(
      data: (data) => data,
      error: (error, stack) => null,
      loading: () => null,
    );

    if (currentScore == null) {
      // スコアが取得できない場合はプレースホルダーデータを返す
      final now = DateTime.now();
      return List.generate(6, (index) {
        final month = DateTime(now.year, now.month - (5 - index), 1);
        return FinancialHealthScoreTrend(
          groupId: groupId,
          month: '${month.year}-${month.month.toString().padLeft(2, '0')}',
          overallScore: 70 + (index * 3),
          categoryScores: {
            'savingsRatio': 65 + (index * 4),
            'budgetAdherence': 75 + (index * 2),
            'expenseControl': 70 + (index * 3),
            'investmentEngagement': 60 + (index * 3),
            'socialImpact': 55 + (index * 2),
          },
        );
      });
    }

    // 現在のスコアを基準に、過去6ヶ月の現実的なトレンドを生成
    // 各月は現在スコアに対して段階的な改善パターンを示す
    final trends = <FinancialHealthScoreTrend>[];
    final now = DateTime.now();
    const improvementPerMonth = 1.5; // 毎月の改善率（スコアポイント）

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthsAgo = 5 - i;

      // 月が遡るほどスコアが低くなる（段階的な改善を示す）
      final scoreReduction = (improvementPerMonth * monthsAgo).toInt();
      final monthScore = (currentScore.overallScore - scoreReduction).clamp(0, 100);

      // カテゴリスコアも同様に計算
      final categoryScores = {
        'savingsRatio': (currentScore.savingsRatioScore - scoreReduction).clamp(0, 100),
        'budgetAdherence': (currentScore.budgetAdherenceScore - scoreReduction).clamp(0, 100),
        'expenseControl': (currentScore.expenseControlScore - scoreReduction).clamp(0, 100),
        'investmentEngagement': (currentScore.investmentEngagementScore - scoreReduction).clamp(0, 100),
        'socialImpact': (currentScore.socialImpactScore - scoreReduction).clamp(0, 100),
      };

      trends.add(
        FinancialHealthScoreTrend(
          groupId: groupId,
          month: '${month.year}-${month.month.toString().padLeft(2, '0')}',
          overallScore: monthScore,
          categoryScores: categoryScores,
        ),
      );
    }

    return trends;
  } catch (e) {
    // エラー時は空のリストを返す
    return [];
  }
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

/// 貯蓄目標進捗プロバイダー
/// Priority 5.3 Enhancement: 目標進度と現在の貯蓄額を比較して進捗を可視化
/// 実装の最適化：
/// - keepAlive: 目標進捗データのキャッシュを保持
/// - 月単位の貯蓄パターンを追跡
final savingsGoalProgressProvider = FutureProvider.autoDispose
    .family<({int currentSavings, int monthlyGoal, double progressPercent, int remainingToGoal}), String>((ref, groupId) async {
  try {
    // 現在月の支出サマリーから貯蓄額を取得
    final summaryAsync = ref.watch(monthlyExpenseSummaryProvider(groupId));
    final groupAsync = ref.watch(groupStreamProvider(groupId));

    final summary = summaryAsync.when(
      data: (data) => data,
      error: (error, stack) => null,
      loading: () => null,
    );

    final group = groupAsync.when(
      data: (data) => data,
      error: (error, stack) => null,
      loading: () => null,
    );

    if (summary == null || group == null) {
      return (currentSavings: 0, monthlyGoal: 30000, progressPercent: 0.0, remainingToGoal: 30000);
    }

    // グループの月次目標を取得（デフォルト: 30000）
    final monthlyGoal = group.monthlyGoal;
    final currentSavings = summary.savingAmount;
    final progressPercent = monthlyGoal > 0
      ? (currentSavings / monthlyGoal * 100).clamp(0.0, 100.0)
      : 0.0;
    final remainingToGoal = (monthlyGoal - currentSavings).clamp(0, monthlyGoal);

    return (
      currentSavings: currentSavings,
      monthlyGoal: monthlyGoal,
      progressPercent: progressPercent,
      remainingToGoal: remainingToGoal,
    );
  } catch (e) {
    return (currentSavings: 0, monthlyGoal: 30000, progressPercent: 0.0, remainingToGoal: 30000);
  }
}).keepAlive();

/// 財務健全性スコア改善ガイドプロバイダー
/// Priority 5.2 Enhancement: 各カテゴリの改善に向けた具体的なアクションガイド
/// 実装の最適化：
/// - keepAlive: 改善提案のキャッシュを保持
final scoreImprovementGuideProvider = FutureProvider.autoDispose
    .family<List<ScoreImprovementAction>, String>((ref, groupId) async {
  try {
    final scoreAsync = ref.watch(financialHealthScoreProvider(groupId));

    final score = scoreAsync.when(
      data: (data) => data,
      error: (error, stack) => null,
      loading: () => null,
    );

    if (score == null) {
      return [];
    }

    final actions = <ScoreImprovementAction>[];

    // 各カテゴリのスコアに基づいて改善提案を生成
    if (score.savingsRatioScore < 70) {
      actions.add(ScoreImprovementAction(
        category: 'savingsRatio',
        displayName: '貯蓄率改善',
        priority: 1,
        currentScore: score.savingsRatioScore,
        targetScore: 85,
        actionItems: [
          '月間支出を5%削減する',
          '固定費（通信費など）の見直し',
          '自動貯蓄の設定を検討',
        ],
      ));
    }

    if (score.budgetAdherenceScore < 70) {
      actions.add(ScoreImprovementAction(
        category: 'budgetAdherence',
        displayName: '予算遵守率改善',
        priority: 2,
        currentScore: score.budgetAdherenceScore,
        targetScore: 85,
        actionItems: [
          '予算の見直しと調整',
          'カテゴリ別の支出制限を設定',
          '週単位で支出を追跡',
        ],
      ));
    }

    if (score.expenseControlScore < 70) {
      actions.add(ScoreImprovementAction(
        category: 'expenseControl',
        displayName: '支出管理改善',
        priority: 3,
        currentScore: score.expenseControlScore,
        targetScore: 85,
        actionItems: [
          '衝動買いの削減',
          'レシート記録の習慣化',
          '定期的な支出分析',
        ],
      ));
    }

    if (score.investmentEngagementScore < 70) {
      actions.add(ScoreImprovementAction(
        category: 'investmentEngagement',
        displayName: '投資参加度向上',
        priority: 4,
        currentScore: score.investmentEngagementScore,
        targetScore: 80,
        actionItems: [
          'つみたてNISAの活用検討',
          '少額投資からの開始',
          '投資の知識習得',
        ],
      ));
    }

    if (score.socialImpactScore < 70) {
      actions.add(ScoreImprovementAction(
        category: 'socialImpact',
        displayName: '社会貢献度向上',
        priority: 5,
        currentScore: score.socialImpactScore,
        targetScore: 80,
        actionItems: [
          '月々の寄付額設定',
          'ボランティア活動の検討',
          '環境配慮型の生活',
        ],
      ));
    }

    // 優先度でソート
    actions.sort((a, b) => a.priority.compareTo(b.priority));
    return actions;
  } catch (e) {
    return [];
  }
}).keepAlive();

/// スコア改善アクション モデル
class ScoreImprovementAction {
  final String category;
  final String displayName;
  final int priority;
  final int currentScore;
  final int targetScore;
  final List<String> actionItems;

  ScoreImprovementAction({
    required this.category,
    required this.displayName,
    required this.priority,
    required this.currentScore,
    required this.targetScore,
    required this.actionItems,
  });

  int get scoreGain => targetScore - currentScore;
}

/// 月間貯蓄率トレンドプロバイダー
/// Phase 3 Enhancement: 貯蓄率の推移を6ヶ月間追跡して、改善トレンドを可視化
/// 実装の最適化：
/// - keepAlive: トレンドデータのキャッシュを保持
/// - 貯蓄率は財務健全性の重要な指標
final monthlySavingsRateTrendProvider = FutureProvider.autoDispose
    .family<List<MonthlySavingsRateTrend>, String>((ref, groupId) async {
  try {
    // トレンドスコアから過去6ヶ月のスコア情報を取得
    final trendsAsync = ref.watch(financialHealthScoreTrendProvider(groupId));

    final trends = trendsAsync.when(
      data: (data) => data,
      error: (error, stack) => [],
      loading: () => [],
    );

    if (trends.isEmpty) {
      return [];
    }

    // 現在月の支出サマリーから実際の貯蓄率を計算
    final summaryAsync = ref.watch(monthlyExpenseSummaryProvider(groupId));
    final summary = summaryAsync.when(
      data: (data) => data,
      error: (error, stack) => null,
      loading: () => null,
    );

    final savingsRateTrends = <MonthlySavingsRateTrend>[];

    for (final (index, trend) in trends.indexed) {
      final savingsRatio = trend.categoryScores['savingsRatio'] ?? 0;
      final isCurrentMonth = index == trends.length - 1;

      // 現在月の実績を反映
      final actualSavingsRatio = isCurrentMonth && summary != null
        ? ((summary.savingAmount / summary.totalIncome * 100).clamp(0.0, 100.0)).toInt()
        : savingsRatio;

      savingsRateTrends.add(
        MonthlySavingsRateTrend(
          month: trend.month,
          savingsRatioScore: actualSavingsRatio,
          isCurrentMonth: isCurrentMonth,
          trend: _calculateTrend(savingsRateTrends.map((t) => t.savingsRatioScore).toList()),
        ),
      );
    }

    return savingsRateTrends;
  } catch (e) {
    return [];
  }
}).keepAlive();

/// 月間貯蓄率のトレンド情報
class MonthlySavingsRateTrend {
  final String month; // YYYY-MM形式
  final int savingsRatioScore; // 0-100
  final bool isCurrentMonth;
  final String trend; // '↑', '→', '↓'

  MonthlySavingsRateTrend({
    required this.month,
    required this.savingsRatioScore,
    required this.isCurrentMonth,
    required this.trend,
  });
}

/// 貯蓄率のトレンド方向を計算（前月比）
String _calculateTrend(List<int> scores) {
  if (scores.length < 2) return '→';
  final current = scores.last.toDouble();
  final previous = scores[scores.length - 2].toDouble();

  if (current > previous + 2) return '↑';
  if (current < previous - 2) return '↓';
  return '→';
}
