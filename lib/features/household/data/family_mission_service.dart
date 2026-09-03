import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/family_mission.dart';

/// 家族ミッションサービス
/// Firestore上での家族ミッションの作成・更新・読み取り
class FamilyMissionService {
  final FirebaseFirestore _firestore;

  FamilyMissionService(this._firestore);

  /// コレクション参照
  CollectionReference<Map<String, dynamic>> _missionsCollection(String groupId) =>
      _firestore.collection('household_groups').doc(groupId).collection('family_missions');

  /// 今週のミッションを取得または作成
  Future<FamilyMission> getOrCreateCurrentWeeklyMission(String groupId) async {
    final template = FamilyMissionTemplates.currentWeeklyMission(groupId);

    final doc = await _missionsCollection(groupId).doc(template.id).get();

    if (doc.exists) {
      return FamilyMission.fromJson(doc.data()!);
    }

    // 存在しない場合は作成
    await _missionsCollection(groupId).doc(template.id).set(template.toJson());
    return template;
  }

  /// ミッションを取得
  Future<FamilyMission?> getMission(String groupId, String missionId) async {
    final doc = await _missionsCollection(groupId).doc(missionId).get();
    if (!doc.exists) return null;
    return FamilyMission.fromJson(doc.data()!);
  }

  /// グループのすべてのミッションを取得（最新順）
  Future<List<FamilyMission>> getMissions(String groupId) async {
    final snapshot = await _missionsCollection(groupId)
        .orderBy('startDate', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FamilyMission.fromJson(doc.data()))
        .toList();
  }

  /// 現在有効なミッション（複数可能）
  Future<List<FamilyMission>> getActiveMissions(String groupId) async {
    final snapshot = await _missionsCollection(groupId).get();

    final missions = snapshot.docs
        .map((doc) => FamilyMission.fromJson(doc.data()))
        .toList();

    return missions.where((m) => m.isActive).toList();
  }

  /// ユーザーのミッション参加状況を更新
  Future<void> updateParticipantContribution(
    String groupId,
    String missionId,
    String uid,
    int contribution,
  ) async {
    final mission = await getMission(groupId, missionId);
    if (mission == null) return;

    final participants = mission.participants.toList();
    final index = participants.indexWhere((p) => p.uid == uid);

    if (index >= 0) {
      // 既存参加者の場合は貢献額を更新
      final updatedParticipant = FamilyMissionParticipant(
        uid: participants[index].uid,
        nickname: participants[index].nickname,
        contribution: contribution,
        score: participants[index].score,
        completedDates: participants[index].completedDates,
      );
      participants[index] = updatedParticipant;
    } else {
      // 新規参加者の場合は追加
      participants.add(
        FamilyMissionParticipant(
          uid: uid,
          nickname: uid, // ニックネームは別途取得が必要
          contribution: contribution,
        ),
      );
    }

    await _missionsCollection(groupId).doc(missionId).update({
      'participants': participants.map((p) => p.toJson()).toList(),
    });
  }

  /// ユーザーのスコアを更新（達成時のボーナス）
  Future<void> updateParticipantScore(
    String groupId,
    String missionId,
    String uid,
    int scoreBonus,
  ) async {
    final mission = await getMission(groupId, missionId);
    if (mission == null) return;

    final participants = mission.participants.toList();
    final index = participants.indexWhere((p) => p.uid == uid);

    if (index >= 0) {
      final updatedParticipant = FamilyMissionParticipant(
        uid: participants[index].uid,
        nickname: participants[index].nickname,
        contribution: participants[index].contribution,
        score: participants[index].score + scoreBonus,
        completedDates: [
          ...participants[index].completedDates,
          DateTime.now(),
        ],
      );
      participants[index] = updatedParticipant;

      await _missionsCollection(groupId).doc(missionId).update({
        'participants': participants.map((p) => p.toJson()).toList(),
      });
    }
  }

  /// ミッションを達成フラグ
  Future<void> completeMission(String groupId, String missionId) async {
    await _missionsCollection(groupId).doc(missionId).update({
      'isCompleted': true,
      'completedAt': DateTime.now().toIso8601String(),
    });
  }

  /// ミッションをストリームで監視
  Stream<FamilyMission?> watchMission(String groupId, String missionId) {
    return _missionsCollection(groupId)
        .doc(missionId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return FamilyMission.fromJson(doc.data()!);
    });
  }

  /// グループのミッション一覧をストリームで監視
  Stream<List<FamilyMission>> watchMissions(String groupId) {
    return _missionsCollection(groupId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FamilyMission.fromJson(doc.data()))
            .toList());
  }

  /// 週間ボーナスXPを計算（全参加者のスコアから）
  int calculateWeeklyBonusXP(FamilyMission mission) {
    if (mission.isCompleted) {
      return mission.weeklyBonusXP;
    }

    // 進捗度に応じたボーナス計算
    final progressRatio = mission.progressRatio;
    if (progressRatio >= 1.0) {
      return mission.weeklyBonusXP;
    } else if (progressRatio >= 0.75) {
      return (mission.weeklyBonusXP * 0.75).toInt();
    } else if (progressRatio >= 0.5) {
      return (mission.weeklyBonusXP * 0.5).toInt();
    }

    return 0;
  }

  /// 家族メンバーの達成状況レポート
  Map<String, dynamic> generateMissionReport(FamilyMission mission) {
    final ranking = mission.ranking;
    final topPerformer = ranking.isNotEmpty ? ranking.first : null;

    return {
      'missionTitle': mission.title,
      'emoji': mission.emoji,
      'progressRatio': mission.progressRatio,
      'totalContribution': mission.totalContribution,
      'targetAmount': mission.targetAmount,
      'topPerformer': topPerformer?.nickname ?? '該当者なし',
      'topContribution': topPerformer?.contribution ?? 0,
      'memberCount': mission.memberCount,
      'daysRemaining': mission.daysRemaining,
      'isCompleted': mission.isCompleted,
      'eventProposal': mission.eventProposal,
    };
  }
}
