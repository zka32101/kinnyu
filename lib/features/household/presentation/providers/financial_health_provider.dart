import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/financial_health_score.dart';

/// Helper: Calculate DateTime for months in the past with proper year adjustment
DateTime _calculateMonthBack(DateTime now, int monthsBack) {
  int newMonth = now.month - monthsBack;
  int newYear = now.year;

  while (newMonth < 1) {
    newMonth += 12;
    newYear--;
  }

  return DateTime(newYear, newMonth, 1);
}

/// 投資額プロバイダー - Placeholder
final investmentAmountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, groupId) async => 0);

/// 社会貢献額プロバイダー - Placeholder
final socialContributionAmountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, groupId) async => 0);

/// 財務健全性スコアプロバイダー
final financialHealthScoreProvider = FutureProvider.autoDispose
    .family<FinancialHealthScore, String>((ref, groupId) async {
  return FinancialHealthScore(
    groupId: groupId,
    calculatedAt: DateTime.now(),
    overallScore: 70,
    savingsRatioScore: 70,
    budgetAdherenceScore: 70,
    expenseControlScore: 70,
    investmentEngagementScore: 70,
    socialImpactScore: 70,
  );
});

/// スコア詳細プロバイダー
final financialHealthScoreDetailProvider = FutureProvider.autoDispose
    .family<FinancialHealthScoreDetail?, String>((ref, groupId) async {
  return null;
});

/// スコアトレンドプロバイダー
final financialHealthScoreTrendProvider = FutureProvider.autoDispose
    .family<List<FinancialHealthScoreTrend>, String>((ref, groupId) async {
  final now = DateTime.now();
  return List.generate(6, (i) {
    final month = _calculateMonthBack(now, 5 - i);
    return FinancialHealthScoreTrend(
      groupId: groupId,
      month: '${month.year}-${month.month.toString().padLeft(2, '0')}',
      overallScore: 65 + (i * 2),
      categoryScores: {
        'savingsRatio': 65 + (i * 2),
        'budgetAdherence': 70 + (i * 2),
        'expenseControl': 65 + (i * 2),
        'investmentEngagement': 60 + (i * 2),
        'socialImpact': 55 + (i * 2),
      },
    );
  });
});

/// 貯蓄目標進捗プロバイダー
final savingsGoalProgressProvider = FutureProvider.autoDispose
    .family<({int currentSavings, int monthlyGoal, double progressPercent, int remainingToGoal}), String>((ref, groupId) async {
  const monthlyGoal = 30000;
  const currentSavings = 15000;
  final progressPercent = (currentSavings / monthlyGoal * 100).clamp(0.0, 100.0);
  final remainingToGoal = (monthlyGoal - currentSavings).clamp(0, monthlyGoal);
  return (currentSavings: currentSavings, monthlyGoal: monthlyGoal, progressPercent: progressPercent, remainingToGoal: remainingToGoal);
});

/// スコア改善ガイドプロバイダー
final scoreImprovementGuideProvider = FutureProvider.autoDispose
    .family<List<ScoreImprovementAction>, String>((ref, groupId) async {
  return [
    ScoreImprovementAction(category: 'savingsRatio', displayName: 'Savings Ratio', priority: 1, currentScore: 65, targetScore: 85, actionItems: ['Reduce spending by 5%', 'Review fixed expenses']),
    ScoreImprovementAction(category: 'budgetAdherence', displayName: 'Budget Adherence', priority: 2, currentScore: 70, targetScore: 85, actionItems: ['Track monthly expenses', 'Adjust budget allocations']),
  ];
});

/// 財務健全性改善推奨プロバイダー
final financialHealthRecommendationsProvider = FutureProvider.autoDispose
    .family<List<HealthScoreRecommendation>, String>((ref, groupId) async {
  return [
    HealthScoreRecommendation(
      id: 'rec_1',
      title: 'Improve Savings Ratio',
      description: 'Increase your monthly savings by reducing expenses or increasing income.',
      category: 'savingsRatio',
      potentialScoreGain: 20,
      priority: 'high',
      actionType: 'saving',
    ),
    HealthScoreRecommendation(
      id: 'rec_2',
      title: 'Better Budget Adherence',
      description: 'Track your spending more closely and adjust budget allocations monthly.',
      category: 'budgetAdherence',
      potentialScoreGain: 15,
      priority: 'medium',
      actionType: 'budget',
    ),
  ];
});

/// 月間貯蓄率トレンドプロバイダー
final monthlySavingsRateTrendProvider = FutureProvider.autoDispose
    .family<List<MonthlySavingsRateTrend>, String>((ref, groupId) async {
  final now = DateTime.now();
  return List.generate(6, (i) {
    final month = _calculateMonthBack(now, 5 - i);
    return MonthlySavingsRateTrend(month: '${month.year}-${month.month.toString().padLeft(2, '0')}', savingsRatioScore: 65 + (i * 2), isCurrentMonth: i == 0, trend: i == 0 ? '↑' : (i % 2 == 0 ? '→' : '↑'));
  });
});

/// 予算最適化プロバイダー
final budgetOptimizationProvider = FutureProvider.autoDispose
    .family<List<BudgetOptimization>, String>((ref, groupId) async {
  return [
    BudgetOptimization(category: 'food', displayName: 'Food', currentBudget: 60000, actualSpent: 80000, recommendedBudget: 88000, recommendation: 'Spending exceeds budget by 33%', priority: 1),
    BudgetOptimization(category: 'transportation', displayName: 'Transportation', currentBudget: 30000, actualSpent: 25000, recommendedBudget: 25000, recommendation: 'Well within budget', priority: 2),
  ];
});

// Model classes
class ScoreImprovementAction {
  final String category, displayName;
  final int priority, currentScore, targetScore;
  final List<String> actionItems;
  ScoreImprovementAction({required this.category, required this.displayName, required this.priority, required this.currentScore, required this.targetScore, required this.actionItems});
  int get scoreGain => targetScore - currentScore;
}

class MonthlySavingsRateTrend {
  final String month, trend;
  final int savingsRatioScore;
  final bool isCurrentMonth;
  MonthlySavingsRateTrend({required this.month, required this.savingsRatioScore, required this.isCurrentMonth, required this.trend});
}

class BudgetOptimization {
  final String category, displayName, recommendation;
  final int currentBudget, actualSpent, recommendedBudget, priority;
  BudgetOptimization({required this.category, required this.displayName, required this.currentBudget, required this.actualSpent, required this.recommendedBudget, required this.recommendation, required this.priority});
  int get budgetDifference => recommendedBudget - currentBudget;
  double get utilizationRate => actualSpent / currentBudget;
}
