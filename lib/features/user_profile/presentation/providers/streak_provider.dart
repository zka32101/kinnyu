import 'package:riverpod/riverpod.dart';
import '../data/streak_service.dart';

final streakServiceProvider = Provider((ref) {
  return StreakService();
});

final streakProvider = FutureProvider.family<StreakData, String>((ref, uid) async {
  final streakService = ref.watch(streakServiceProvider);
  return streakService.getStreak(uid);
});

final streakStreamProvider =
    StreamProvider.family<StreakData, String>((ref, uid) {
  final streakService = ref.watch(streakServiceProvider);
  return streakService.getStreakStream(uid);
});
