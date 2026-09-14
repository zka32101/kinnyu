/// 評価の深刻度レベル
enum EvaluationSeverity {
  excellent,  // 優秀
  good,       // 良い
  caution,    // 注意
  warning,    // 警告
  critical,   // 重大
}

/// カテゴリ別の支出評価
class CategoryEvaluation {
  final String category;            // e.g., "food", "transport", "entertainment"
  final int actualSpent;
  final int budgetAmount;
  final int difference;             // actual - budget (negative = under budget)
  final double utilization;         // actual / budget (%)
  final EvaluationSeverity severity;
  final String recommendation;      // "支出を15%削減してください"

  const CategoryEvaluation({
    required this.category,
    required this.actualSpent,
    required this.budgetAmount,
    required this.difference,
    required this.utilization,
    required this.severity,
    required this.recommendation,
  });
}

/// 月間の支出評価サマリー
class SpendingEvaluation {
  final String groupId;
  final String month;               // YYYY-MM
  final List<CategoryEvaluation> categoryEvaluations;
  final String overallAssessment;   // 支出健全性の総合評価
  final List<String> actionableRecommendations;

  const SpendingEvaluation({
    required this.groupId,
    required this.month,
    required this.categoryEvaluations,
    required this.overallAssessment,
    required this.actionableRecommendations,
  });

  /// 平均利用率 (%)
  double get averageUtilization {
    if (categoryEvaluations.isEmpty) return 0.0;
    final total = categoryEvaluations.fold<double>(
      0.0,
      (sum, cat) => sum + cat.utilization,
    );
    return total / categoryEvaluations.length;
  }
}

/// 月間のスナップショット (過去との比較用)
class MonthlySnapshot {
  final String month;               // YYYY-MM
  final int income;
  final int expense;
  final int savings;
  final double savingsRate;
  final Map<String, int> categoryExpenses;

  const MonthlySnapshot({
    required this.month,
    required this.income,
    required this.expense,
    required this.savings,
    required this.savingsRate,
    required this.categoryExpenses,
  });
}

/// 6ヶ月の履歴比較
class HistoricalComparison {
  final String groupId;
  final List<MonthlySnapshot> monthlySnapshots;  // 直近6ヶ月

  const HistoricalComparison({
    required this.groupId,
    required this.monthlySnapshots,
  });

  /// 平均貯蓄率 (%)
  double get avgSavingsRate {
    if (monthlySnapshots.isEmpty) return 0.0;
    final total = monthlySnapshots.fold<double>(
      0.0,
      (sum, snap) => sum + snap.savingsRate,
    );
    return total / monthlySnapshots.length;
  }

  /// 6ヶ月の総貯蓄額
  int get totalSavings6Months =>
      monthlySnapshots.fold<int>(0, (sum, snap) => sum + snap.savings);

  /// 6ヶ月の平均月間貯蓄
  int get avgMonthlySavings =>
      monthlySnapshots.isEmpty ? 0 : (totalSavings6Months ~/ monthlySnapshots.length);
}
