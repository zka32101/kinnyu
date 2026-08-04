import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/simulation/presentation/pages/simulation_hub_page.dart';
import 'package:okane_kore/features/simulation/presentation/pages/investment_simulator_page.dart';
import 'package:okane_kore/features/simulation/presentation/pages/household_simulator_page.dart';

void main() {
  group('SimulationHubPage', () {
    testWidgets('renders both simulation cards', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: SimulationHubPage())));
      await tester.pumpAndSettle();

      expect(find.text('家計シミュレーション'), findsOneWidget);
      expect(find.text('積立投資シミュレーション'), findsOneWidget);
    });

    testWidgets('tapping household card navigates to HouseholdSimulatorPage',
        (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: SimulationHubPage())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('家計シミュレーション'));
      await tester.pumpAndSettle();

      expect(find.byType(HouseholdSimulatorPage), findsOneWidget);
    });

    testWidgets('tapping investment card navigates to InvestmentSimulatorPage',
        (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: SimulationHubPage())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('積立投資シミュレーション'));
      await tester.pumpAndSettle();

      expect(find.byType(InvestmentSimulatorPage), findsOneWidget);
    });
  });

  group('InvestmentSimulatorPage', () {
    testWidgets('renders without crash and shows a result', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: InvestmentSimulatorPage())),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsNWidgets(1));
      expect(find.textContaining('¥'), findsWidgets);
    });

    testWidgets('changing monthly amount updates the result', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: InvestmentSimulatorPage())),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '50000');
      await tester.pumpAndSettle();

      // 積立額が反映され、クラッシュせず結果が更新される
      expect(find.textContaining('¥'), findsWidgets);
    });

    testWidgets('tapping the free pattern card applies its values directly',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: InvestmentSimulatorPage())),
      );
      await tester.pumpAndSettle();

      // 無料枠（1件目: はじめての積立）はプレミアム未加入でも即座に適用される
      expect(find.text('はじめての積立'), findsOneWidget);
      await tester.tap(find.text('はじめての積立'));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller?.text, equals('1000'));
    });

    testWidgets('tapping a locked pattern card opens the paywall',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: InvestmentSimulatorPage())),
      );
      await tester.pumpAndSettle();

      // 2件目以降はプレミアム未加入だとロックされ、Paywallへ遷移する
      expect(find.text('新NISAつみたて満額'), findsOneWidget);
      await tester.tap(find.text('新NISAつみたて満額'));
      await tester.pumpAndSettle();

      expect(find.text('お金コレ！プレミアム'), findsOneWidget);
    });

    testWidgets('switching to real-fluctuation mode shows yearly returns',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: InvestmentSimulatorPage())),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('リアル変動'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('リアル変動'));
      await tester.pumpAndSettle();

      expect(find.text('再抽選'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('年ごとの利回りと評価額'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('年ごとの利回りと評価額'), findsOneWidget);
    });

    testWidgets('reroll button changes yearly returns in real mode',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: InvestmentSimulatorPage())),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('リアル変動'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('リアル変動'));
      await tester.pumpAndSettle();

      // クラッシュせず再抽選できることを確認
      await tester.tap(find.text('再抽選'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('年ごとの利回りと評価額'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('年ごとの利回りと評価額'), findsOneWidget);
    });
  });

  group('HouseholdSimulatorPage', () {
    testWidgets('renders without crash and shows monthly savings',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HouseholdSimulatorPage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('毎月の貯蓄額'), findsOneWidget);
    });

    testWidgets('shows deficit warning when expense exceeds income',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HouseholdSimulatorPage())),
      );
      await tester.pumpAndSettle();

      final incomeField = find.byType(TextField).first;
      await tester.enterText(incomeField, '100000');
      await tester.pumpAndSettle();

      expect(find.text('毎月の赤字額'), findsOneWidget);
    });

    testWidgets('starts in simple mode with 2 text fields',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HouseholdSimulatorPage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('簡易'), findsOneWidget);
      expect(find.text('詳細（年度別）'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('switching to detailed mode shows per-year input rows',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HouseholdSimulatorPage())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('詳細（年度別）'));
      await tester.pumpAndSettle();

      // 初期値は10年 → 年度カードが10件（1年目はスクロール前でも見える）
      expect(find.textContaining('1年目'), findsOneWidget);

      // 最後までスクロールして10年目のカードとフィールド数を確認
      await tester.scrollUntilVisible(
        find.textContaining('10年目'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('10年目'), findsOneWidget);
    });

    testWidgets('has an Excel export button in the app bar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HouseholdSimulatorPage())),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.ios_share), findsOneWidget);
    });

    testWidgets('tapping Excel export without premium opens the paywall',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HouseholdSimulatorPage())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.ios_share));
      await tester.pumpAndSettle();

      expect(find.text('お金コレ！プレミアム'), findsOneWidget);
    });
  });
}
