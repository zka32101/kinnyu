import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents the impact a goal achievement has on financial health score
class GoalScoreImpact {
  final String goalId;
  final String goalName;
  final String description;
  final int currentScore;
  final int projectedScore;
  final int scoreGain;
  final String affectedCategory; // Which score component benefits
  final String emoji;

  GoalScoreImpact({
    required this.goalId,
    required this.goalName,
    required this.description,
    required this.currentScore,
    required this.projectedScore,
    required this.affectedCategory,
    required this.emoji,
  }) : scoreGain = projectedScore - currentScore;

  double get percentageGain => currentScore > 0 ? (scoreGain / currentScore * 100) : 0;
}

/// Provider showing potential score impacts of achievable goals
/// ENHANCEMENT: Connects Goals/Missions system with Financial Health Score
/// Shows users how specific goals contribute to their financial health
final goalScoreImpactProvider = FutureProvider.autoDispose
    .family<List<GoalScoreImpact>, String>((ref, groupId) async {
  // Mock data demonstrating the concept
  // In production: would fetch actual missions/goals and calculate impacts

  const currentOverallScore = 70;

  return [
    GoalScoreImpact(
      goalId: 'goal_monthly_savings',
      goalName: '月間貯蓄目標達成',
      description: '月間25,000円の貯蓄目標を達成することで、貯蓄率スコアが向上',
      currentScore: currentOverallScore,
      projectedScore: 75,
      affectedCategory: 'savingsRatio',
      emoji: '💰',
    ),
    GoalScoreImpact(
      goalId: 'goal_budget_adherence',
      goalName: '予算遵守率100%',
      description: '1ヶ月間、すべてのカテゴリで予算内に収まることで、予算遵守スコアが向上',
      currentScore: currentOverallScore,
      projectedScore: 78,
      affectedCategory: 'budgetAdherence',
      emoji: '📊',
    ),
    GoalScoreImpact(
      goalId: 'goal_start_investing',
      goalName: '投資を始める',
      description: '50,000円以上の投資を開始することで、投資参加度スコアが大幅に向上',
      currentScore: currentOverallScore,
      projectedScore: 80,
      affectedCategory: 'investmentEngagement',
      emoji: '📈',
    ),
    GoalScoreImpact(
      goalId: 'goal_social_contribution',
      goalName: '社会貢献活動',
      description: '10,000円以上の寄付を行うことで、社会貢献度スコアが向上',
      currentScore: currentOverallScore,
      projectedScore: 73,
      affectedCategory: 'socialImpact',
      emoji: '🤝',
    ),
  ];
});

/// Provider showing most impactful goals (sorted by potential score gain)
final topImpactGoalsProvider = FutureProvider.autoDispose
    .family<List<GoalScoreImpact>, String>((ref, groupId) async {
  final impacts = await ref.watch(goalScoreImpactProvider(groupId).future);
  final sorted = List<GoalScoreImpact>.from(impacts);
  sorted.sort((a, b) => b.scoreGain.compareTo(a.scoreGain));
  return sorted.take(3).toList(); // Top 3 most impactful goals
});

/// Provider for scenario analysis: show score if specific goal achieved
final projectedScoreWithGoalProvider = FutureProvider.autoDispose
    .family<int, (String, String)>((ref, params) async {
  final (groupId, goalId) = params;

  final impacts = await ref.watch(goalScoreImpactProvider(groupId).future);
  final matchingGoal = impacts.firstWhere(
    (goal) => goal.goalId == goalId,
    orElse: () => impacts.first,
  );

  return matchingGoal.projectedScore;
});
