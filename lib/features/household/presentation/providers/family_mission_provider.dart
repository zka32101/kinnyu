import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/family_mission_service.dart';
import '../../domain/models/family_mission.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';

/// FamilyMissionService プロバイダー
final familyMissionServiceProvider = Provider((ref) {
  return FamilyMissionService(FirebaseFirestore.instance);
});

/// 現在のグループIDプロバイダー
/// 注: household_provider から取得する必要があります
final currentGroupIdProvider = StateProvider<String?>((ref) => null);

/// 今週の家族ミッションを取得
final weeklyFamilyMissionProvider = FutureProvider.family<FamilyMission?, String>(
  (ref, groupId) async {
    final service = ref.watch(familyMissionServiceProvider);
    return await service.getOrCreateCurrentWeeklyMission(groupId);
  },
);

/// グループのすべてのミッションを取得
final familyMissionsProvider = FutureProvider.family<List<FamilyMission>, String>(
  (ref, groupId) async {
    final service = ref.watch(familyMissionServiceProvider);
    return await service.getMissions(groupId);
  },
);

/// 現在有効なミッション一覧を取得
final activeFamilyMissionsProvider = FutureProvider.family<List<FamilyMission>, String>(
  (ref, groupId) async {
    final service = ref.watch(familyMissionServiceProvider);
    return await service.getActiveMissions(groupId);
  },
);

/// 特定のミッションをストリームで監視
final watchFamilyMissionProvider =
    StreamProvider.family<FamilyMission?, (String, String)>(
  (ref, params) {
    final (groupId, missionId) = params;
    final service = ref.watch(familyMissionServiceProvider);
    return service.watchMission(groupId, missionId);
  },
);

/// グループのミッション一覧をストリームで監視
final watchFamilyMissionsProvider = StreamProvider.family<List<FamilyMission>, String>(
  (ref, groupId) {
    final service = ref.watch(familyMissionServiceProvider);
    return service.watchMissions(groupId);
  },
);

/// ユーザーの現在のミッションランキングを計算
final userMissionRankingProvider =
    FutureProvider.family<int, (String, String, String)>(
  (ref, params) async {
    final (groupId, missionId, uid) = params;
    final service = ref.watch(familyMissionServiceProvider);
    final mission = await service.getMission(groupId, missionId);

    if (mission == null) return 0;

    final ranking = mission.ranking;
    final userIndex = ranking.indexWhere((p) => p.uid == uid);

    return userIndex >= 0 ? userIndex + 1 : 0;
  },
);

/// ユーザーの週間ランキング（スコア順）
final userWeeklyScoreProvider = FutureProvider.family<int, (String, String)>(
  (ref, params) async {
    final (groupId, uid) = params;
    final service = ref.watch(familyMissionServiceProvider);
    final mission = await service.getOrCreateCurrentWeeklyMission(groupId);

    final participant = mission.getParticipant(uid);
    return participant?.score ?? 0;
  },
);

/// ファミリーミッション達成状況レポート
final familyMissionReportProvider =
    FutureProvider.family<Map<String, dynamic>, (String, String)>(
  (ref, params) async {
    final (groupId, missionId) = params;
    final service = ref.watch(familyMissionServiceProvider);
    final mission = await service.getMission(groupId, missionId);

    if (mission == null) {
      return {'error': 'Mission not found'};
    }

    return service.generateMissionReport(mission);
  },
);

/// ファミリーミッション更新プロバイダー（mutator）
final familyMissionMutatorProvider = Provider((ref) {
  return FamilyMissionMutator(
    ref.watch(familyMissionServiceProvider),
  );
});

/// ミッション更新のためのクラス
class FamilyMissionMutator {
  final FamilyMissionService _service;

  FamilyMissionMutator(this._service);

  /// ユーザーのミッション参加を記録
  Future<void> recordParticipation(
    String groupId,
    String missionId,
    String uid,
    int contribution,
  ) async {
    await _service.updateParticipantContribution(
      groupId,
      missionId,
      uid,
      contribution,
    );
  }

  /// ユーザーのミッション完了を記録（ボーナス適用）
  Future<void> recordMissionCompletion(
    String groupId,
    String missionId,
    String uid,
  ) async {
    const scoreBonus = 100; // 完了時のボーナス
    await _service.updateParticipantScore(
      groupId,
      missionId,
      uid,
      scoreBonus,
    );
  }

  /// ファミリーミッションを達成フラグ
  Future<void> completeFamilyMission(
    String groupId,
    String missionId,
  ) async {
    await _service.completeMission(groupId, missionId);
  }
}
