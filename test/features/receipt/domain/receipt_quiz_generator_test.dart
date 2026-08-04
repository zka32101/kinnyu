import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/receipt/domain/models/receipt.dart';
import 'package:okane_kore/features/receipt/domain/models/receipt_quiz_generator.dart';

void main() {
  Receipt makeReceipt(String id, int amount, ReceiptCategory cat) => Receipt(
        id: id,
        uid: 'u1',
        date: DateTime(2026, 3, 1),
        category: cat,
        amount: amount,
        createdAt: DateTime(2026, 3, 1),
      );

  group('ReceiptQuizGenerator', () {
    test('generate returns a valid quiz with 4 options', () {
      final r = makeReceipt('r1', 500, ReceiptCategory.convenience);
      final q = ReceiptQuizGenerator.generate(r);

      expect(q.options.length, equals(4));
      expect(q.correctAnswerIndex, greaterThanOrEqualTo(0));
      expect(q.correctAnswerIndex, lessThan(q.options.length));
      expect(q.question, isNotEmpty);
      expect(q.explanation, isNotEmpty);
    });

    test('generate is deterministic for the same receipt id', () {
      final r = makeReceipt('same_id', 800, ReceiptCategory.dining);
      final q1 = ReceiptQuizGenerator.generate(r);
      final q2 = ReceiptQuizGenerator.generate(r);
      expect(q1.id, equals(q2.id));
    });

    test('annual quiz computes 52-week total correctly', () {
      final r = makeReceipt('r_annual', 300, ReceiptCategory.convenience);
      final q = ReceiptQuizGenerator.generateAnnualQuiz(r);
      final correct = q.options[q.correctAnswerIndex];
      expect(correct, equals('¥${300 * 52}'));
    });

    test('investment quiz correct answer is the largest (compound growth)', () {
      final r = makeReceipt('r_inv', 1000, ReceiptCategory.other);
      final q = ReceiptQuizGenerator.generateInvestmentQuiz(r);
      // 10年複利(5%)は元本より必ず大きい
      final correct = q.options[q.correctAnswerIndex];
      final value = int.parse(correct.replaceAll('¥', ''));
      expect(value, greaterThan(1000));
    });

    test('all quiz variants produce distinct, non-empty explanations', () {
      final r = makeReceipt('r_all', 600, ReceiptCategory.grocery);
      final inv = ReceiptQuizGenerator.generateInvestmentQuiz(r);
      final annual = ReceiptQuizGenerator.generateAnnualQuiz(r);
      final compound = ReceiptQuizGenerator.generateCompoundQuiz(r);
      for (final q in [inv, annual, compound]) {
        expect(q.explanation.trim(), isNotEmpty);
        expect(q.options.toSet().length, equals(q.options.length),
            reason: '選択肢に重複あり: ${q.id}');
      }
    });
  });
}
