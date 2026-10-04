import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/core/firebase/account_deletion_service.dart';

void main() {
  late FakeFirebaseFirestore db;
  late AccountDeletionService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    service = AccountDeletionService(firestore: db);
  });

  Future<void> seedUser(String uid, {String? groupId}) async {
    await db.collection('users').doc(uid).set({
      'streak': 3,
      if (groupId != null) 'householdGroupId': groupId,
    });
    for (final name in AccountDeletionService.userSubcollections) {
      await db.collection('users').doc(uid).collection(name).add({'v': 1});
      await db.collection('users').doc(uid).collection(name).add({'v': 2});
    }
    await db.collection('streaks').doc(uid).set({'current': 5});
    await db.collection('receipts').add({'uid': uid, 'amount': 100});
  }

  test('自分のデータを全て削除し、他のユーザーのデータは残す', () async {
    await seedUser('u1', groupId: 'g1');
    await seedUser('u2', groupId: 'g1');
    await db.collection('household_groups').doc('g1').set({
      'members': ['u1', 'u2'],
      'memberNicknames': {'u1': 'たろう', 'u2': 'はなこ'},
      'memberContributions': {'u1': 1000, 'u2': 2000},
      'totalSavings': 3000,
    });
    await db.collection('challenges').doc('c1').set({
      'participants': [
        {'uid': 'u1', 'reductionAmount': 500},
        {'uid': 'u2', 'reductionAmount': 800},
      ],
    });

    await service.deleteUserData('u1');

    // u1: 全て消える
    expect((await db.collection('users').doc('u1').get()).exists, isFalse);
    for (final name in AccountDeletionService.userSubcollections) {
      expect(
        (await db.collection('users').doc('u1').collection(name).get()).docs,
        isEmpty,
        reason: 'users/u1/$name が残っている',
      );
    }
    expect((await db.collection('streaks').doc('u1').get()).exists, isFalse);
    final receipts = await db.collection('receipts').get();
    expect(receipts.docs.map((d) => d.data()['uid']), ['u2']);

    // 世帯: u1 だけが抜け、u2 は残る（合計貯蓄は触らない）
    final group = (await db.collection('household_groups').doc('g1').get()).data()!;
    expect(group['members'], ['u2']);
    expect(group['memberNicknames'], {'u2': 'はなこ'});
    expect(group['memberContributions'], {'u2': 2000});
    expect(group['totalSavings'], 3000);

    // チャレンジ: u1 の参加だけ外れる
    final challenge = (await db.collection('challenges').doc('c1').get()).data()!;
    expect(
      (challenge['participants'] as List).map((p) => (p as Map)['uid']),
      ['u2'],
    );

    // u2: 無傷
    expect((await db.collection('users').doc('u2').get()).exists, isTrue);
    for (final name in AccountDeletionService.userSubcollections) {
      expect(
        (await db.collection('users').doc('u2').collection(name).get()).docs,
        hasLength(2),
        reason: 'users/u2/$name が消えている',
      );
    }
    expect((await db.collection('streaks').doc('u2').get()).exists, isTrue);
  });

  test('世帯に未参加・ユーザー文書がなくても失敗しない', () async {
    await expectLater(service.deleteUserData('nobody'), completes);
    await seedUser('u3');
    await expectLater(service.deleteUserData('u3'), completes);
    expect((await db.collection('users').doc('u3').get()).exists, isFalse);
  });

  test('世帯グループが既に存在しなくても削除できる', () async {
    await seedUser('u4', groupId: 'gone');
    await expectLater(service.deleteUserData('u4'), completes);
    expect((await db.collection('users').doc('u4').get()).exists, isFalse);
  });

  test('件数が一括削除の上限を超えても全て消える', () async {
    await db.collection('users').doc('u5').set({'x': 1});
    final col = db.collection('users').doc('u5').collection('spending');
    for (var i = 0; i < 850; i++) {
      await col.add({'i': i});
    }
    await service.deleteUserData('u5');
    expect((await col.get()).docs, isEmpty);
  });
}
