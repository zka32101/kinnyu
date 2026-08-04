import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/simulation/domain/models/household_simulator.dart';

void main() {
  group('HouseholdSimulator', () {
    test('computes monthly savings and positive savings rate', () {
      final result = HouseholdSimulator.simulate(
        const HouseholdSimulationInput(
          monthlyIncome: 300000,
          monthlyExpense: 220000,
          years: 10,
        ),
      );

      expect(result.monthlySavings, equals(80000));
      expect(result.isDeficit, isFalse);
      expect(result.savingsRate, closeTo(80000 / 300000, 0.0001));
      expect(result.projection.length, equals(10));
    });

    test('detects deficit when expense exceeds income', () {
      final result = HouseholdSimulator.simulate(
        const HouseholdSimulationInput(
          monthlyIncome: 200000,
          monthlyExpense: 250000,
          years: 5,
        ),
      );

      expect(result.monthlySavings, equals(-50000));
      expect(result.isDeficit, isTrue);
      expect(result.savingsRate, lessThan(0));
      // 赤字の場合、積立は0として扱われ資産は増えない
      expect(result.projection.last.principal, equals(0));
    });

    test('projection reflects investment return when specified', () {
      final noReturn = HouseholdSimulator.simulate(
        const HouseholdSimulationInput(
          monthlyIncome: 300000,
          monthlyExpense: 250000,
          investmentReturnPercent: 0,
          years: 10,
        ),
      );
      final withReturn = HouseholdSimulator.simulate(
        const HouseholdSimulationInput(
          monthlyIncome: 300000,
          monthlyExpense: 250000,
          investmentReturnPercent: 5,
          years: 10,
        ),
      );

      expect(withReturn.projection.last.balance,
          greaterThan(noReturn.projection.last.balance));
      // 元本は運用有無に関わらず同じ
      expect(withReturn.projection.last.principal,
          equals(noReturn.projection.last.principal));
    });

    test('zero income does not throw and yields zero rate', () {
      final result = HouseholdSimulator.simulate(
        const HouseholdSimulationInput(
          monthlyIncome: 0,
          monthlyExpense: 0,
          years: 1,
        ),
      );
      expect(result.savingsRate, equals(0.0));
      expect(result.isDeficit, isFalse);
    });
  });

  group('YearlyPlan', () {
    test('monthlySavings and isDeficit are derived correctly', () {
      const plan = YearlyPlan(year: 1, monthlyIncome: 300000, monthlyExpense: 350000);
      expect(plan.monthlySavings, equals(-50000));
      expect(plan.isDeficit, isTrue);
    });

    test('copyWith updates only specified fields', () {
      const plan = YearlyPlan(year: 3, monthlyIncome: 300000, monthlyExpense: 200000);
      final updated = plan.copyWith(monthlyIncome: 350000);
      expect(updated.year, equals(3));
      expect(updated.monthlyIncome, equals(350000));
      expect(updated.monthlyExpense, equals(200000));
    });
  });

  group('HouseholdSimulator.simulateDetailed', () {
    test('returns one result per plan year in order', () {
      final plans = [
        const YearlyPlan(year: 1, monthlyIncome: 250000, monthlyExpense: 200000),
        const YearlyPlan(year: 2, monthlyIncome: 280000, monthlyExpense: 210000),
        const YearlyPlan(year: 3, monthlyIncome: 300000, monthlyExpense: 220000),
      ];
      final results = HouseholdSimulator.simulateDetailed(plans: plans);

      expect(results.length, equals(3));
      expect(results.map((r) => r.year).toList(), equals([1, 2, 3]));
    });

    test('reflects a raise (income increase) in a later year', () {
      final plans = [
        const YearlyPlan(year: 1, monthlyIncome: 250000, monthlyExpense: 200000),
        const YearlyPlan(year: 2, monthlyIncome: 400000, monthlyExpense: 200000), // 昇給
      ];
      final results = HouseholdSimulator.simulateDetailed(plans: plans);

      expect(results[0].monthlySavings, equals(50000));
      expect(results[1].monthlySavings, equals(200000));
      // 昇給後は元本の増え方が加速する
      final growthYear1 = results[0].principal;
      final growthYear2 = results[1].principal - growthYear1;
      expect(growthYear2, greaterThan(growthYear1));
    });

    test('deficit year does not reduce accumulated principal', () {
      final plans = [
        const YearlyPlan(year: 1, monthlyIncome: 300000, monthlyExpense: 200000),
        const YearlyPlan(year: 2, monthlyIncome: 200000, monthlyExpense: 300000), // 赤字（例: 転職）
      ];
      final results = HouseholdSimulator.simulateDetailed(plans: plans);

      expect(results[1].isDeficit, isTrue);
      // 赤字年は積み立てられないが、既存の元本は減らない
      expect(results[1].principal, equals(results[0].principal));
    });

    test('applies investment growth across years cumulatively', () {
      final plans = List.generate(
        10,
        (i) => YearlyPlan(year: i + 1, monthlyIncome: 300000, monthlyExpense: 250000),
      );
      final noGrowth =
          HouseholdSimulator.simulateDetailed(plans: plans, investmentReturnPercent: 0);
      final withGrowth =
          HouseholdSimulator.simulateDetailed(plans: plans, investmentReturnPercent: 5);

      expect(withGrowth.last.balance, greaterThan(noGrowth.last.balance));
      expect(withGrowth.last.principal, equals(noGrowth.last.principal));
    });
  });

  group('HouseholdSimulator.expandToYearlyPlans', () {
    test('creates one identical plan per year from simple input', () {
      const input = HouseholdSimulationInput(
        monthlyIncome: 300000,
        monthlyExpense: 220000,
        years: 5,
      );
      final plans = HouseholdSimulator.expandToYearlyPlans(input);

      expect(plans.length, equals(5));
      for (var i = 0; i < plans.length; i++) {
        expect(plans[i].year, equals(i + 1));
        expect(plans[i].monthlyIncome, equals(300000));
        expect(plans[i].monthlyExpense, equals(220000));
      }
    });

    test('expanded plans produce the same result as simple simulate', () {
      const input = HouseholdSimulationInput(
        monthlyIncome: 300000,
        monthlyExpense: 220000,
        investmentReturnPercent: 4,
        years: 8,
      );
      final simple = HouseholdSimulator.simulate(input);
      final plans = HouseholdSimulator.expandToYearlyPlans(input);
      final detailed = HouseholdSimulator.simulateDetailed(
        plans: plans,
        investmentReturnPercent: input.investmentReturnPercent,
      );

      expect(detailed.last.balance, closeTo(simple.projection.last.balance, 0.01));
      expect(detailed.last.principal, equals(simple.projection.last.principal));
    });
  });
}
