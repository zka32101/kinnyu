import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/challenge.dart';

class ChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _challengesRef =>
      _firestore.collection('challenges');

  Future<Challenge> getCurrentChallenge() async {
    final template = ChallengeTemplates.currentWeeklyChallenge();
    final doc = await _challengesRef.doc(template.id).get();

    if (!doc.exists) {
      await _challengesRef.doc(template.id).set(template.toJson());
      return template;
    }

    return Challenge.fromJson({...doc.data()!, 'id': doc.id});
  }

  Stream<Challenge> watchCurrentChallenge() {
    final template = ChallengeTemplates.currentWeeklyChallenge();
    return _challengesRef.doc(template.id).snapshots().map((doc) {
      if (!doc.exists) return template;
      return Challenge.fromJson({...doc.data()!, 'id': doc.id});
    });
  }

  Future<void> joinChallenge(String challengeId, String uid) async {
    final doc = await _challengesRef.doc(challengeId).get();
    if (!doc.exists) return;

    final challenge = Challenge.fromJson({...doc.data()!, 'id': doc.id});
    if (challenge.isParticipating(uid)) return;

    final updatedParticipants = [
      ...challenge.participants,
      ChallengeParticipant(uid: uid, reductionAmount: 0),
    ];

    await _challengesRef.doc(challengeId).update({
      'participants': updatedParticipants.map((p) => p.toJson()).toList(),
    });
  }

  Future<void> updateReduction(
      String challengeId, String uid, int reductionAmount) async {
    final doc = await _challengesRef.doc(challengeId).get();
    if (!doc.exists) return;

    final challenge = Challenge.fromJson({...doc.data()!, 'id': doc.id});
    final updatedParticipants = challenge.participants.map((p) {
      if (p.uid == uid) {
        return ChallengeParticipant(uid: uid, reductionAmount: reductionAmount);
      }
      return p;
    }).toList();

    await _challengesRef.doc(challengeId).update({
      'participants': updatedParticipants.map((p) => p.toJson()).toList(),
    });
  }
}
