import 'package:riverpod/riverpod.dart';
import '../../data/household_service.dart';
import '../../domain/models/household_budget.dart';
import '../../domain/models/household_expense_summary.dart';
import 'household_provider.dart';

/// 世帯の予算設定を取得
final householdBudgetProvider =
    FutureProvider.family<HouseholdBudget?, String>((ref, groupId) async {
  final service = ref.watch(householdServiceProvider);
  return service.getBudget(groupId);
});

/// 世帯の月間支出を取得（カテゴリ別集計）
final householdMonthlyExpenseProvider = FutureProvider.family<HouseholdMonthlyExpense, ({String groupId, DateTime month})>(
  (ref, params) async {
    final service = ref.watch(householdServiceProvider);
    return service.getMonthlyExpense(
      groupId: params.groupId,
      month: params.month,
    );
  },
);

/// カテゴリ別の支出サマリー（予算と実績を比較）
final householdExpenseSummaryProvider = FutureProvider.family<
    Map<BudgetCategory, HouseholdExpenseSummary>,
    ({String groupId, DateTime month})>(
  (ref, params) async {
    final service = ref.watch(householdServiceProvider);

    final budget = await service.getBudget(params.groupId);
    final expenses = await service.getMonthlyExpense(
      groupId: params.groupId,
      month: params.month,
    );

    final summaries = <BudgetCategory, HouseholdExpenseSummary>{};
    final monthStr = '${params.month.year}-${params.month.month.toString().padLeft(2, '0')}';

    for (var category in BudgetCategory.values) {
      final spent = expenses.getTotalByCategory(category);
      final budgetAmount = budget?.categoryBudgets[category] ?? 0;

      summaries[category] = HouseholdExpenseSummary(
        groupId: params.groupId,
        month: monthStr,
        totalIncome: 0,
        totalExpense: spent,
        savingAmount: 0,
        categoryBreakdown: {category.name: spent},
      );
    }

    return summaries;
  },
);

/// 予算設定を初期化
final initializeBudgetProvider =
    FutureProvider.family<HouseholdBudget, String>((ref, groupId) async {
  final service = ref.watch(householdServiceProvider);
  return service.initializeBudget(groupId);
});
