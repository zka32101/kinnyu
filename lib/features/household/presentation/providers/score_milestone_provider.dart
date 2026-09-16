import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import './financial_health_provider.dart';

/// Provider that monitors financial health score changes and triggers milestone notifications
/// ENHANCEMENT: Detects when score crosses milestone thresholds (70, 75, 80, 85, 90)
/// and sends celebratory notifications to motivate users
class ScoreMilestoneNotifier extends StateNotifier<int?> {
  final NotificationService _notificationService;

  ScoreMilestoneNotifier(this._notificationService) : super(null);

  /// Check if current score crosses a milestone and send notification if needed
  Future<void> checkAndNotifyMilestone(int newScore, {int? previousScore}) async {
    final milestones = [70, 75, 80, 85, 90];

    // Only notify if score is exactly at a milestone
    if (milestones.contains(newScore)) {
      // Only notify if score improved (not on first load)
      if (previousScore != null && newScore > previousScore) {
        await _notificationService.showScoreMilestoneNotification(newScore);
        state = newScore;
      } else if (previousScore == null) {
        // First load - don't notify, just record state
        state = newScore;
      }
    }
  }

  /// Report improvement action and notify user
  Future<void> reportImprovementAction({
    required String actionType,
    required String category,
    required int estimatedScoreGain,
  }) async {
    await _notificationService.showImprovementActionNotification(
      actionType: actionType,
      category: category,
      estimatedScoreGain: estimatedScoreGain,
    );
  }

  /// Report monthly goal achievement
  Future<void> reportMonthlyGoalAchieved({
    required String goalName,
    required int currentScore,
    required int previousScore,
  }) async {
    await _notificationService.showMonthlyGoalAchievedNotification(
      goalName: goalName,
      currentScore: currentScore,
      previousScore: previousScore,
    );
  }
}

/// Notification service provider
final notificationServiceProvider = Provider((ref) {
  return NotificationService();
});

/// Score milestone notifier - tracks score changes and triggers notifications
final scoreMilestoneProvider = StateNotifierProvider<ScoreMilestoneNotifier, int?>(
  (ref) {
    final notificationService = ref.watch(notificationServiceProvider);
    return ScoreMilestoneNotifier(notificationService);
  },
);

/// Provider that watches score changes and automatically notifies on milestones
/// Usage: watch this in a widget that displays the financial health score
final scoreChangeNotifierProvider = FutureProvider.autoDispose
    .family<void, String>((ref, groupId) async {
  final score = await ref.watch(
    financialHealthScoreProvider(groupId).future,
  );
  final milestone = ref.watch(scoreMilestoneProvider);

  // Notify if score changed and crossed a milestone
  await ref.read(scoreMilestoneProvider.notifier)
      .checkAndNotifyMilestone(score.overallScore, previousScore: milestone);
});
