import 'package:flutter/foundation.dart';
import '../domain/models/household_balance_sheet.dart';
import '../domain/models/household_budget.dart';
import '../domain/models/household_expense_summary.dart';
import '../domain/models/spending_evaluation.dart';

/// 支出評価とレコメンデーション生成サービス
class SpendingEvaluationService {
  SpendingEvaluationService();

  /// 月間の支出をバジェットに対して評価
  Future<SpendingEvaluation> evaluateSpending(
    String groupId,
    String month,
    HouseholdBudget budget,
    HouseholdExpenseSummary summary,
  ) async {
    final categoryEvaluations = <CategoryEvaluation>[];
    final recommendations = <String>[];

    // カテゴリごとに評価を実施
    budget.categoryBudgets.forEach((category, budgetAmount) {
      final actualAmount = summary.categoryBreakdown[category.name] ?? 0;
      final difference = actualAmount - budgetAmount;
      final utilization = budgetAmount > 0 ? (actualAmount / budgetAmount) * 100 : 0.0;

      // 深刻度を決定
      late final EvaluationSeverity severity;
      late final String recommendation;

      if (utilization <= 80) {
        severity = EvaluationSeverity.excellent;
        recommendation = '${category.displayName}の支出は予算内に収まっています。';
      } else if (utilization <= 100) {
        severity = EvaluationSeverity.good;
        recommendation = '${category.displayName}の支出が予算に近づいています。注視が必要です。';
      } else if (utilization <= 120) {
        severity = EvaluationSeverity.caution;
        final overPercent = ((utilization - 100) * budgetAmount / 100).toStringAsFixed(0);
        recommendation = '${category.displayName}の支出が予算超過です。約¥$overPercent 削減を推奨します。';
      } else if (utilization <= 150) {
        severity = EvaluationSeverity.warning;
        final overPercent = ((utilization - 100) * budgetAmount / 100).toStringAsFixed(0);
        recommendation = '${category.displayName}の支出が大幅に超過しています。約¥$overPercent 削減してください。';
      } else {
        severity = EvaluationSeverity.critical;
        final overPercent = ((utilization - 100) * budgetAmount / 100).toStringAsFixed(0);
        recommendation = '${category.displayName}の支出が極度に超過しています。緊急の対応が必要です（¥$overPercent 削減必要）。';
      }

      categoryEvaluations.add(
        CategoryEvaluation(
          category: category.name,
          actualSpent: actualAmount,
          budgetAmount: budgetAmount,
          difference: difference,
          utilization: utilization,
          severity: severity,
          recommendation: recommendation,
        ),
      );

      // 警告以上の深刻度なら推奨リストに追加
      if (severity.index >= EvaluationSeverity.caution.index) {
        recommendations.add(recommendation);
      }
    });

    // 全体的なアセスメント
    final avgUtilization = categoryEvaluations.isNotEmpty
        ? categoryEvaluations.fold<double>(0.0, (sum, cat) => sum + cat.utilization) /
            categoryEvaluations.length
        : 0.0;

    late final String overallAssessment;
    if (avgUtilization <= 80) {
      overallAssessment = '支出が予算内に良く管理されています。';
    } else if (avgUtilization <= 100) {
      overallAssessment = '支出は予算に近いですが、概ね管理状況は良好です。';
    } else if (avgUtilization <= 120) {
      overallAssessment = '複数カテゴリで予算超過があります。改善が必要です。';
    } else {
      overallAssessment = '支出が大幅に予算超過です。緊急の見直しが必要です。';
    }

    return SpendingEvaluation(
      groupId: groupId,
      month: month,
      categoryEvaluations: categoryEvaluations,
      overallAssessment: overallAssessment,
      actionableRecommendations: recommendations,
    );
  }

  /// 直近6ヶ月の履歴比較を取得
  Future<HistoricalComparison> getHistoricalComparison(
    String groupId,
  ) async {
    final now = DateTime.now();
    final snapshots = <MonthlySnapshot>[];

    // 過去6ヶ月のデータを取得
    for (int i = 5; i >= 0; i--) {
      final targetMonth = now.month - i;
      var year = now.year;
      var month = targetMonth;

      // Handle month underflow
      while (month <= 0) {
        month += 12;
        year -= 1;
      }

      final monthStr =
          '${year.toString()}-${month.toString().padLeft(2, '0')}';

      try {
        // Firestore から月間支出サマリーを取得 (現在のプレースホルダーは使用)
        // 実装時に実際のクエリに置き換える必要があります
        final snapshot = MonthlySnapshot(
          month: monthStr,
          income: 300000 + (i * 5000), // プレースホルダー
          expense: 180000 + (i * 3000), // プレースホルダー
          savings: 120000 + (i * 2000), // プレースホルダー
          savingsRate: 40.0 + (i * 0.5),
          categoryExpenses: {
            'food': 40000,
            'transport': 20000,
            'utilities': 15000,
            'entertainment': 25000,
            'other': 80000,
          },
        );
        snapshots.add(snapshot);
      } catch (e) {
        // エラー時は処理をスキップして続行
        debugPrint('Failed to fetch historical data for $monthStr: $e');
      }
    }

    // 古い順にソート
    snapshots.sort((a, b) => a.month.compareTo(b.month));

    return HistoricalComparison(
      groupId: groupId,
      monthlySnapshots: snapshots,
    );
  }

  /// 直近12ヶ月の純資産推移を取得
  Future<NetWorthHistory> getNetWorthHistory(
    String groupId, {
    int months = 12,
  }) async {
    final now = DateTime.now();
    final snapshots = <NetWorthSnapshot>[];

    // プレースホルダー：直近月の総資産・総負債を基準に、過去に遡るほど
    // 資産が少なかったと仮定して逆算する（月あたり貯蓄額の目安を差し引く）
    const currentTotalAssets = 4500000;
    const currentTotalLiabilities = 800000;
    const assumedMonthlyNetWorthGrowth = 60000;

    for (int i = months - 1; i >= 0; i--) {
      final targetMonth = now.month - i;
      var year = now.year;
      var month = targetMonth;

      while (month <= 0) {
        month += 12;
        year -= 1;
      }

      final monthStr =
          '${year.toString()}-${month.toString().padLeft(2, '0')}';

      try {
        // 実装時に実際のFirestoreクエリ（資産口座・負債残高の記録）に置き換える
        final totalAssets =
            (currentTotalAssets - (i * assumedMonthlyNetWorthGrowth))
                .clamp(0, currentTotalAssets);
        final totalLiabilities =
            (currentTotalLiabilities - (i * 5000)).clamp(0, currentTotalLiabilities);

        snapshots.add(NetWorthSnapshot(
          month: monthStr,
          totalAssets: totalAssets,
          totalLiabilities: totalLiabilities,
        ));
      } catch (e) {
        debugPrint('Failed to fetch net worth history for $monthStr: $e');
      }
    }

    snapshots.sort((a, b) => a.month.compareTo(b.month));

    return NetWorthHistory(
      groupId: groupId,
      snapshots: snapshots,
    );
  }
}
