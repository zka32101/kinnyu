import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/simulation/domain/models/investment_simulation_pattern.dart';

void main() {
  group('InvestmentSimulationPatterns', () {
    test('has a good variety of patterns', () {
      expect(InvestmentSimulationPatterns.patterns.length, greaterThanOrEqualTo(6));
    });

    test('all pattern IDs are unique', () {
      final ids = InvestmentSimulationPatterns.patterns.map((p) => p.id).toSet();
      expect(ids.length, equals(InvestmentSimulationPatterns.patterns.length));
    });

    test('every pattern has valid positive fields', () {
      for (final p in InvestmentSimulationPatterns.patterns) {
        expect(p.title.trim(), isNotEmpty);
        expect(p.description.trim(), isNotEmpty);
        expect(p.monthlyAmount, greaterThan(0));
        expect(p.years, greaterThan(0));
        expect(p.years, lessThanOrEqualTo(40));
      }
    });

    test('covers more than one investment type across patterns', () {
      final types = InvestmentSimulationPatterns.patterns.map((p) => p.investmentType).toSet();
      expect(types.length, greaterThan(1));
    });
  });
}
