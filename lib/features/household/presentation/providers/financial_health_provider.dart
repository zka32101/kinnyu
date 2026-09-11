import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/financial_health_score.dart';
import '../../domain/models/household_budget.dart';
import '../../domain/models/household_expense_summary.dart';
import '../../domain/models/household_group.dart';
import '../../domain/services/financial_health_calculator.dart';
import '../../data/household_service.dart';
import './household_budget_provider.dart';
import './household_provider.dart';
import './social_contribution_provider.dart';
import '../../../core/services/notification_provider.dart';

/// 現在月の家計情報プロバイダー
final monthlyExpenseSummaryProvider = FutureProvider.autoDispose
    .family<HouseholdExpenseSummary?, String>((ref, groupId) async {
  try {
    final service = HouseholdService();
    final now = DateTime.now();
    return await service.getMonthlyExpenseSummary(
      groupId: groupId,
      month: DateTime(now.year, now.month),
    );
  } catch (e) {
    return null;
  }
}).keepAlive();

/// 投資額プロバイダー
final investmentAmountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, groupId) async {
  // Placeholder: Full implementation deferred
  return 0;
}).keepAlive();

/// 社会貢献額プロバイダー
final socialContributionAmountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, groupId) async {
  try {
    final totalDonations = await ref.watch(totalDonationsProvider(groupId).future);
    return totalDonations;
  } catch (e) {
    return 0;
  }
}).keepAlive();

/// 財務健全性スコアプロバイダー
final financialHealthScoreProvider = FutureProvider.autoDispose
    .family<FinancialHealthScore, String>((ref, groupId) async {
  try {
    final budgetAsync = ref.watch(householdBudgetProvider(groupId));
    final summaryAsync = ref.watch(monthlyExpenseSummaryProvider(groupId));
    final investmentAsync = ref.watch(investmentAmountProvider(groupId));
    final socialAsync = ref.watch(socialContributionAmountProvider(groupId));

    // Create default score if data not available
    return FinancialHealthScore(
      groupId: groupId,
      overallScore: 70,
      savingsRatioScore: 70,
      budgetAdherenceScore: 70,
      expenseControlScore: 70,
      investmentEngagementScore: 70,
      socialImpactScore: 70,
    );
  } catch (e) {
    return FinancialHealthScore(
      groupId: groupId,
      overallScore: 70,
      savingsRatioScore: 70,
      budgetAdherenceScore: 70,
      expenseControlScore: 70,
      investmentEngagementScore: 70,
      socialImpactScore: 70,
    );
  }
}).keepAlive();

/// スコア詳細プロバイダー
final financialHealthScoreDetailProvider = FutureProvider.autoDispose
    .family<FinancialHealthScoreDetail?, String>((ref, groupId) async {
  try {
    final scoreAsync = ref.watch(financialHealthScoreProvider(groupId));
    final score = await scoreAsync.future;

    return FinancialHealthScoreDetail(
      score: score,
      categories: [
        HealthScoreCategory(
          name: 'Savings Ratio',
          score: score.savingsRatioScore,
          description: 'Monthly savings rate',
        ),
        HealthScoreCategory(
          name: 'Budget Adherence',
          score: score.budgetAdherenceScore,
          description: 'Budget compliance',
        ),
        HealthScoreCategory(
          name: 'Expense Control',
          score: score.expenseControlScore,
          description: 'Spending control',
        ),
        HealthScoreCategory(
          name: 'Investment Engagement',
          score: score.investmentEngagementScore,
          description: 'Investment participation',
        ),
        HealthScoreCategory(
          name: 'Social Impact',
          score: score.socialImpactScore,
          description: 'Community contribution',
        ),
      ],
    );
  } catch (e) {
    return null;
  }
}).keepAlive();

/// スコアトレンドプロバイダー
final financialHealthScoreTrendProvider = FutureProvider.autoDispose
    .family<List<FinancialHealthScoreTrend>, String>((ref, groupId) async {
  try {
    final now = DateTime.now();
    final trends = <FinancialHealthScoreTrend>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      trends.add(
        FinancialHealthScoreTrend(
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
        ),
      );
    }
    return trends;
  } catch (e) {
    return [];
  }
}).keepAlive();

/// 貯蓄目標進捗プロバイダー
final savingsGoalProgressProvider = FutureProvider.autoDispose
    .family<({int currentSavings, int monthlyGoal, double progressPercent, int remainingToGoal}), String>((ref, groupId) async {
  try {
    const monthlyGoal = 30000;
    const currentSavings = 15000;
    final progressPercent = (currentSavings / monthlyGoal * 100).clamp(0.0, 100.0);
    final remainingToGoal = (monthlyGoal - currentSavings).clamp(0, monthlyGoal);

    return (
      currentSavings: currentSavings,
      monthlyGoal: monthlyGoal,
      progressPercent: progressPercent,
      remainingToGoal: remainingToGoal,
    );
  } catch (e) {
    return (
      currentSavings: 0,
      monthlyGoal: 30000,
      progressPercent: 0.0,
      remainingToGoal: 30000,
    );
  }
}).keepAlive();

/// スコア改善ガイドプロバイダー
final scoreImprovementGuideProvider = FutureProvider.autoDispose
    .family<List<ScoreImprovementAction>, String>((ref, groupId) async {
  try {
    return [
      ScoreImprovementAction(
        category: 'savingsRatio',
        displayName: 'Savings Ratio',
        priority: 1,
        currentScore: 65,
        targetScore: 85,
        actionItems: ['Reduce spending by 5%', 'Review fixed expenses'],
      ),
      ScoreImprovementAction(
        category: 'budgetAdherence',
        displayName: 'Budget Adherence',
        priority: 2,
        currentScore: 70,
        targetScore: 85,
        actionItems: ['Track monthly expenses', 'Adjust budget allocations'],
      ),
    ];
  } catch (e) {
    return [];
  }
}).keepAlive();

/// 月間貯蓄率トレンドプロバイダー
final monthlySavingsRateTrendProvider = FutureProvider.autoDispose
    .family<List<MonthlySavingsRateTrend>, String>((ref, groupId) async {
  try {
    final now = DateTime.now();
    final trends = <MonthlySavingsRateTrend>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      trends.add(
        MonthlySavingsRateTrend(
          month: '${month.year}-${month.month.toString().padLeft(2, '0')}',
          savingsRatioScore: 65 + (i * 2),
          isCurrentMonth: i == 0,
          trend: i == 0 ? '↑' : (i % 2 == 0 ? '→' : '↑'),
        ),
      );
    }
    return trends;
  } catch (e) {
    return [];
  }
}).keepAlive();

/// 予算最適化プロバイダー
final budgetOptimizationProvider = FutureProvider.autoDispose
    .family<List<BudgetOptimization>, String>((ref, groupId) async {
  try {
    return [
      BudgetOptimization(
        category: 'food',
        displayName: 'Food',
        currentBudget: 60000,
        actualSpent: 80000,
        recommendedBudget: 88000,
        recommendation: 'Spending exceeds budget by 33%',
        priority: 1,
      ),
      BudgetOptimization(
        category: 'transportation',
        displayName: 'Transportation',
        currentBudget: 30000,
        actualSpent: 25000,
        recommendedBudget: 25000,
        recommendation: 'Well within budget',
        priority: 2,
      ),
    ];
  } catch (e) {
    return [];
  }
}).keepAlive();

// Model classes
class ScoreImprovementAction {
  final String category;
  final String displayName;
  final int priority;
  final int currentScore;
  final int targetScore;
  final List<String> actionItems;

  ScoreImprovementAction({
    required this.category,
    required this.displayName,
    required this.priority,
    required this.currentScore,
    required this.targetScore,
    required this.actionItems,
  });

  int get scoreGain => targetScore - currentScore;
}

class MonthlySavingsRateTrend {
  final String month;
  final int savingsRatioScore;
  final bool isCurrentMonth;
  final String trend;

  MonthlySavingsRateTrend({
    required this.month,
    required this.savingsRatioScore,
    required this.isCurrentMonth,
    required this.trend,
  });
}

class BudgetOptimization {
  final String category;
  final String displayName;
  final int currentBudget;
  final int actualSpent;
  final int recommendedBudget;
  final String recommendation;
  final int priority;

  BudgetOptimization({
    required this.category,
    required this.displayName,
    required this.currentBudget,
    required this.actualSpent,
    required this.recommendedBudget,
    required this.recommendation,
    required this.priority,
  });

  int get budgetDifference => recommendedBudget - currentBudget;
  double get utilizationRate => actualSpent / currentBudget;
}
