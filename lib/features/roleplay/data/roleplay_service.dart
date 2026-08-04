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
          .get();

      return snapshot.docs
          .map((doc) => RoleplayResult.fromJson(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
