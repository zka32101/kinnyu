import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/financial_insight.dart';
import '../../domain/services/financial_insights_service.dart';
import './financial_health_provider.dart';
import './household_balance_sheet_provider.dart';

// ===== Analysis Providers =====

/// 前月の支出サマリー
final previousMonthExpenseProvider = FutureProvider.autoDispose
    .family<HouseholdExpenseSummary?, String>((ref, groupId) async {
  // 前月の支出データを取得
  // 実装時：Firestoreから該当する月のデータを取得
  // 現在：プレースホルダー
  return null;
});

/// 支出の異常を分析
final spendingAnomaliesProvider = FutureProvider.autoDispose
    .family<List<SpendingAnomaly>, String>((ref, groupId) async {
  try {
    // 現在月と前月の支出を取得（仮）
    final currentMonthStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    final previousMonth = DateTime.now().subtract(Duration(days: DateTime.now().day));
    final previousMonthStr = '${previousMonth.year}-${previousMonth.month.toString().padLeft(2, '0')}';

    // 注：実装時には実際のデータプロバイダーから取得
    // final currentExpense = await ref.watch(monthlyExpenseSummaryProvider((groupId, currentMonthStr)).future);
    // final previousExpense = await ref.watch(monthlyExpenseSummaryProvider((groupId, previousMonthStr)).future);

    // モック実装：2つのダミーサマリーを作成
    final currentExpense = HouseholdExpenseSummary(
      month: currentMonthStr,
      groupId: groupId,
      categoryExpenses: {
        'food': 85000,
        'transportation': 25000,
        'utilities': 12000,
        'entertainment': 15000,
        'healthcare': 5000,
        'education': 10000,
        'other': 8000,
      },
      totalExpense: 160000,
      totalIncome: 300000,
    );

    final previousExpense = HouseholdExpenseSummary(
      month: previousMonthStr,
      groupId: groupId,
      categoryExpenses: {
        'food': 68000,
        'transportation': 24000,
        'utilities': 12000,
        'entertainment': 12000,
        'healthcare': 3000,
        'education': 10000,
        'other': 6000,
      },
      totalExpense: 135000,
      totalIncome: 300000,
    );

    // 予算目標（仮）
    const budgetTargets = {
      'food': 70000,
      'transportation': 25000,
      'utilities': 12000,
      'entertainment': 15000,
      'healthcare': 5000,
      'education': 10000,
      'other': 10000,
    };

    return FinancialInsightsService.analyzeAnomalies(
      currentExpense,
      previousExpense,
      budgetTargets,
    );
  } catch (e) {
    return [];
  }
});

/// ユーザーのコンテキストを評価
final userContextProvider = FutureProvider.autoDispose
    .family<InsightContext, String>((ref, groupId) async {
  try {
    final score = await ref.watch(financialHealthScoreProvider(groupId).future);
    final trends = await ref.watch(financialHealthScoreTrendProvider(groupId).future);

    return FinancialInsightsService.assessUserContext(trends, score.overallScore);
  } catch (e) {
    return InsightContext(
      userState: UserState.starter,
      scoreTrajectory: ScoreTrajectory.stable,
      monthsAtCurrentLevel: 0,
      previousThreeMonthAverage: 70,
      benchmarkPercentile: 50.0,
    );
  }
});

/// 全インサイトを生成
final financialInsightsProvider = FutureProvider.autoDispose
    .family<List<FinancialInsight>, String>((ref, groupId) async {
  try {
    final score = await ref.watch(financialHealthScoreProvider(groupId).future);
    final trends = await ref.watch(financialHealthScoreTrendProvider(groupId).future);
    final anomalies = await ref.watch(spendingAnomaliesProvider(groupId).future);

    return FinancialInsightsService.generateRecommendations(
      score,
      trends,
      anomalies,
    );
  } catch (e) {
    return [];
  }
});

/// ダッシュボード用の上位インサイト（最大3件）
final topInsightsProvider = FutureProvider.autoDispose
    .family<List<FinancialInsight>, String>((ref, groupId) async {
  try {
    final allInsights = await ref.watch(financialInsightsProvider(groupId).future);
    return FinancialInsightsService.prioritizeInsights(allInsights, 3);
  } catch (e) {
    return [];
  }
});

/// 各インサイトのコンテキストメッセージ
final insightContextualMessagesProvider = FutureProvider.autoDispose
    .family<Map<String, String>, (String, String)>((ref, params) async {
  final (groupId, locale) = params;

  try {
    final insights = await ref.watch(financialInsightsProvider(groupId).future);
    final context = await ref.watch(userContextProvider(groupId).future);

    final messages = <String, String>{};
    for (final insight in insights) {
      messages[insight.id] = FinancialInsightsService.composeContextualMessage(
        insight,
        context,
        locale,
      );
    }
    return messages;
  } catch (e) {
    return {};
  }
});

// ===== Helper Models for Mocking =====

/// 家計支出サマリーのモックモデル
class HouseholdExpenseSummary {
  final String month;
  final String groupId;
  final Map<String, int> categoryExpenses;
  final int totalExpense;
  final int totalIncome;

  HouseholdExpenseSummary({
    required this.month,
    required this.groupId,
    required this.categoryExpenses,
    required this.totalExpense,
    required this.totalIncome,
  });

  double get savingsRate => totalIncome > 0 ? (totalIncome - totalExpense) / totalIncome : 0.0;
}
