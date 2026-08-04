import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/quiz/domain/models/question.dart';
import 'package:okane_kore/core/firebase/firebase_init.dart';

void main() {
  group('Question Seed Data', () {
    final questions = FirebaseInitializer.allQuestions();

    test('has at least 80 questions total', () {
      expect(questions.length, greaterThanOrEqualTo(80));
    });

    test('all question IDs are unique', () {
      final ids = questions.map((q) => q.id).toSet();
      expect(ids.length, equals(questions.length),
          reason: '重複したIDが存在します');
    });

    test('every correctAnswerIndex is within options range', () {
      for (final q in questions) {
        expect(q.correctAnswerIndex, greaterThanOrEqualTo(0),
            reason: '${q.id}: correctAnswerIndex が負');
        expect(q.correctAnswerIndex, lessThan(q.options.length),
            reason: '${q.id}: correctAnswerIndex が選択肢範囲外');
      }
    });

    test('every question has at least 2 options', () {
      for (final q in questions) {
        expect(q.options.length, greaterThanOrEqualTo(2),
            reason: '${q.id}: 選択肢が不足');
      }
    });

    test('every question has non-empty text and explanation', () {
      for (final q in questions) {
        expect(q.question.trim(), isNotEmpty, reason: '${q.id}: 問題文が空');
        expect(q.explanation.trim(), isNotEmpty, reason: '${q.id}: 解説が空');
      }
    });

    test('each category has at least 20 questions', () {
      for (final category in QuizCategory.values) {
        final count = questions.where((q) => q.category == category).length;
        expect(count, greaterThanOrEqualTo(20),
            reason: '$category の問題数が不足: $count問');
      }
    });

    test('difficulty levels are represented in each category', () {
      for (final category in QuizCategory.values) {
        final catQuestions =
            questions.where((q) => q.category == category).toList();
        final difficulties = catQuestions.map((q) => q.difficulty).toSet();
        expect(difficulties.length, greaterThanOrEqualTo(2),
            reason: '$category は難易度のバリエーションが不足');
      }
    });
  });
}
