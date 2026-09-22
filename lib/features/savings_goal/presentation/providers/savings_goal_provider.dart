import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/savings_goal_service.dart';
import '../../domain/models/savings_goal.dart';

final savingsGoalServiceProvider = Provider((ref) {
  return SavingsGoalService();
});

// autoDispose: このプロバイダーが監視されなくなったら Firestore の
// ストリーム購読を確実に解除し、リークを防ぐ。
final savingsGoalsStreamProvider =
    StreamProvider.autoDispose.family<List<SavingsGoal>, String>((ref, uid) {
  final service = ref.watch(savingsGoalServiceProvider);
  return service.watchGoals(uid);
});

/// 達成済みの貯金目標数（実績・バッジ機能から利用）
final achievedSavingsGoalsCountProvider =
    FutureProvider.autoDispose.family<int, String>((ref, uid) async {
  final service = ref.watch(savingsGoalServiceProvider);
  return service.getAchievedGoalsCount(uid);
});
