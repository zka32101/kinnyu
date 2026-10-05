import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/mission/data/mission_service.dart';
import 'package:okane_kore/features/mission/domain/models/mission.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MissionService service;

  CollectionReference<Map<String, dynamic>> missions(String uid) =>
      db.collection('users').doc(uid).collection('missions');

  setUp(() {
    db = FakeFirebaseFirestore();
    service = MissionService(firestore: db);
  });

  test('ミッションが無いユーザーには今週分(3件)が作られる', () async {
    await service.ensureWeeklyMissions('u1');

    final docs = (await missions('u1').get()).docs;
    expect(docs, hasLength(3));
    expect(
      docs.every((d) => d.data()['status'] == MissionStatus.pending.index),
      isTrue,
    );
    final user = (await db.collection('users').doc('u1').get()).data()!;
    expect(user['lastMissionSeedWeek'], isA<int>());
  });

  test('何度呼んでも重複して作られない', () async {
    await service.ensureWeeklyMissions('u1');
    await service.ensureWeeklyMissions('u1');

    expect((await missions('u1').get()).docs, hasLength(3));
  });

  test('今週のミッションを全て完了しても、同じ週に作り直されない', () async {
    await service.ensureWeeklyMissions('u1');
    for (final doc in (await missions('u1').get()).docs) {
      await service.completeMission('u1', doc.id);
    }

    await service.ensureWeeklyMissions('u1');

    final docs = (await missions('u1').get()).docs;
    expect(docs, hasLength(3));
    expect(
      docs.every((d) => d.data()['status'] == MissionStatus.completed.index),
      isTrue,
    );
    expect(await service.getCompletedMissionsCount('u1'), 3);
  });

  test('期限切れの未完了ミッションは「期限切れ」になる', () async {
    await missions('u1').doc('old').set({
      'id': 'old',
      'type': MissionType.savingsTarget.index,
      'title': '古いミッション',
      'description': '',
      'rewardXP': 10,
      'deadline': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'status': MissionStatus.pending.index,
    });

    await service.ensureWeeklyMissions('u1');

    final old = (await missions('u1').doc('old').get()).data()!;
    expect(old['status'], MissionStatus.expired.index);
  });

  test('他のユーザーのミッションには影響しない', () async {
    await service.ensureWeeklyMissions('u1');
    expect((await missions('u2').get()).docs, isEmpty);
  });
}
