import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/quiz/domain/models/pattern_diagnosis.dart';
import 'package:okane_kore/features/quiz/domain/models/diagnosis_question.dart';

void main() {
  group('DiagnosisQuestions', () {
    test('has 3 questions each with 3 options', () {
      expect(DiagnosisQuestions.questions.length, equals(3));
      for (final q in DiagnosisQuestions.questions) {
        expect(q.options.length, equals(3), reason: '${q.id}: 選択肢が3つでない');
        expect(q.question.trim(), isNotEmpty);
      }
    });

    test('all question IDs are unique', () {
      final ids = DiagnosisQuestions.questions.map((q) => q.id).toSet();
      expect(ids.length, equals(DiagnosisQuestions.questions.length));
    });
  });

  group('PatternDiagnosisGenerator', () {
    test('generates a valid diagnosis for all 27 combinations', () {
      for (var a = 0; a < 3; a++) {
        for (var b = 0; b < 3; b++) {
          for (var c = 0; c < 3; c++) {
            final id = '$a_$b_$c';
            final d = PatternDiagnosisGenerator.getDiagnosis(id);
            expect(d.typeName, isNotEmpty, reason: '$id: タイプ名が空');
            expect(d.savingsTip1, isNotEmpty, reason: '$id: tip1 が空');
            expect(d.savingsTip2, isNotEmpty, reason: '$id: tip2 が空');
            expect(d.savingsTip3, isNotEmpty, reason: '$id: tip3 が空');
            expect(d.estimatedMonthlySavings, greaterThan(0));
            expect(d.disclaimer, isNotEmpty);
          }
        }
      }
    });

    test('typeName reflects the first answer (spending habit)', () {
      final d0 = PatternDiagnosisGenerator.getDiagnosis('0_0_0');
      final d1 = PatternDiagnosisGenerator.getDiagnosis('1_0_0');
      final d2 = PatternDiagnosisGenerator.getDiagnosis('2_0_0');
      expect(d0.typeName, isNot(equals(d1.typeName)));
      expect(d1.typeName, isNot(equals(d2.typeName)));
    });

    test('handles malformed pattern IDs gracefully', () {
      final d = PatternDiagnosisGenerator.getDiagnosis('invalid');
      expect(d.typeName, isNotEmpty);
      final d2 = PatternDiagnosisGenerator.getDiagnosis('9_9_9');
      expect(d2.typeName, isNotEmpty);
    });

    test('getRandomDiagnosis returns a valid diagnosis', () {
      final d = PatternDiagnosisGenerator.getRandomDiagnosis();
      expect(d.typeName, isNotEmpty);
      expect(d.estimatedMonthlySavings, greaterThan(0));
    });

    test('every diagnosis has a non-empty imageAsset path', () {
      for (var a = 0; a < 3; a++) {
        for (var b = 0; b < 3; b++) {
          for (var c = 0; c < 3; c++) {
            final d = PatternDiagnosisGenerator.getDiagnosis('${a}_${b}_${c}');
            expect(d.imageAsset, isNotEmpty);
            expect(d.imageAsset, startsWith('assets/images/diagnosis/'));
          }
        }
      }
    });

    test('imageAsset depends only on the first answer (spending habit)', () {
      final d1 = PatternDiagnosisGenerator.getDiagnosis('0_0_0');
      final d2 = PatternDiagnosisGenerator.getDiagnosis('0_1_2');
      expect(d1.imageAsset, equals(d2.imageAsset));

      final d3 = PatternDiagnosisGenerator.getDiagnosis('1_0_0');
      expect(d1.imageAsset, isNot(equals(d3.imageAsset)));
    });
  });
}
