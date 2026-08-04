import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/roleplay/domain/models/roleplay_scenario.dart';

void main() {
  group('RoleplayScenarios', () {
    final scenarios = RoleplayScenarios.all();

    test('has all 3 scenario types', () {
      expect(scenarios.length, equals(3));
      final types = scenarios.map((s) => s.type).toSet();
      expect(types, containsAll(RoleplayScenarioType.values));
    });

    test('byType returns matching scenario for each type', () {
      for (final type in RoleplayScenarioType.values) {
        expect(RoleplayScenarios.byType(type).type, equals(type));
      }
    });

    test('every scenario has at least 3 decisions', () {
      for (final s in scenarios) {
        expect(s.decisions.length, greaterThanOrEqualTo(3),
            reason: '${s.title}: 判断が不足');
      }
    });

    test('every decision has matching options and scoreDeltas length', () {
      for (final s in scenarios) {
        for (final d in s.decisions) {
          expect(d.options.length, equals(d.scoreDeltas.length),
              reason: '${s.title}: 選択肢とスコアの数が不一致 -> ${d.question}');
        }
      }
    });

    test('every decision has at least 2 options', () {
      for (final s in scenarios) {
        for (final d in s.decisions) {
          expect(d.options.length, greaterThanOrEqualTo(2),
              reason: '${s.title}: 選択肢が不足');
        }
      }
    });

    test('every decision has non-empty question and explanation', () {
      for (final s in scenarios) {
        for (final d in s.decisions) {
          expect(d.question.trim(), isNotEmpty);
          expect(d.explanation?.trim() ?? '', isNotEmpty,
              reason: '${s.title}: 解説が空 -> ${d.question}');
        }
      }
    });

    test('each scenario has a positive best-choice score', () {
      for (final s in scenarios) {
        for (final d in s.decisions) {
          final best = d.scoreDeltas.reduce((a, b) => a > b ? a : b);
          expect(best, greaterThan(0),
              reason: '${s.title}: 最善手が加点でない -> ${d.question}');
        }
      }
    });
  });
}
