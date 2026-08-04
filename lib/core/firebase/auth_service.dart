import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      print('Anonymous sign-in failed: $e');
      return null;
    }
  }

  Future<void> _initializeUserProfile(String uid) async {
    try {
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
        });
      }
    } catch (e) {
      print('Failed to initialize user profile: $e');
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
      );
    } catch (e) {
      print('Failed to get user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    int? streak,
    int? totalXP,
    int? level,
    bool? ahaAchieved,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (streak != null) updates['streak'] = streak;
      if (totalXP != null) updates['totalXP'] = totalXP;
      if (level != null) updates['level'] = level;
      if (ahaAchieved != null) updates['ahaAchieved'] = ahaAchieved;
      updates['lastUpdatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      print('Failed to update user profile: $e');
    }
  }

  Stream<UserProfile?> getUserProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      return UserProfile(
        uid: uid,
        email: data['email'],
        streak: data['streak'] ?? 0,
        totalXP: data['totalXP'] ?? 0,
        level: data['level'] ?? 1,
        ahaAchieved: data['ahaAchieved'] ?? false,
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
      print('Failed to sign out: $e');
    }
  }
}
