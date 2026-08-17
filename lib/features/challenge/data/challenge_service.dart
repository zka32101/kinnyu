import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/challenge.dart';

class ChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _challengesRef =>
      _firestore.collection('challenges');

  Future<Challenge> getCurrentChallenge() async {
    final template = ChallengeTemplates.currentWeeklyChallenge();
    final doc = await _challengesRef.doc(template.id).get();

    if (!doc.exists) {
      // template.id is a deterministic natural key (slug + week start date),
      // so concurrent get-or-create calls all target the same document.
      // Using SetOptions(merge: true) makes the creation idempotent instead
      // of racing/overwriting each other's data.
      await _challengesRef
          .doc(template.id)
          .set(template.toJson(), SetOptions(merge: true));
      return template;
    }

    return Challenge.fromJson({...doc.data()!, 'id': doc.id});
  }

  Stream<Challenge> watchCurrentChallenge() {
    final template = ChallengeTemplates.currentWeeklyChallenge();
    return _challengesRef.doc(template.id).snapshots().map((doc) {
      if (!doc.exists) return template;
      return Challenge.fromJson({...doc.data()!, 'id': doc.id});
    }).transform(
      StreamTransformer.fromHandlers(
        handleError: (error, stack, sink) {
          debugPrint('watchCurrentChallenge error: $error');
          sink.addError(error, stack);
        },
      ),
    );
  }

  Future<void> joinChallenge(String challengeId, String uid) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _challengesRef.doc(challengeId);
        final doc = await transaction.get(docRef);
        if (!doc.exists) return;

        final challenge = Challenge.fromJson({...doc.data()!, 'id': doc.id});
        if (challenge.isParticipating(uid)) return;

        transaction.update(docRef, {
          'participants': FieldValue.arrayUnion(
            [ChallengeParticipant(uid: uid, reductionAmount: 0).toJson()],
          ),
        });
      });
    } catch (e) {
      debugPrint('joinChallenge error: $e');
      rethrow;
    }
  }

  Future<void> updateReduction(
      String challengeId, String uid, int reductionAmount) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _challengesRef.doc(challengeId);
        final doc = await transaction.get(docRef);
        if (!doc.exists) return;

        final challenge = Challenge.fromJson({...doc.data()!, 'id': doc.id});
        final updatedParticipants = challenge.participants.map((p) {
          if (p.uid == uid) {
            return ChallengeParticipant(
                uid: uid, reductionAmount: reductionAmount);
          }
          return p;
        }).toList();

        transaction.update(docRef, {
          'participants':
              updatedParticipants.map((p) => p.toJson()).toList(),
        });
      });
    } catch (e) {
      debugPrint('updateReduction error: $e');
      rethrow;
    }
  }
}
