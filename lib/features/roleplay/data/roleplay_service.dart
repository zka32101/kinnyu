import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/roleplay_scenario.dart';

class RoleplayService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveResult(String uid, RoleplayResult result) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('roleplay_results')
          .add(result.toJson());
    } catch (e) {
      throw Exception('Failed to save roleplay result: $e');
    }
  }

  Future<List<RoleplayResult>> getResults(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('roleplay_results')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      // NOTE: merges doc.id into the map to match the pattern used by
      // sibling services (e.g. Investment/Mission/Challenge fromJson).
      // RoleplayResult does not yet expose an `id` property, so fromJson
      // currently ignores the extra key — add an `id` field to the model
      // if/when callers need to reference a specific result document.
      return snapshot.docs
          .map((doc) => RoleplayResult.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
