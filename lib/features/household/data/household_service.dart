import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
    required String nickname,
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
      memberNicknames: {uid: nickname},
      memberContributions: {},
    );

    try {
      await _firestore.runTransaction((transaction) async {
        transaction.set(_groupsRef.doc(inviteCode), group.toJson());
        transaction.update(_firestore.collection('users').doc(uid), {
          'householdGroupId': inviteCode,
        });
      });
    } catch (e) {
      debugPrint('createGroup transaction failed: $e');
      rethrow;
    }

    return group;
  }

  Future<HouseholdGroup?> joinGroup({
    required String uid,
    required String inviteCode,
    required String nickname,
  }) async {
    final code = inviteCode.toUpperCase();
    final groupDocRef = _groupsRef.doc(code);
    final userDocRef = _firestore.collection('users').doc(uid);

    try {
      return await _firestore.runTransaction<HouseholdGroup?>((transaction) async {
        final doc = await transaction.get(groupDocRef);
        if (!doc.exists) return null;

        final group = HouseholdGroup.fromJson({...doc.data()!, 'id': doc.id});

        if (!group.members.contains(uid)) {
          transaction.update(groupDocRef, {
            'members': FieldValue.arrayUnion([uid]),
            'memberNicknames.$uid': nickname,
          });
          transaction.update(userDocRef, {
            'householdGroupId': code,
          });

          return HouseholdGroup(
            id: group.id,
            name: group.name,
            members: [...group.members, uid],
            totalSavings: group.totalSavings,
            monthlyGoal: group.monthlyGoal,
            createdAt: group.createdAt,
            memberNicknames: {...group.memberNicknames, uid: nickname},
            memberContributions: group.memberContributions,
          );
        }

        return group;
      });
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
    }).transform(
      StreamTransformer.fromHandlers(
        handleError: (error, stack, sink) {
          debugPrint('watchGroup error: $error');
          sink.addError(error, stack);
        },
      ),
    );
  }

  Future<void> addSavings(String groupId, String uid, int amount) async {
    try {
      await _groupsRef.doc(groupId).update({
        'totalSavings': FieldValue.increment(amount),
        'memberContributions.$uid': FieldValue.increment(amount),
      });
    } catch (e) {
      debugPrint('addSavings failed: $e');
      rethrow;
    }
  }

  Future<void> leaveGroup({
    required String uid,
    required String groupId,
  }) async {
    final groupDocRef = _groupsRef.doc(groupId);
    final userDocRef = _firestore.collection('users').doc(uid);

    try {
      await _firestore.runTransaction((transaction) async {
        transaction.update(groupDocRef, {
          'members': FieldValue.arrayRemove([uid]),
          'memberNicknames.$uid': FieldValue.delete(),
          'memberContributions.$uid': FieldValue.delete(),
        });
        transaction.update(userDocRef, {
          'householdGroupId': FieldValue.delete(),
        });
      });
    } catch (e) {
      debugPrint('leaveGroup failed: $e');
      rethrow;
    }
  }
}
