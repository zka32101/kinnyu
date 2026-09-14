import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/spending_evaluation_service.dart';
import '../../domain/models/spending_evaluation.dart';
import '../../domain/models/household_balance_sheet.dart';
import 'household_budget_provider.dart';
import 'household_provider.dart';

/// SpendingEvaluationService プロバイダー
final spendingEvaluationServiceProvider = Provider((ref) {
  return SpendingEvaluationService(FirebaseFirestore.instance);
});

/// 簡易バランスサマリー (当月)
final simpleBalanceSummaryProvider =
    FutureProvider.autoDispose.family<SimpleBalanceSummary, String>(
  (ref, groupId) async {
    final householdAsync = ref.watch(monthlyExpenseSummaryProvider((groupId, _getCurrentMonth())));

    return householdAsync.when(
      data: (summary) {
        // プレースホルダー: 実装時に実際の収入データを取得
        final monthlyIncome = 300000;
        final monthlyExpense = summary.totalExpense;
        final monthlySavings = monthlyIncome - monthlyExpense;
        final savingsRate = monthlyIncome > 0
            ? (monthlySavings / monthlyIncome) * 100
            : 0.0;

        return SimpleBalanceSummary(
          monthlyIncome: monthlyIncome,
          monthlyExpense: monthlyExpense,
          monthlySavings: monthlySavings,
          savingsRate: savingsRate,
          categoryExpenses: summary.categoryExpenses,
        );
      },
      loading: () => throw Exception('Loading...'),
      error: (error, stack) => throw error,
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
    final service = ref.watch(spendingEvaluationServiceProvider);

    // バジェットと支出サマリーを取得
    final budgetAsync = ref.watch(householdBudgetProvider(groupId));
    final expenseAsync = ref.watch(monthlyExpenseSummaryProvider((groupId, month)));

    // 両方の AsyncValue が完了するまで待つ
    return await (
      budgetAsync.whenData((budget) async {
        return await expenseAsync.whenData((expenses) async {
          return await service.evaluateSpending(groupId, month, budget, expenses);
        });
      }).future
    );
  },
);

/// 現在の月 (YYYY-MM フォーマット) を取得
String _getCurrentMonth() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}
