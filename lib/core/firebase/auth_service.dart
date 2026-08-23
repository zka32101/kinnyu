import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../features/user_profile/presentation/providers/user_provider.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      await _initializeUserProfile(userCredential.user!.uid);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Anonymous sign-in failed: $e');
      return null;
    }
  }

  Future<void> _initializeUserProfile(String uid) async {
    try {
      // Use set(..., SetOptions(merge: true)) with the deterministic uid
      // document ID so that concurrent/repeated calls (e.g. two overlapping
      // signInAnonymously() calls) are idempotent instead of racing or
      // clobbering each other.
      final docSnapshot = await _firestore.collection('users').doc(uid).get();

      if (!docSnapshot.exists) {
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'email': null,
          'streak': 0,
          'totalXP': 0,
          'level': 1,
          'paidStatus': {},
          'ahaAchieved': false,
          'diagnosisPatternId': null,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Failed to initialize user profile: $e');
    }
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return UserProfile(
        uid: uid,
        email: data['email'],
        streak: data['streak'] ?? 0,
        totalXP: data['totalXP'] ?? 0,
        level: data['level'] ?? 1,
        ahaAchieved: data['ahaAchieved'] ?? false,
        diagnosisPatternId: data['diagnosisPatternId'],
      );
    } catch (e) {
      debugPrint('Failed to get user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    int? streak,
    int? totalXP,
    int? level,
    bool? ahaAchieved,
    String? diagnosisPatternId,
  }) async {
    final updates = <String, dynamic>{};
    if (streak != null) updates['streak'] = streak;
    if (totalXP != null) updates['totalXP'] = totalXP;
    if (level != null) updates['level'] = level;
    if (ahaAchieved != null) updates['ahaAchieved'] = ahaAchieved;
    if (diagnosisPatternId != null) {
      updates['diagnosisPatternId'] = diagnosisPatternId;
    }
    updates['lastUpdatedAt'] = FieldValue.serverTimestamp();

    try {
      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      // update() fails if the document doesn't exist yet. Fall back to a
      // merge-set so the profile gets created instead of failing silently.
      debugPrint(
        'updateUserProfile: update() failed for $uid ($e); '
        'falling back to set(merge: true)',
      );
      try {
        await _firestore
            .collection('users')
            .doc(uid)
            .set(updates, SetOptions(merge: true));
      } catch (e2) {
        debugPrint('Failed to update user profile via fallback set: $e2');
      }
    }
  }

  Stream<UserProfile?> getUserProfileStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .transform(
          StreamTransformer<DocumentSnapshot<Map<String, dynamic>>,
              DocumentSnapshot<Map<String, dynamic>>>.fromHandlers(
            handleData: (doc, sink) => sink.add(doc),
            handleError: (error, stack, sink) {
              debugPrint('getUserProfileStream error: $error');
              // Re-add the error so it still propagates as AsyncError to
              // any listening StreamProvider/UI .when(error: ...).
              sink.addError(error, stack);
            },
          ),
        )
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      return UserProfile(
        uid: uid,
        email: data['email'],
        streak: data['streak'] ?? 0,
        totalXP: data['totalXP'] ?? 0,
        level: data['level'] ?? 1,
        ahaAchieved: data['ahaAchieved'] ?? false,
        diagnosisPatternId: data['diagnosisPatternId'],
      );
    });
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Failed to sign out: $e');
    }
  }
}
