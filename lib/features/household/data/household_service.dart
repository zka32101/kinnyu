import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/household_group.dart';

class HouseholdService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _groupsRef =>
      _firestore.collection('household_groups');

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<HouseholdGroup> createGroup({
    required String uid,
    required String name,
    int monthlyGoal = 30000,
  }) async {
    final inviteCode = _generateInviteCode();
    final now = DateTime.now();

    final group = HouseholdGroup(
      id: inviteCode,
      name: name,
      members: [uid],
      totalSavings: 0,
      monthlyGoal: monthlyGoal,
      createdAt: now,
    );

    await _groupsRef.doc(inviteCode).set(group.toJson());
    await _firestore.collection('users').doc(uid).update({
      'householdGroupId': inviteCode,
    });

    return group;
  }

  Future<HouseholdGroup?> joinGroup({
    required String uid,
    required String inviteCode,
  }) async {
    try {
      final doc = await _groupsRef.doc(inviteCode.toUpperCase()).get();
      if (!doc.exists) return null;

      final group = HouseholdGroup.fromJson({...doc.data()!, 'id': doc.id});

      if (!group.members.contains(uid)) {
        final updatedMembers = [...group.members, uid];
        await _groupsRef.doc(inviteCode.toUpperCase()).update({
          'members': updatedMembers,
        });
        await _firestore.collection('users').doc(uid).update({
          'householdGroupId': inviteCode.toUpperCase(),
        });
      }

      final updatedDoc = await _groupsRef.doc(inviteCode.toUpperCase()).get();
      return HouseholdGroup.fromJson({...updatedDoc.data()!, 'id': updatedDoc.id});
    } catch (e) {
      throw Exception('Failed to join group: $e');
    }
  }

  Future<HouseholdGroup?> getUserGroup(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final groupId = userDoc.data()?['householdGroupId'] as String?;

      if (groupId == null) return null;

      final groupDoc = await _groupsRef.doc(groupId).get();
      if (!groupDoc.exists) return null;

      return HouseholdGroup.fromJson({...groupDoc.data()!, 'id': groupDoc.id});
    } catch (e) {
      return null;
    }
  }

  Stream<HouseholdGroup?> watchGroup(String groupId) {
    return _groupsRef.doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return HouseholdGroup.fromJson({...doc.data()!, 'id': doc.id});
    });
  }

  Future<void> addSavings(String groupId, int amount) async {
    await _groupsRef.doc(groupId).update({
      'totalSavings': FieldValue.increment(amount),
    });
  }
}
