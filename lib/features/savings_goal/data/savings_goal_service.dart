import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/savings_goal.dart';

class SavingsGoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _goalsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('savingsGoals');
  }

  /// 登録された貯金目標をリアルタイムで購読する（作成日時の降順）
  Stream<List<SavingsGoal>> watchGoals(String uid) {
    return _goalsRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SavingsGoal.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<SavingsGoal> addGoal({
    required String uid,
    required String name,
    required String emoji,
    required int targetAmount,
    required DateTime deadline,
  }) async {
    final docRef = _goalsRef(uid).doc();
    final goal = SavingsGoal(
      id: docRef.id,
      uid: uid,
      name: name,
      emoji: emoji,
      targetAmount: targetAmount,
      currentAmount: 0,
      deadline: deadline,
      createdAt: DateTime.now(),
    );

    try {
      await docRef.set(goal.toJson());
      return goal;
    } catch (e) {
      debugPrint('SavingsGoalService.addGoal failed: $e');
      rethrow;
    }
  }

  Future<void> updateProgress({
    required String uid,
    required String goalId,
    required int currentAmount,
  }) async {
    try {
      await _goalsRef(uid).doc(goalId).update({'currentAmount': currentAmount});
    } catch (e) {
      debugPrint('SavingsGoalService.updateProgress failed: $e');
      rethrow;
    }
  }

  Future<void> deleteGoal(String uid, String goalId) async {
    try {
      await _goalsRef(uid).doc(goalId).delete();
    } catch (e) {
      debugPrint('SavingsGoalService.deleteGoal failed: $e');
      rethrow;
    }
  }

  /// 実績（バッジ）機能向け：達成済みの貯金目標数を取得する
  Future<int> getAchievedGoalsCount(String uid) async {
    try {
      final snapshot = await _goalsRef(uid).get();
      return snapshot.docs
          .map((doc) => SavingsGoal.fromJson({...doc.data(), 'id': doc.id}))
          .where((goal) => goal.isAchieved)
          .length;
    } catch (e) {
      debugPrint('SavingsGoalService.getAchievedGoalsCount failed: $e');
      return 0;
    }
  }
}
