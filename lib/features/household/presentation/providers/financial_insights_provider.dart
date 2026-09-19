import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/financial_insight.dart';
import '../../domain/models/household_expense_summary.dart';
import '../../domain/services/financial_insights_service.dart';
import './financial_health_provider.dart';
import './household_balance_sheet_provider.dart';

// ===== Analysis Providers =====

/// 前月の支出サマリー
/// エッジケース対応: 初月の場合はnullを返す
final previousMonthExpenseProvider = FutureProvider.autoDispose
    .family<HouseholdExpenseSummary?, String>((ref, groupId) async {
  // 前月の支出データを取得
  // 実装時：Firestoreから該当する月のデータを取得
  // 現在：プレースホルダー
  return null;
});

/// 支出の異常を分析
/// エッジケース対応:
/// - 初月: 前月データがないため異常なし
/// - 支出がない: 全て0として処理（異常なし）
/// - カテゴリ不足: スキップされる
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
      categoryBreakdown: {
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
      savingAmount: 300000 - 160000,
    );

    final previousExpense = HouseholdExpenseSummary(
      month: previousMonthStr,
      groupId: groupId,
      categoryBreakdown: {
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
      savingAmount: 300000 - 135000,
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
    debugPrint('Error analyzing anomalies: $e');
    return [];
  }
});

/// ユーザーのコンテキストを評価
/// エッジケース対応:
/// - スコアデータ不足: startuerとして分類
/// - トレンドデータなし: スコア軌跡は'stable'
/// - エラー時: デフォルト値を返す（クラッシュせず）
final userContextProvider = FutureProvider.autoDispose
    .family<InsightContext, String>((ref, groupId) async {
  try {
    final score = await ref.watch(financialHealthScoreProvider(groupId).future);
    final trends = await ref.watch(financialHealthScoreTrendProvider(groupId).future);

    return FinancialInsightsService.assessUserContext(trends, score.overallScore);
  } catch (e) {
    debugPrint('Error assessing user context: $e');
    // デフォルト値: 初期ユーザー、安定トレンド
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
/// エッジケース対応:
/// - スコアなし: 空のリストを返す（UIで「利用可能なインサイトなし」と表示）
/// - 異常検知なし: 改善提案のみを返す
/// - 全インサイトなし: 空のリストを返す
final financialInsightsProvider = FutureProvider.autoDispose
    .family<List<FinancialInsight>, String>((ref, groupId) async {
  try {
    final score = await ref.watch(financialHealthScoreProvider(groupId).future);
    final trends = await ref.watch(financialHealthScoreTrendProvider(groupId).future);
    final anomalies = await ref.watch(spendingAnomaliesProvider(groupId).future);

    final insights = FinancialInsightsService.generateRecommendations(
      score,
      trends,
      anomalies ?? [],
    );

    return insights;
  } catch (e) {
    debugPrint('Error generating financial insights: $e');
    return [];
  }
});

/// ダッシュボード用の上位インサイト（最大3件）
/// パフォーマンス最適化:
/// - financialInsightsProviderから上位3件を取得
/// - .autoDisposeで不使用時にメモリ解放
/// - 毎回の優先度付けを効率化
final topInsightsProvider = FutureProvider.autoDispose
    .family<List<FinancialInsight>, String>((ref, groupId) async {
  try {
    final allInsights = await ref.watch(financialInsightsProvider(groupId).future);
    return FinancialInsightsService.prioritizeInsights(allInsights, 3);
  } catch (e) {
    debugPrint('Error getting top insights: $e');
    return [];
  }
});

/// 各インサイトのコンテキストメッセージ
/// 多言語対応: 日本語（'ja'）と英語（'en'）
/// エッジケース対応:
/// - インサイトなし: 空マップを返す
/// - メッセージ生成エラー: スキップして他を続行
final insightContextualMessagesProvider = FutureProvider.autoDispose
    .family<Map<String, String>, (String, String)>((ref, params) async {
  final (groupId, locale) = params;

  try {
    final insights = await ref.watch(financialInsightsProvider(groupId).future);
    final context = await ref.watch(userContextProvider(groupId).future);

    final messages = <String, String>{};
    for (final insight in insights) {
      try {
        messages[insight.id] = FinancialInsightsService.composeContextualMessage(
          insight,
          context,
          locale,
        );
      } catch (e) {
        debugPrint('Error composing message for insight ${insight.id}: $e');
        messages[insight.id] = insight.description;
      }
    }
    return messages;
  } catch (e) {
    debugPrint('Error getting contextual messages: $e');
    return {};
  }
});
