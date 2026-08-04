import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/premium/presentation/pages/paywall_page.dart';

void main() {
  group('PaywallPage', () {
    testWidgets('renders feature list and a not-yet-available message',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: PaywallPage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('お金コレ！プレミアム'), findsOneWidget);
      expect(find.textContaining('投資シミュレーション'), findsWidgets);
      expect(find.textContaining('Excel出力'), findsWidgets);

      // RevenueCat 未設定のため getOfferings() は null → 商品なしメッセージが出る
      expect(find.textContaining('準備中'), findsOneWidget);
    });

    testWidgets('has a restore purchases button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: PaywallPage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('購入履歴を復元'), findsOneWidget);
    });
  });
}
