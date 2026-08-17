import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'subscription_service.dart';
import '../firebase/auth_provider.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

/// プレミアム加入状態。アプリ起動時・購入直後・復元直後に refresh() で再取得する。
final isPremiumProvider = NotifierProvider<IsPremiumNotifier, bool>(() {
  return IsPremiumNotifier();
});

class IsPremiumNotifier extends Notifier<bool> {
  String? _currentUserId;

  @override
  bool build() {
    // currentUserProvider（authStateChanges）を監視し、ログインユーザーが
    // 変わったとき（サインアウト→別ユーザーでサインインなど）に
    // プレミアム状態が前のユーザーのものが残らないようリセットして
    // 再取得する。これによりユーザーセッションをまたいだ
    // プレミアム状態の漏れを防ぐ。
    _currentUserId = ref.read(currentUserProvider).asData?.value?.uid;

    ref.listen(currentUserProvider, (previous, next) {
      final newUserId = next.asData?.value?.uid;
      if (newUserId != _currentUserId) {
        _currentUserId = newUserId;
        // fire-and-forget: リスナー内なので await せず、内部で例外を握りつぶす
        resetAndRefresh();
      }
    });

    // 初期値は false（無料）。起動後に refresh() で実際の状態を反映する。
    return false;
  }

  Future<void> refresh() async {
    try {
      final service = ref.read(subscriptionServiceProvider);
      state = await service.isPremium();
    } catch (e) {
      // refresh() は呼び出し元（例: main.dart の initState）に例外を
      // 伝播させない。エラーはログに残すだけにして、アプリが起動不能に
      // ならないようにする。
      debugPrint('IsPremiumNotifier.refresh() failed: $e');
    }
  }

  /// 状態を無料（false）にリセットしたうえで refresh() を実行する。
  ///
  /// TODO: 現状は build() 内で currentUserProvider を監視して自動的に
  /// 呼び出しているが、もし将来 main.dart 側で明示的にサインイン/サインアウトの
  /// タイミングを検知できる場合は、そこから直接
  /// `ref.read(isPremiumProvider.notifier).resetAndRefresh()` を呼び出しても良い。
  Future<void> resetAndRefresh() async {
    state = false;
    await refresh();
  }

  void setPremium(bool value) {
    state = value;
  }
}
