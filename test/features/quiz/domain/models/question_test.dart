import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/quiz/domain/models/question.dart';

void main() {
  group('Question', () {
    test('fromJson creates a valid Question instance', () {
      final json = {
        'id': 'q1',
        'category': 0, // QuizCategory.savings
        'difficulty': 1, // QuizDifficulty.medium
        'question': 'What is saving?',
        'options': ['Option A', 'Option B', 'Option C'],
        'correctAnswerIndex': 0,
        'explanation': 'This is the correct answer',
      };

      final question = Question.fromJson(json);

      expect(question.id, equals('q1'));
      expect(question.category, equals(QuizCategory.savings));
      expect(question.difficulty, equals(QuizDifficulty.medium));
      expect(question.question, equals('What is saving?'));
      expect(question.options.length, equals(3));
      expect(question.correctAnswerIndex, equals(0));
      expect(question.explanation, isNotEmpty);
    });

    test('toJson serializes Question correctly', () {
      final question = Question(
        id: 'q1',
        category: QuizCategory.tax,
        difficulty: QuizDifficulty.easy,
        question: 'Tax question?',
        options: ['Yes', 'No', 'Maybe'],
        correctAnswerIndex: 1,
        explanation: 'Tax explanation',
      );

      final json = question.toJson();

      expect(json['id'], equals('q1'));
      expect(json['category'], equals(QuizCategory.tax.index));
      expect(json['difficulty'], equals(QuizDifficulty.easy.index));
      expect(json['question'], equals('Tax question?'));
      expect(json['correctAnswerIndex'], equals(1));
    });

    test('Enum values are ordered correctly', () {
      expect(QuizCategory.savings.index, equals(0));
      expect(QuizCategory.tax.index, equals(1));
      expect(QuizCategory.invest.index, equals(2));
      expect(QuizCategory.insurance.index, equals(3));
    });
  });
}
