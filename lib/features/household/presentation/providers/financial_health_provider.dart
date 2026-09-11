import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/financial_health_score.dart';
import '../../domain/models/household_budget.dart';
import '../../domain/models/household_expense_summary.dart';
import '../../domain/services/financial_health_calculator.dart';
import './household_budget_provider.dart';

/// 現在月の家計情報プロバイダー（プレースホルダー）
/// 実際の実装では、Firestoreから月別の家計サマリーを取得します
final monthlyExpenseSummaryProvider = FutureProvider.autoDispose
    .family<HouseholdExpenseSummary?, String>((ref, groupId) async {
  // TODO: Implement Firestore query to fetch monthly expense summary
  // For now, return a placeholder
  return HouseholdExpenseSummary(
    groupId: groupId,
    month: '2026-09',
    totalIncome: 500000,
    totalExpense: 300000,
    savingAmount: 200000,
    categoryBreakdown: {
      '食費': 60000,
      '光熱費': 25000,
      '交通費': 20000,
      '娯楽': 20000,
      '医療': 15000,
      '教育': 10000,
      'ショッピング': 30000,
      'その他': 120000,
    },
  );
});

/// 投資額プロバイダー（プレースホルダー）
/// 実際の実装では、ポートフォリオ情報から投資額を計算します
final investmentAmountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, groupId) async {
  // TODO: Implement to fetch from investment portfolio
  return 50000; // プレースホルダー: 月額5万円の投資
});

/// 社会貢献額プロバイダー（プレースホルダー）
/// 実際の実装では、寄付履歴から社会貢献額を計算します
final socialContributionAmountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, groupId) async {
  // TODO: Implement to fetch from donation history
  return 10000; // プレースホルダー: 月額1万円の寄付
});

/// 財務健全性スコアプロバイダー（メインプロバイダー）
final financialHealthScoreProvider = FutureProvider.autoDispose
    .family<FinancialHealthScore?, String>((ref, groupId) async {
  // 依存するプロバイダーから情報を取得
  final budgetAsync = ref.watch(householdBudgetProvider(groupId));
  final summaryAsync = ref.watch(monthlyExpenseSummaryProvider(groupId));
  final investmentAsync = ref.watch(investmentAmountProvider(groupId));
  final socialAsync = ref.watch(socialContributionAmountProvider(groupId));

  // すべての非同期処理が完了するまで待機
  final budget = await budgetAsync.when(
    data: (data) => data,
    error: (error, stack) => null,
    loading: () => null,
  );

  final summary = await summaryAsync.when(
    data: (data) => data,
    error: (error, stack) => null,
    loading: () => null,
  );

  final investment = await investmentAsync.when(
    data: (data) => data,
    error: (error, stack) => 0,
    loading: () => 0,
  );

  final social = await socialAsync.when(
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
final financialHealthScoreDetailProvider = FutureProvider.autoDispose
    .family<FinancialHealthScoreDetail?, String>((ref, groupId) async {
  final scoreAsync = ref.watch(financialHealthScoreProvider(groupId));

  final score = await scoreAsync.when(
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
});

/// 財務健全性スコア推奨事項プロバイダー
final financialHealthRecommendationsProvider = FutureProvider.autoDispose
    .family<List<HealthScoreRecommendation>, String>((ref, groupId) async {
  final detailAsync = ref.watch(financialHealthScoreDetailProvider(groupId));

  final detail = await detailAsync.when(
    data: (data) => data,
    error: (error, stack) => null,
    loading: () => null,
  );

  return detail?.recommendations ?? [];
});

/// 財務健全性スコア月別トレンドプロバイダー（プレースホルダー）
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
});
