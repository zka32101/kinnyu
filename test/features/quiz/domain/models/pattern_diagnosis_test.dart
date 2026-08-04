import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/quiz/domain/models/pattern_diagnosis.dart';

void main() {
  group('PatternDiagnosis serialization', () {
    test('fromJson creates a valid diagnosis', () {
      final json = {
        'patternId': '0_0_0',
        'typeName': 'ちりつも支出タイプ',
        'savingsTip1': 'Reduce convenience store visits',
        'savingsTip2': 'Track spending',
        'savingsTip3': 'Switch to cheaper mobile plan',
        'disclaimer': 'This is for educational purposes',
        'estimatedMonthlySavings': 5000,
      };

      final diagnosis = PatternDiagnosis.fromJson(json);

      expect(diagnosis.patternId, equals('0_0_0'));
      expect(diagnosis.typeName, equals('ちりつも支出タイプ'));
      expect(diagnosis.savingsTip1, isNotEmpty);
      expect(diagnosis.estimatedMonthlySavings, equals(5000));
    });

    test('fromJson defaults typeName to empty when missing', () {
      final json = {
        'patternId': '0_0_1',
        'savingsTip1': 'Tip 1',
        'savingsTip2': 'Tip 2',
        'savingsTip3': 'Tip 3',
        'disclaimer': 'Disclaimer',
        'estimatedMonthlySavings': 7000,
      };
      final diagnosis = PatternDiagnosis.fromJson(json);
      expect(diagnosis.typeName, equals(''));
    });

    test('toJson serializes correctly', () {
      final diagnosis = PatternDiagnosis(
        patternId: '0_0_1',
        typeName: 'メリハリ消費タイプ',
        savingsTip1: 'Tip 1',
        savingsTip2: 'Tip 2',
        savingsTip3: 'Tip 3',
        disclaimer: 'Disclaimer text',
        estimatedMonthlySavings: 7000,
      );

      final json = diagnosis.toJson();

      expect(json['patternId'], equals('0_0_1'));
      expect(json['typeName'], equals('メリハリ消費タイプ'));
      expect(json['savingsTip1'], equals('Tip 1'));
      expect(json['estimatedMonthlySavings'], equals(7000));
    });
  });

  group('PatternDiagnosisGenerator (new generative logic)', () {
    test('getDiagnosis returns a valid diagnosis for known pattern', () {
      final result = PatternDiagnosisGenerator.getDiagnosis('0_0_0');
      expect(result.patternId, equals('0_0_0'));
      expect(result.typeName, isNotEmpty);
      expect(result.savingsTip1, isNotEmpty);
      expect(result.disclaimer, contains('教育目的'));
    });

    test('getDiagnosis handles unknown pattern gracefully (no null)', () {
      final result = PatternDiagnosisGenerator.getDiagnosis('unknown_pattern');
      expect(result.typeName, isNotEmpty);
      expect(result.savingsTip1, isNotEmpty);
    });

    test('getRandomDiagnosis returns a valid diagnosis', () {
      final result = PatternDiagnosisGenerator.getRandomDiagnosis();
      expect(result.patternId, isNotEmpty);
      expect(result.savingsTip1, isNotEmpty);
      expect(result.disclaimer, isNotEmpty);
    });

    test('every 27 combination yields non-empty tips with disclaimer', () {
      for (var a = 0; a < 3; a++) {
        for (var b = 0; b < 3; b++) {
          for (var c = 0; c < 3; c++) {
            final d =
                PatternDiagnosisGenerator.getDiagnosis('${a}_${b}_${c}');
            expect(d.savingsTip1, isNotEmpty);
            expect(d.savingsTip2, isNotEmpty);
            expect(d.savingsTip3, isNotEmpty);
            expect(d.disclaimer, contains('教育目的'));
          }
        }
      }
    });
  });
}
