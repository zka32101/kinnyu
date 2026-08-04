import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/quiz/domain/models/question.dart';
import 'package:okane_kore/features/quiz/presentation/pages/quiz_page.dart';
import 'package:okane_kore/features/quiz/presentation/providers/question_provider.dart';

void main() {
  group('QuizPage Widget Tests', () {
    testWidgets('QuizPage renders without crash for savings category',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizPage(category: QuizCategory.savings),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Page should be rendered without exceptions
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('QuizPage renders without crash for tax category',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizPage(category: QuizCategory.tax),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Page should be rendered without exceptions
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('QuizPage renders without crash for invest category',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuizPage(category: QuizCategory.invest),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Page should be rendered without exceptions
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
