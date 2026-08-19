import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  /// 現在の暦週に対して決定的なシード値を計算する。
  /// 同じ週内であれば何度呼び出しても同じ値になるため、
  /// 同時に走った `_seedWeeklyMissions` 呼び出し同士が
  /// 同じミッションID群を生成し、書き込みが冪等になる。
  int _weeklySeed() {
    final now = DateTime.now();
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(firstDayOfYear).inDays + 1;
    final weekNumber = ((dayOfYear - now.weekday + 10) / 7).floor();
    return now.year * 100 + weekNumber;
  }

  Future<List<Mission>> _seedWeeklyMissions(String uid) async {
    // 週単位で決定的なシードを使うことで、同時に複数回シードが
    // 走っても同じドキュメントIDが生成され、バッチ書き込みが
    // 上書き（冪等）になり重複ミッションを防ぐ。
    final missions =
        MissionTemplates.generateWeeklyMissions(seed: _weeklySeed());

    final batch = _firestore.batch();
    for (final mission in missions) {
      final docRef = _userMissionsRef(uid).doc(mission.id);
      batch.set(docRef, mission.toJson(), SetOptions(merge: true));
    }
    await batch.commit();

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

  /// 完了済みミッション数を取得する（実績・バッジ機能の集計用）。
  /// Firestore の Aggregation Query（count）を使い、ドキュメント本体を
  /// 取得せずに件数のみをカウントする。失敗した場合は 0 を返す。
  Future<int> getCompletedMissionsCount(String uid) async {
    try {
      final snapshot = await _userMissionsRef(uid)
          .where('status', isEqualTo: MissionStatus.completed.index)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Failed to get completed missions count: $e');
      return 0;
    }
  }

  Stream<List<Mission>> watchActiveMissions(String uid) {
    return _userMissionsRef(uid)
        .where('status', isEqualTo: MissionStatus.pending.index)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              try {
                return Mission.fromJson({...doc.data(), 'id': doc.id});
              } catch (e) {
                debugPrint('Failed to parse mission doc ${doc.id}: $e');
                return null;
              }
            })
            .whereType<Mission>()
            .toList())
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stack, sink) {
              debugPrint('watchActiveMissions error: $error');
              sink.addError(error, stack);
            },
          ),
        );
  }
}
