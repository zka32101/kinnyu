import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/glossary/presentation/pages/glossary_page.dart';

void main() {
  group('GlossaryPage Widget', () {
    testWidgets('renders without crash and shows search field',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GlossaryPage()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('filtering by search narrows the list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GlossaryPage()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'NISA');
      await tester.pumpAndSettle();

      // 検索欄とカード見出しの2箇所に「NISA」が出る（=カードが1件に絞られている）
      expect(find.text('NISA'), findsNWidgets(2));
      // iDeCo など他カテゴリの用語は絞り込みで消える
      expect(find.text('iDeCo'), findsNothing);
    });
  });
}
