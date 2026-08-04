import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'subscription_service.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

/// プレミアム加入状態。アプリ起動時・購入直後・復元直後に refresh() で再取得する。
final isPremiumProvider = NotifierProvider<IsPremiumNotifier, bool>(() {
  return IsPremiumNotifier();
});

class IsPremiumNotifier extends Notifier<bool> {
  @override
  bool build() {
    // 初期値は false（無料）。起動後に refresh() で実際の状態を反映する。
    return false;
  }

  Future<void> refresh() async {
    final service = ref.read(subscriptionServiceProvider);
    state = await service.isPremium();
  }

  void setPremium(bool value) {
    state = value;
  }
}
