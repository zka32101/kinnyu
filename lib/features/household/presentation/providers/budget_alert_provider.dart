import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/household_budget.dart';
import 'household_provider.dart';

/// 今月のカテゴリ別予算消化状況（CategoryExpenseSummary）を返す。
/// NOTE: uidをgroupIdとして代用する（household機能の他プロバイダーと同様の暫定対応）。
final currentMonthCategoryExpenseSummariesProvider =
    FutureProvider.autoDispose.family<List<CategoryExpenseSummary>, String>(
  (ref, groupId) async {
    final service = ref.watch(householdServiceProvider);
    final now = DateTime.now();

    final budget = await service.getBudget(groupId);
    final expenses = await service.getMonthlyExpense(
      groupId: groupId,
      month: now,
    );

    return BudgetCategory.values.map((category) {
      final spent = expenses.getTotalByCategory(category);
      final budgetAmount = budget?.categoryBudgets[category] ?? 0;
      return CategoryExpenseSummary(
        category: category,
        spent: spent,
        budget: budgetAmount,
      );
    }).toList();
  },
);

/// 予算に達していない（isWarning）、または超過している（isOverBudget）カテゴリのみを返す。
final budgetAlertCategoriesProvider =
    FutureProvider.autoDispose.family<List<CategoryExpenseSummary>, String>(
  (ref, groupId) async {
    final summaries =
        await ref.watch(currentMonthCategoryExpenseSummariesProvider(groupId).future);
    return summaries
        .where((s) => s.budget > 0 && (s.isOverBudget || s.isWarning))
        .toList();
  },
);
