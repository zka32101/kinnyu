import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/financial_health_score.dart';
import './financial_health_provider.dart';
import '../../../core/services/notification_service.dart';

/// Goal achievement impact on financial health score
class GoalScoreImpact {
  final String goalName;
  final String description;
  final int currentScore;
  final int projectedScore;
  final int scoreGain;
  final String affectedCategory;
  final double confidenceLevel; // 0.0-1.0

  GoalScoreImpact({
    required this.goalName,
    required this.description,
    required this.currentScore,
    required this.projectedScore,
    required this.scoreGain,
    required this.affectedCategory,
    required this.confidenceLevel,
  });

  int get percentImprovement => ((scoreGain / currentScore) * 100).toInt();
}

/// Calculate projected score improvement from achieving savings goal
final savingsGoalScoreImpactProvider = FutureProvider.autoDispose
    .family<GoalScoreImpact?, String>((ref, groupId) async {
  try {
    // Get current financial health score
    final scoreAsync = ref.watch(financialHealthScoreProvider(groupId));
    final currentScore = await scoreAsync.future;

    // Get current savings goal progress
    final progressAsync =
        ref.watch(savingsGoalProgressProvider(groupId));
    final progress = await progressAsync.future;

    if (progress.progressPercent >= 100.0) {
      // Goal already achieved
      return GoalScoreImpact(
        goalName: 'Monthly Savings Goal',
        description: 'Achieve monthly savings target of ¥${progress.monthlyGoal}',
        currentScore: currentScore.overallScore,
        projectedScore: currentScore.overallScore,
        scoreGain: 0,
        affectedCategory: 'savingsRatio',
        confidenceLevel: 1.0,
      );
    }

    // Calculate projected improvement
    // Estimate: 5-10 points per complete savings goal achievement
    final projectedGain = ((100.0 - progress.progressPercent) / 100.0 * 10).toInt();
    final projectedScore =
        (currentScore.overallScore + projectedGain).clamp(0, 100);

    return GoalScoreImpact(
      goalName: 'Monthly Savings Goal',
      description:
          'Achieve monthly savings target of ¥${progress.monthlyGoal} (currently ¥${progress.currentSavings})',
      currentScore: currentScore.overallScore,
      projectedScore: projectedScore,
      scoreGain: projectedGain,
      affectedCategory: 'savingsRatio',
      confidenceLevel: 0.85, // Good confidence for savings goal prediction
    );
  } catch (e) {
    return null;
  }
}).keepAlive();

/// All household goals and their score impacts
final allGoalScoreImpactsProvider = FutureProvider.autoDispose
    .family<List<GoalScoreImpact>, String>((ref, groupId) async {
  try {
    final impacts = <GoalScoreImpact>[];

    // Get savings goal impact
    final savingsImpactAsync =
        ref.watch(savingsGoalScoreImpactProvider(groupId));
    final savingsImpact = await savingsImpactAsync.future;
    if (savingsImpact != null) {
      impacts.add(savingsImpact);
    }

    // TODO: Add more goal types as goal management system expands:
    // - Investment participation goals
    // - Budget adherence goals
    // - Social contribution goals
    // - Expense control goals

    return impacts;
  } catch (e) {
    return [];
  }
}).keepAlive();

/// ゴール達成がスコアに与える影響を通知する
final goalAchievementNotificationProvider = FutureProvider.autoDispose
    .family<void, String>((ref, groupId) async {
  try {
    // すべてのゴールの影響を監視
    final impactsAsync = ref.watch(allGoalScoreImpactsProvider(groupId));
    final impacts = await impactsAsync.future;

    // 各ゴールについて通知を送信
    for (final impact in impacts) {
      if (impact.scoreGain > 0) {
        final notificationService = NotificationService();
        notificationService.showGoalAchievementImpactNotification(
          goalName: impact.goalName,
          scoreGain: impact.scoreGain,
          projectedScore: impact.projectedScore,
        );
      }
    }
  } catch (e) {
    // 通知送信の失敗はアプリの動作に影響しないようにする
  }
}).keepAlive();
