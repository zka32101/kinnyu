import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';
import '../../data/mission_service.dart';
import '../../domain/models/mission.dart';

final missionServiceProvider = Provider((ref) {
  return MissionService();
});

final activeMissionsProvider =
    FutureProvider.family<List<Mission>, String>((ref, uid) async {
  final service = ref.watch(missionServiceProvider);
  return service.getActiveMissions(uid);
});

// autoDispose: このプロバイダーが監視されなくなったら Firestore の
// ストリーム購読を確実に解除し、リークを防ぐ。
final missionsStreamProvider =
    StreamProvider.autoDispose.family<List<Mission>, String>((ref, uid) {
  final service = ref.watch(missionServiceProvider);
  // 今週のミッションを用意する（無ければ作成・期限切れは更新）。
  // 失敗しても一覧の購読は続ける。作成後はストリームが自動で更新される。
  service.ensureWeeklyMissions(uid).catchError((Object e) {
    debugPrint('ensureWeeklyMissions failed: $e');
  });
  return service.watchActiveMissions(uid);
});
