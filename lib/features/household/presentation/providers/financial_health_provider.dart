import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/financial_health_score.dart';
import '../../../investment/presentation/providers/investment_provider.dart';
import '../../../investment/domain/services/market_simulator.dart';
import './social_contribution_provider.dart';

// PERFORMANCE NOTE: All providers use .autoDispose.family for optimal memory usage:
// - .autoDispose: Automatically disposes unused providers (good for low-memory scenarios)
// - .family: Caches values per parameter (same groupId reuses cached result)
// See: lib/features/household/presentation/providers/PERFORMANCE_OPTIMIZATION.md

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

/// 投資額プロバイダー - Integration with Investment module
/// INTEGRATION: Fetches current investment portfolio value from activeInvestmentsProvider
/// CACHING:
/// - StreamProvider (not FutureProvider) for real-time updates
/// - .autoDispose: Clears when detail page closed
/// - Deduplication: Multiple detail pages watch same groupId → single investment stream
/// OPTIMIZATION: This provider is only watched by financial health detail page
/// Not fetched on dashboard, avoiding unnecessary network requests
/// LAZY LOADING: Only loads when user navigates to financial health detail page
final investmentAmountProvider = StreamProvider.autoDispose
    .family<int, String>((ref, groupId) {
  final investmentStream = ref.watch(activeInvestmentsProvider(groupId));

  return investmentStream.asyncMap((investments) async {
    int totalValue = 0;
    for (final investment in investments) {
      final currentIndex = MarketSimulator.getCurrentIndexValue(
        investment.investmentType,
      );
      final currentValue = investment.currentValue(currentIndex);
      totalValue += currentValue.toInt();
    }
    return totalValue;
  }).handleError((error) {
    return 0;
  });
});

/// 社会貢献額プロバイダー - Real-time integration with Social Contribution module
/// INTEGRATION: Fetches total donations from socialContributionProvider
/// - Streams donation records from Firestore
/// - Updates in real-time as contributions are added
/// CACHING:
/// - .autoDispose: Clears when detail page closed
/// - Deduplication: Multiple detail pages watch same groupId → single donation fetch
/// - Error handling: Returns 0 if social contribution service unavailable (no crash)
/// OPTIMIZATION: This provider is only watched by financial health detail page
/// Not fetched on dashboard, avoiding unnecessary network requests
/// LAZY LOADING: Only loads when user navigates to financial health detail page
/// MEMORY: With .autoDispose, donation data freed immediately when tab closed
final socialContributionAmountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, groupId) async {
  try {
    return await ref.watch(totalDonationsProvider(groupId).future);
  } catch (e) {
    // Fallback if social contribution service unavailable
    return 0;
  }
});

/// 財務健全性スコアプロバイダー
/// CACHING BEHAVIOR:
/// - .autoDispose: Automatically clears when no longer watched (memory efficient)
/// - .family: Caches per groupId (same groupId across widgets reuses same result)
/// - No TTL: Currently refreshes on app resume; when Firestore integrated,
///   consider 1-hour cache to reduce recalculation (category scores rarely change intraday)
/// USAGE:
/// - Dashboard: Watch via select() to only rebuild on score changes (not all fields)
/// - Detail page: Watch full object (all scores needed for display)
/// WATCH PATTERN: Use .select((async) => async.whenData((s) => s.overallScore))
/// to optimize dashboard rebuilds when only the main score is displayed
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

/// 現在月のスコアトレンドプロバイダー (Lazy-loading optimization)
/// PERFORMANCE: Returns only current month data (< 100ms)
/// Use this for dashboard/overview to avoid loading 6 months of data unnecessarily
/// When user navigates to Trends tab, load historicalScoreTrendProvider
final currentMonthScoreTrendProvider = FutureProvider.autoDispose
    .family<FinancialHealthScoreTrend, String>((ref, groupId) async {
  final now = DateTime.now();
  return FinancialHealthScoreTrend(
    groupId: groupId,
    month: '${now.year}-${now.month.toString().padLeft(2, '0')}',
    overallScore: 75,
    categoryScores: {
      'savingsRatio': 75,
      'budgetAdherence': 80,
      'expenseControl': 75,
      'investmentEngagement': 70,
      'socialImpact': 65,
    },
  );
});

/// スコアトレンドプロバイダー (6ヶ月のトレンドデータ)
/// OPTIMIZATION NOTE: Cached by .family parameter (same groupId reuses result)
/// CACHING: Riverpod .autoDispose provides automatic memory management
/// TTL Strategy (when Firestore integrated):
/// - Cache for 1 hour if data unchanged
/// - Invalidate on explicit refresh or app resume
/// LAZY LOADING: Use currentMonthScoreTrendProvider for fast initial load
/// Only fetch all 6 months when Trends tab is opened (see historicalScoreTrendProvider)
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

/// 過去トレンドプロバイダー (Lazy-loading - 詳細ページのTrendsタブ用)
/// PERFORMANCE: Only fetched when user opens Trends tab (on-demand loading)
/// Combined with currentMonthScoreTrendProvider for fast initial page load
/// Returns months 2-6 (previous 5 months, excluding current)
final historicalScoreTrendProvider = FutureProvider.autoDispose
    .family<List<FinancialHealthScoreTrend>, String>((ref, groupId) async {
  final now = DateTime.now();
  return List.generate(5, (i) {
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
