import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// アカウント削除時に、ユーザーの Firestore データをすべて消すサービス。
///
/// Google Play の「アカウント削除」要件に対応する。Firebase Authentication の
/// ユーザー自体の削除は [AuthService.deleteCurrentUser] が担当する。
/// **データ削除は認証が有効なうちに行う**必要があるため、呼び出し側は
/// 「再認証 → [deleteUserData] → ユーザー削除」の順で実行すること。
///
/// 新しい保存先（`users/{uid}` 配下のサブコレクションなど）を追加したら、
/// [userSubcollections] に足すこと。足し忘れると削除後にデータが残る。
class AccountDeletionService {
  AccountDeletionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// `users/{uid}` 配下にあるサブコレクション名。
  static const List<String> userSubcollections = [
    'spending',
    'roleplay_results',
    'receipts',
    'subscriptions',
    'savingsGoals',
    'missions',
    'investments',
    'furusatoGifts',
  ];

  /// 一括削除1回あたりの件数（Firestore のバッチ上限500より小さくしておく）。
  static const int _batchSize = 400;

  /// [uid] のデータをすべて削除する。途中で失敗した場合は例外を投げる
  /// （削除済みの分はそのまま。再度呼べば残りを削除できる）。
  Future<void> deleteUserData(String uid) async {
    await _leaveHouseholdGroup(uid);
    await _removeFromChallenges(uid);

    final userRef = _firestore.collection('users').doc(uid);
    for (final name in userSubcollections) {
      await _deleteCollection(userRef.collection(name));
    }

    await _firestore.collection('streaks').doc(uid).delete();
    await _deleteLegacyReceipts(uid);

    // 世帯離脱で参照する householdGroupId を読み終えてから、最後に消す。
    await userRef.delete();
  }

  /// 世帯グループから抜け、ニックネームと貢献額を消す。
  Future<void> _leaveHouseholdGroup(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);
    final groupId = (await userRef.get()).data()?['householdGroupId'] as String?;
    if (groupId == null || groupId.isEmpty) return;

    final groupRef = _firestore.collection('household_groups').doc(groupId);
    if (!(await groupRef.get()).exists) return;
    await groupRef.update({
      'members': FieldValue.arrayRemove([uid]),
      'memberNicknames.$uid': FieldValue.delete(),
      'memberContributions.$uid': FieldValue.delete(),
    });
  }

  /// 週次チャレンジの参加者リストから自分を外す。
  Future<void> _removeFromChallenges(String uid) async {
    final snapshot = await _firestore.collection('challenges').limit(100).get();
    for (final doc in snapshot.docs) {
      final raw = doc.data()['participants'];
      if (raw is! List) continue;
      final kept = raw
          .where((p) => !(p is Map && p['uid'] == uid))
          .toList(growable: false);
      if (kept.length != raw.length) {
        await doc.reference.update({'participants': kept});
      }
    }
  }

  /// 旧構造（ルート直下の `receipts`）に残っている自分のレシートを消す。
  Future<void> _deleteLegacyReceipts(String uid) async {
    while (true) {
      final snapshot = await _firestore
          .collection('receipts')
          .where('uid', isEqualTo: uid)
          .limit(_batchSize)
          .get();
      if (snapshot.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  /// コレクション内のドキュメントをすべて消す（サブコレクションは対象外）。
  Future<void> _deleteCollection(CollectionReference<Map<String, dynamic>> ref) async {
    while (true) {
      final snapshot = await ref.limit(_batchSize).get();
      if (snapshot.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('[AccountDeletion] ${ref.path}: ${snapshot.docs.length}件削除');
    }
  }
}
