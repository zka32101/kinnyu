import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../household/domain/models/household_expense_summary.dart';
import '../../../household/presentation/providers/household_budget_provider.dart';

/// 貯蓄ダッシュボード統合情報
class SavingsDashboard {
  final int totalIncome;
  final int totalExpense;
  final int savingsAmount;
  final double goalProgress;

  SavingsDashboard({
    required this.totalIncome,
    required this.totalExpense,
    required this.savingsAmount,
    required this.goalProgress,
  });
}

/// 貯蓄目標モデル
class SavingsGoal {
  final String id;
  final String name;
  final int targetAmount;
  final int currentAmount;
  final DateTime deadline;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
  });
}

/// 統合ダッシュボードプロバイダー（最新のキャッシュ付き）
final savingsDashboardProvider =
    FutureProvider.autoDispose.family<SavingsDashboard, String>(
  (ref, groupId) async {
    // 複数のデータソースを並列取得
    final budgetAsync = ref.watch(householdBudgetProvider(groupId));
    final goalsAsync = ref.watch(savingsGoalProvider(groupId));

    // Extract actual data from AsyncValue
    final budget = budgetAsync.maybeWhen(
      data: (data) => data,
      orElse: () => null,
    );
    final goals = goalsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => [],
    );

    // Calculate aggregate metrics
    if (budget == null) {
      return DashboardMetrics(
        totalBalance: 0,
        monthlyIncome: 0,
        totalExpense: 0,
        savingsAmount: 0,
        savingsRate: 0.0,
        goalProgress: 0.0,
      );
    }

    final totalIncome = budget.allocatedBudget; // Assuming allocated = income
    final totalExpense = budget.spentAmount;
    final savingsAmount = totalIncome - totalExpense;

    // Calculate goal progress (0.0 to 1.0)
    double goalProgress = 0.0;
    if (goals.isNotEmpty) {
      int totalSaved = 0;
      int totalTarget = 0;
      for (final goal in goals) {
        totalSaved += goal.currentAmount;
        totalTarget += goal.targetAmount;
      }
      goalProgress = totalTarget > 0 ? totalSaved / totalTarget : 0.0;
    }

    return SavingsDashboard(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      savingsAmount: savingsAmount,
      goalProgress: goalProgress.clamp(0.0, 1.0),
    );
  },
);

/// 月間支出サマリープロバイダー
final monthlyExpenseSummaryProvider =
    FutureProvider.autoDispose.family<HouseholdExpenseSummary, (String, String)>(
  (ref, params) async {
    final (groupId, month) = params;

    // Placeholder implementation - replace with actual service call
    return HouseholdExpenseSummary(
      groupId: groupId,
      month: month,
      totalIncome: 350000,
      totalExpense: 305000,
      savingAmount: 45000,
      categoryBreakdown: {
        '食費': 75000,
        '交通費': 35000,
        'エネルギー': 18000,
        '娯楽': 30000,
        'その他': 147000,
      },
    );
  },
);

/// カテゴリ別支出プロバイダー（最新のキャッシュ付き）
final categoryBreakdownProvider =
    FutureProvider.autoDispose.family<Map<String, int>, (String, String)>(
  (ref, params) async {
    final (groupId, month) = params;

    // Placeholder implementation - replace with actual service call
    return {
      '食費': 75000,
      '交通費': 35000,
      'エネルギー': 18000,
      '娯楽': 30000,
      'その他': 147000,
    };
  },
);

/// 貯蓄目標プロバイダー（最新のキャッシュ付き）
final savingsGoalProvider =
    FutureProvider.autoDispose.family<List<SavingsGoal>, String>(
  (ref, groupId) async {
    // Placeholder implementation - replace with actual service call
    return [
      SavingsGoal(
        id: 'goal_1',
        name: 'Emergency Fund',
        targetAmount: 300000,
        currentAmount: 150000,
        deadline: DateTime.now().add(const Duration(days: 180)),
      ),
      SavingsGoal(
        id: 'goal_2',
        name: 'Vacation',
        targetAmount: 500000,
        currentAmount: 200000,
        deadline: DateTime.now().add(const Duration(days: 365)),
      ),
    ];
  },
);

/// 複数プロバイダー監視の最小化のためのメモ化プロバイダー
/// 使用例: ref.watch(dashboardMetricsProvider(groupId)) の代わりに
/// ref.watch(savingsDashboardProvider(groupId)) を各セクションで監視
final dashboardMetricsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, groupId) async {
    // これは使用例として示すだけで、実際の実装では
    // 各セクションが独立した FutureProvider を監視すべき
    final dashboard = await ref.watch(savingsDashboardProvider(groupId).future);
    final goals = await ref.watch(savingsGoalProvider(groupId).future);

    return {
      'dashboard': dashboard,
      'goals': goals,
    };
  },
);
