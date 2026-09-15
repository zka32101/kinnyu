import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/spending_evaluation_service.dart';
import '../../domain/models/spending_evaluation.dart';
import '../../domain/models/household_balance_sheet.dart';

/// SpendingEvaluationService プロバイダー
/// Provides access to spending evaluation and recommendation generation
final spendingEvaluationServiceProvider = Provider((ref) {
  return SpendingEvaluationService();
});

/// 簡易バランスサマリー (当月)
final simpleBalanceSummaryProvider =
    FutureProvider.autoDispose.family<SimpleBalanceSummary, String>(
  (ref, groupId) async {
    // プレースホルダー実装 - 実際のデータ取得は今後の統合時に実装
    final monthlyIncome = 300000;
    final monthlyExpense = 180000;
    final monthlySavings = monthlyIncome - monthlyExpense;
    final savingsRate = monthlyIncome > 0
        ? (monthlySavings / monthlyIncome) * 100
        : 0.0;

    return SimpleBalanceSummary(
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      monthlySavings: monthlySavings,
      savingsRate: savingsRate,
      categoryExpenses: {
        '食費': 40000,
        '交通費': 20000,
        'エネルギー': 15000,
        '娯楽': 25000,
        'その他': 80000,
      },
    );
  },
);

/// 詳細バランスシート
final householdBalanceSheetProvider =
    FutureProvider.autoDispose.family<HouseholdBalanceSheet, String>(
  (ref, groupId) async {
    // プレースホルダー: 実装時に実際の資産・負債データを Firestore から取得
    return HouseholdBalanceSheet(
      groupId: groupId,
      asOfDate: DateTime.now(),
      savingsAccount: 500000,
      checkingAccount: 100000,
      investmentsValue: 1500000,
      otherAssets: 200000,
      shortTermDebt: 0,
      longTermDebt: 0,
      otherLiabilities: 0,
      monthlyIncome: 300000,
      monthlyExpense: 180000,
    );
  },
);

/// 履歴比較 (6ヶ月)
final historicalComparisonProvider =
    FutureProvider.autoDispose.family<HistoricalComparison, String>(
  (ref, groupId) async {
    final service = ref.watch(spendingEvaluationServiceProvider);
    return await service.getHistoricalComparison(groupId);
  },
);

/// 月間支出評価
final spendingEvaluationProvider =
    FutureProvider.autoDispose.family<SpendingEvaluation, (String, String)>(
  (ref, params) async {
    final (groupId, month) = params;

    // プレースホルダー実装 - 実際のデータ取得と評価は今後の統合時に実装
    return SpendingEvaluation(
      groupId: groupId,
      month: month,
      categoryEvaluations: [
        CategoryEvaluation(
          category: '食費',
          actualSpent: 45000,
          budgetAmount: 40000,
          difference: 5000,
          utilization: 112.5,
          severity: EvaluationSeverity.caution,
          recommendation: '食費の支出が予算超過です。約¥5000 削減を推奨します。',
        ),
        CategoryEvaluation(
          category: '交通費',
          actualSpent: 18000,
          budgetAmount: 20000,
          difference: -2000,
          utilization: 90.0,
          severity: EvaluationSeverity.good,
          recommendation: '交通費の支出は予算内に良く収まっています。',
        ),
      ],
      overallAssessment: '複数カテゴリで予算超過があります。改善が必要です。',
      actionableRecommendations: ['食費の支出が予算超過です。約¥5000 削減を推奨します。'],
    );
  },
);

/// 現在の月 (YYYY-MM フォーマット) を取得
String _getCurrentMonth() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}
