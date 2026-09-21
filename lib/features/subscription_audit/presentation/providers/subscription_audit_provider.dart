import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/subscription_audit_service.dart';
import '../../domain/models/subscription.dart';

final subscriptionAuditServiceProvider = Provider((ref) {
  return SubscriptionAuditService();
});

// autoDispose: このプロバイダーが監視されなくなったら Firestore の
// ストリーム購読を確実に解除し、リークを防ぐ。
final subscriptionsStreamProvider =
    StreamProvider.autoDispose.family<List<Subscription>, String>((ref, uid) {
  final service = ref.watch(subscriptionAuditServiceProvider);
  return service.watchSubscriptions(uid);
});
