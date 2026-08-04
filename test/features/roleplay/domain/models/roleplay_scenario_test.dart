import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/roleplay/domain/models/roleplay_scenario.dart';

void main() {
  group('RoleplayResult', () {
    test('fromJson creates a valid result', () {
      final now = DateTime.now();
      final json = {
        'scenario': 0, // RoleplayScenarioType.youngFamily
        'selectedAnswers': [0, 1, 2],
        'score': 25,
        'createdAt': now.toIso8601String(),
      };

      final result = RoleplayResult.fromJson(json);

      expect(result.scenario, equals(RoleplayScenarioType.youngFamily));
      expect(result.selectedAnswers.length, equals(3));
      expect(result.score, equals(25));
    });

    test('toJson serializes correctly', () {
      final now = DateTime.now();
      final result = RoleplayResult(
        scenario: RoleplayScenarioType.youngFamily,
        selectedAnswers: [1, 0, 2],
        score: 20,
        createdAt: now,
      );

      final json = result.toJson();

      expect(json['scenario'], equals(0));
      expect(json['selectedAnswers'], equals([1, 0, 2]));
      expect(json['score'], equals(20));
    });
  });

  group('RoleplayDecision', () {
    test('creates a valid decision with correct fields', () {
      final decision = RoleplayDecision(
        question: 'What to do?',
        options: ['Option A', 'Option B', 'Option C'],
        scoreDeltas: [10, 5, 0],
        explanation: 'This is the explanation',
      );

      expect(decision.question, equals('What to do?'));
      expect(decision.options.length, equals(3));
      expect(decision.scoreDeltas.length, equals(3));
      expect(decision.explanation, isNotEmpty);
    });
  });

  group('RoleplayScenario', () {
    test('youngFamily scenario has correct properties', () {
      final scenario = RoleplayScenarios.youngFamily();

      expect(scenario.type, equals(RoleplayScenarioType.youngFamily));
      expect(scenario.title, isNotEmpty);
      expect(scenario.description, isNotEmpty);
      expect(scenario.annualIncome, equals(4000000));
      expect(scenario.decisions.length, greaterThanOrEqualTo(3));
    });

    test('all decisions have matching options and scoreDeltas', () {
      final scenario = RoleplayScenarios.youngFamily();

      for (final decision in scenario.decisions) {
        expect(decision.options.length, equals(decision.scoreDeltas.length));
      }
    });

    test('every decision has at least one positive (best) choice', () {
      final scenario = RoleplayScenarios.youngFamily();

      for (final decision in scenario.decisions) {
        final best = decision.scoreDeltas.reduce((a, b) => a > b ? a : b);
        expect(best, greaterThan(0));
      }
    });
  });
}
