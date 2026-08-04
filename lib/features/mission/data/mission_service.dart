import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/mission.dart';

class MissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userMissionsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('missions');
  }

  Future<List<Mission>> getActiveMissions(String uid) async {
    try {
      final snapshot = await _userMissionsRef(uid)
          .where('status', isEqualTo: MissionStatus.pending.index)
          .get();

      if (snapshot.docs.isEmpty) {
        return _seedWeeklyMissions(uid);
      }

      return snapshot.docs
          .map((doc) => Mission.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch missions: $e');
    }
  }

  Future<List<Mission>> _seedWeeklyMissions(String uid) async {
    final missions = MissionTemplates.generateWeeklyMissions();
    for (final mission in missions) {
      await _userMissionsRef(uid).doc(mission.id).set(mission.toJson());
    }
    return missions;
  }

  Future<void> completeMission(String uid, String missionId) async {
    try {
      await _userMissionsRef(uid).doc(missionId).update({
        'status': MissionStatus.completed.index,
        'completedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to complete mission: $e');
    }
  }

  Stream<List<Mission>> watchActiveMissions(String uid) {
    return _userMissionsRef(uid)
        .where('status', isEqualTo: MissionStatus.pending.index)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Mission.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
}
