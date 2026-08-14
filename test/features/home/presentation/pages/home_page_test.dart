import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/home/presentation/pages/home_page.dart';
import 'package:okane_kore/features/user_profile/presentation/providers/user_provider.dart';

void main() {
  group('HomePage Widget Tests', () {
    testWidgets('HomePage renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      expect(find.text('金融オンライン大学'), findsOneWidget);
      expect(find.text('ストリーク'), findsOneWidget);
      expect(find.text('ジャンルを選択'), findsOneWidget);
    });

    testWidgets('HomePage displays streak card', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      expect(find.text('0日間'), findsOneWidget);
      expect(find.text('今日の学習を完了してストリークを続けよう！'), findsOneWidget);
    });

    testWidgets('HomePage displays category grid', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      expect(find.text('貯蓄'), findsOneWidget);
      expect(find.text('税金'), findsOneWidget);
      expect(find.text('投資'), findsOneWidget);
      expect(find.text('保険'), findsOneWidget);
    });

    testWidgets('HomePage has floating action button for receipt', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      expect(find.byIcon(Icons.receipt_long), findsWidgets);
      expect(find.text('レシート記録'), findsOneWidget);
    });

    testWidgets('HomePage has appbar with icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      expect(find.byIcon(Icons.family_restroom), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });
  });
}
