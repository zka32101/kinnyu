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
import '../../../core/services/notification_service.dart';
import '../../../features/investment/presentation/providers/investment_provider.dart';

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

/// 投資額プロバイダー - Aggregate real investment values from all household members
final investmentAmountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, groupId) async {
  try {
    // Get household group to find all members
    final groupAsync = ref.watch(groupStreamProvider(groupId));
    final group = await groupAsync.future;

    if (group == null || group.members.isEmpty) {
      return 0;
    }

    // Aggregate investments from all members
    int totalInvestment = 0;
    for (final member in group.members) {
      try {
        final investmentsAsync = ref.watch(activeInvestmentsProvider(member.uid));
        final investments = await investmentsAsync.future;
        if (investments != null) {
          for (final investment in investments) {
            totalInvestment += investment.savingsAmount;
          }
        }
      } catch (_) {
        // Continue if one member's data fails
        continue;
      }
    }

    return totalInvestment;
  } catch (e) {
    return 0;
  }
}).keepAlive();

/// 社会貢献額プロバイダー - Fetch real donation/contribution data
final socialContributionAmountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, groupId) async {
  try {
    // Get real contribution data from social contribution service
    final service = ref.watch(socialContributionServiceProvider);
    final totalDonations = await service.getTotalDonations(groupId);
    return totalDonations;
  } catch (e) {
    // Fallback to 0 if service unavailable
    return 0;
  }
}).keepAlive();

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
}).keepAlive();

/// スコア詳細プロバイダー
final financialHealthScoreDetailProvider = FutureProvider.autoDispose
    .family<FinancialHealthScoreDetail?, String>((ref, groupId) async {
  // Placeholder: Return null for now - full implementation deferred
  return null;
}).keepAlive();

/// スコアトレンドプロバイダー
final financialHealthScoreTrendProvider = FutureProvider.autoDispose
    .family<List<FinancialHealthScoreTrend>, String>((ref, groupId) async {
  final now = DateTime.now();
  return List.generate(6, (i) {
    final month = DateTime(now.year, now.month - (5 - i), 1);
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
}).keepAlive();

/// 貯蓄目標進捗プロバイダー
final savingsGoalProgressProvider = FutureProvider.autoDispose
    .family<({int currentSavings, int monthlyGoal, double progressPercent, int remainingToGoal}), String>((ref, groupId) async {
  const monthlyGoal = 30000;
  const currentSavings = 15000;
  final progressPercent = (currentSavings / monthlyGoal * 100).clamp(0.0, 100.0);
  final remainingToGoal = (monthlyGoal - currentSavings).clamp(0, monthlyGoal);
  return (currentSavings: currentSavings, monthlyGoal: monthlyGoal, progressPercent: progressPercent, remainingToGoal: remainingToGoal);
}).keepAlive();

/// スコア改善ガイドプロバイダー
final scoreImprovementGuideProvider = FutureProvider.autoDispose
    .family<List<ScoreImprovementAction>, String>((ref, groupId) async {
  return [
    ScoreImprovementAction(category: 'savingsRatio', displayName: 'Savings Ratio', priority: 1, currentScore: 65, targetScore: 85, actionItems: ['Reduce spending by 5%', 'Review fixed expenses']),
    ScoreImprovementAction(category: 'budgetAdherence', displayName: 'Budget Adherence', priority: 2, currentScore: 70, targetScore: 85, actionItems: ['Track monthly expenses', 'Adjust budget allocations']),
  ];
}).keepAlive();

/// 財務健全性スコアの変化を監視し、マイルストーン達成と改善をお知らせする
final financialHealthNotificationProvider = FutureProvider.autoDispose
    .family<void, String>((ref, groupId) async {
  try {
    // 現在のスコアを監視
    final scoreAsync = ref.watch(financialHealthScoreProvider(groupId));
    final currentScore = await scoreAsync.future;

    // 前月のスコアを監視（トレンドプロバイダーから取得）
    final trendsAsync = ref.watch(financialHealthScoreTrendProvider(groupId));
    final trends = await trendsAsync.future;

    // スコアが有効な場合、通知を送信する
    if (currentScore.overallScore > 0 && trends.isNotEmpty) {
      final notificationService = NotificationService();

      // マイルストーン達成の通知
      notificationService.showScoreMilestoneNotification(currentScore.overallScore);

      // 月単位での改善を検出して通知
      if (trends.length >= 2) {
        final previousMonthScore = trends[trends.length - 2].overallScore;
        if (currentScore.overallScore > previousMonthScore) {
          notificationService.showScoreImprovementNotification(
            previousScore: previousMonthScore,
            currentScore: currentScore.overallScore,
            category: '総合スコア',
          );
        }
      }
    }
  } catch (e) {
    // 通知送信の失敗はアプリの動作に影響しないようにする
  }
}).keepAlive();

/// 月間貯蓄率トレンドプロバイダー
final monthlySavingsRateTrendProvider = FutureProvider.autoDispose
    .family<List<MonthlySavingsRateTrend>, String>((ref, groupId) async {
  final now = DateTime.now();
  return List.generate(6, (i) {
    final month = DateTime(now.year, now.month - (5 - i), 1);
    return MonthlySavingsRateTrend(month: '${month.year}-${month.month.toString().padLeft(2, '0')}', savingsRatioScore: 65 + (i * 2), isCurrentMonth: i == 0, trend: i == 0 ? '↑' : (i % 2 == 0 ? '→' : '↑'));
  });
}).keepAlive();

/// 予算最適化プロバイダー
final budgetOptimizationProvider = FutureProvider.autoDispose
    .family<List<BudgetOptimization>, String>((ref, groupId) async {
  return [
    BudgetOptimization(category: 'food', displayName: 'Food', currentBudget: 60000, actualSpent: 80000, recommendedBudget: 88000, recommendation: 'Spending exceeds budget by 33%', priority: 1),
    BudgetOptimization(category: 'transportation', displayName: 'Transportation', currentBudget: 30000, actualSpent: 25000, recommendedBudget: 25000, recommendation: 'Well within budget', priority: 2),
  ];
}).keepAlive();

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
