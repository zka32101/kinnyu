import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/subscription.dart';

class SubscriptionAuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _subscriptionsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('subscriptions');
  }

  /// 登録されたサブスクリプションをリアルタイムで購読する（作成日時の降順）
  Stream<List<Subscription>> watchSubscriptions(String uid) {
    return _subscriptionsRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Subscription.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<Subscription> addSubscription({
    required String uid,
    required String name,
    required int amount,
    required SubscriptionBillingCycle billingCycle,
    required SubscriptionCategory category,
  }) async {
    final docRef = _subscriptionsRef(uid).doc();
    final subscription = Subscription(
      id: docRef.id,
      uid: uid,
      name: name,
      amount: amount,
      billingCycle: billingCycle,
      category: category,
      isActive: true,
      createdAt: DateTime.now(),
    );

    try {
      await docRef.set(subscription.toJson());
      return subscription;
    } catch (e) {
      debugPrint('SubscriptionAuditService.addSubscription failed: $e');
      rethrow;
    }
  }

  Future<void> updateSubscription(Subscription subscription) async {
    try {
      await _subscriptionsRef(subscription.uid)
          .doc(subscription.id)
          .update(subscription.toJson());
    } catch (e) {
      debugPrint('SubscriptionAuditService.updateSubscription failed: $e');
      rethrow;
    }
  }

  Future<void> setActive({
    required String uid,
    required String subscriptionId,
    required bool isActive,
  }) async {
    try {
      await _subscriptionsRef(uid).doc(subscriptionId).update({'isActive': isActive});
    } catch (e) {
      debugPrint('SubscriptionAuditService.setActive failed: $e');
      rethrow;
    }
  }

  Future<void> deleteSubscription(String uid, String subscriptionId) async {
    try {
      await _subscriptionsRef(uid).doc(subscriptionId).delete();
    } catch (e) {
      debugPrint('SubscriptionAuditService.deleteSubscription failed: $e');
      rethrow;
    }
  }
}
