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

final missionsStreamProvider =
    StreamProvider.family<List<Mission>, String>((ref, uid) {
  final service = ref.watch(missionServiceProvider);
  return service.watchActiveMissions(uid);
});
