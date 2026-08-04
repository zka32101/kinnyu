import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/core/subscription/subscription_provider.dart';

void main() {
  group('isPremiumProvider', () {
    test('defaults to false (free) before any refresh', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(isPremiumProvider), isFalse);
    });

    test('setPremium updates the state directly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(isPremiumProvider.notifier).setPremium(true);
      expect(container.read(isPremiumProvider), isTrue);

      container.read(isPremiumProvider.notifier).setPremium(false);
      expect(container.read(isPremiumProvider), isFalse);
    });

    test('refresh() without a configured RevenueCat SDK resolves to false',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // SubscriptionService は API キー未設定のため isPremium() は常に false を返す
      await container.read(isPremiumProvider.notifier).refresh();
      expect(container.read(isPremiumProvider), isFalse);
    });
  });
}
