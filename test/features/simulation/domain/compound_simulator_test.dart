import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/simulation/domain/models/compound_simulator.dart';

void main() {
  group('CompoundSimulator', () {
    test('returns one result per year', () {
      final results = CompoundSimulator.simulate(
        monthlyContribution: 10000,
        annualRatePercent: 5,
        years: 10,
      );
      expect(results.length, equals(10));
      expect(results.first.year, equals(1));
      expect(results.last.year, equals(10));
    });

    test('principal accumulates exactly as contributions (0% rate)', () {
      final results = CompoundSimulator.simulate(
        monthlyContribution: 10000,
        annualRatePercent: 0,
        years: 5,
      );
      expect(results.last.principal, equals(10000 * 12 * 5));
      // 0%なら運用益は出ない
      expect(results.last.balance, closeTo(results.last.principal.toDouble(), 0.01));
      expect(results.last.profit, closeTo(0, 0.01));
    });

    test('balance grows faster than principal with positive rate', () {
      final results = CompoundSimulator.simulate(
        monthlyContribution: 10000,
        annualRatePercent: 5,
        years: 10,
      );
      expect(results.last.balance, greaterThan(results.last.principal.toDouble()));
      expect(results.last.profit, greaterThan(0));
    });

    test('balance is monotonically increasing across years', () {
      final results = CompoundSimulator.simulate(
        monthlyContribution: 5000,
        annualRatePercent: 3,
        years: 20,
      );
      for (var i = 1; i < results.length; i++) {
        expect(results[i].balance, greaterThan(results[i - 1].balance));
      }
    });

    test('initial lump sum is included in principal and grows', () {
      final results = CompoundSimulator.simulate(
        initial: 1000000,
        monthlyContribution: 0,
        annualRatePercent: 5,
        years: 10,
      );
      expect(results.last.principal, equals(1000000));
      expect(results.last.balance, greaterThan(1000000));
    });

    test('higher rate produces higher final balance for same contributions', () {
      final low = CompoundSimulator.simulate(
        monthlyContribution: 10000,
        annualRatePercent: 2,
        years: 15,
      );
      final high = CompoundSimulator.simulate(
        monthlyContribution: 10000,
        annualRatePercent: 8,
        years: 15,
      );
      expect(high.last.balance, greaterThan(low.last.balance));
    });
  });

  group('CompoundSimulator.simulateRandom', () {
    test('returns one result per year with a return% attached', () {
      final results = CompoundSimulator.simulateRandom(
        monthlyContribution: 10000,
        meanAnnualRatePercent: 6,
        volatilityPercent: 16,
        years: 15,
        seed: 42,
      );
      expect(results.length, equals(15));
      for (final r in results) {
        expect(r.annualReturnPercent, greaterThanOrEqualTo(-60));
        expect(r.annualReturnPercent, lessThanOrEqualTo(150));
      }
    });

    test('same seed produces identical results (reproducible)', () {
      final a = CompoundSimulator.simulateRandom(
        monthlyContribution: 20000,
        meanAnnualRatePercent: 7,
        volatilityPercent: 18,
        years: 20,
        seed: 123,
      );
      final b = CompoundSimulator.simulateRandom(
        monthlyContribution: 20000,
        meanAnnualRatePercent: 7,
        volatilityPercent: 18,
        years: 20,
        seed: 123,
      );
      for (var i = 0; i < a.length; i++) {
        expect(a[i].balance, equals(b[i].balance));
        expect(a[i].annualReturnPercent, equals(b[i].annualReturnPercent));
      }
    });

    test('different seeds produce different return sequences', () {
      final a = CompoundSimulator.simulateRandom(
        monthlyContribution: 20000,
        meanAnnualRatePercent: 7,
        volatilityPercent: 18,
        years: 20,
        seed: 1,
      );
      final b = CompoundSimulator.simulateRandom(
        monthlyContribution: 20000,
        meanAnnualRatePercent: 7,
        volatilityPercent: 18,
        years: 20,
        seed: 2,
      );
      final anyDifferent = List.generate(a.length, (i) => i)
          .any((i) => a[i].annualReturnPercent != b[i].annualReturnPercent);
      expect(anyDifferent, isTrue);
    });

    test('includes both up and down years over a long horizon (realistic volatility)', () {
      final results = CompoundSimulator.simulateRandom(
        monthlyContribution: 10000,
        meanAnnualRatePercent: 6,
        volatilityPercent: 18,
        years: 40,
        seed: 7,
      );
      final hasDownYear = results.any((r) => r.annualReturnPercent < 0);
      final hasUpYear = results.any((r) => r.annualReturnPercent > 0);
      expect(hasDownYear, isTrue,
          reason: '長期間シミュレーションすればマイナスの年が現実的に出現するはず');
      expect(hasUpYear, isTrue);
    });

    test('principal accumulation matches deterministic simulate regardless of randomness', () {
      final results = CompoundSimulator.simulateRandom(
        monthlyContribution: 15000,
        meanAnnualRatePercent: 5,
        volatilityPercent: 20,
        years: 10,
        seed: 99,
      );
      expect(results.last.principal, equals(15000 * 12 * 10));
    });

    test('zero volatility behaves like the deterministic simulator', () {
      final random = CompoundSimulator.simulateRandom(
        monthlyContribution: 10000,
        meanAnnualRatePercent: 5,
        volatilityPercent: 0,
        years: 10,
        seed: 1,
      );
      final deterministic = CompoundSimulator.simulate(
        monthlyContribution: 10000,
        annualRatePercent: 5,
        years: 10,
      );
      for (var i = 0; i < random.length; i++) {
        expect(random[i].balance, closeTo(deterministic[i].balance, 0.01));
      }
    });
  });
}
