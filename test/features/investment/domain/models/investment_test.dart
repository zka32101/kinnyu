import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/investment/domain/models/investment.dart';

void main() {
  group('InvestmentTypeInfo', () {
    test('has 6 investment types with complete metadata', () {
      expect(InvestmentType.values.length, equals(6));
      for (final type in InvestmentType.values) {
        expect(InvestmentTypeInfo.displayNames[type], isNotNull);
        expect(InvestmentTypeInfo.displayNames[type], isNotEmpty);
        expect(InvestmentTypeInfo.descriptions[type], isNotNull);
        expect(InvestmentTypeInfo.descriptions[type], isNotEmpty);
        expect(InvestmentTypeInfo.baseIndexValues[type], isNotNull);
        expect(InvestmentTypeInfo.baseIndexValues[type], greaterThan(0));
        expect(InvestmentTypeInfo.annualGrowthRate[type], isNotNull);
      }
    });

    test('bond has the lowest annual growth rate (lowest risk)', () {
      final bondRate = InvestmentTypeInfo.annualGrowthRate[InvestmentType.bond]!;
      for (final type in InvestmentType.values) {
        if (type == InvestmentType.bond) continue;
        expect(bondRate, lessThanOrEqualTo(
            InvestmentTypeInfo.annualGrowthRate[type]!));
      }
    });
  });

  group('Investment', () {
    test('currentValue scales with index ratio', () {
      final investment = Investment(
        id: 'inv1',
        uid: 'user1',
        savingsAmount: 10000,
        investmentType: InvestmentType.sp500,
        purchaseDate: DateTime(2026, 1, 1),
        purchaseIndexValue: 5000,
      );

      expect(investment.currentValue(5000), equals(10000));
      expect(investment.currentValue(5500), equals(11000));
      expect(investment.currentValue(4500), equals(9000));
    });

    test('profitLoss reflects gain and loss correctly', () {
      final investment = Investment(
        id: 'inv1',
        uid: 'user1',
        savingsAmount: 10000,
        investmentType: InvestmentType.topix,
        purchaseDate: DateTime(2026, 1, 1),
        purchaseIndexValue: 2800,
      );

      expect(investment.profitLoss(2800), equals(0));
      expect(investment.profitLoss(3080), closeTo(1000, 0.01));
      expect(investment.profitLoss(2520), closeTo(-1000, 0.01));
    });

    test('fromJson/toJson round-trip preserves data', () {
      final original = Investment(
        id: 'inv1',
        uid: 'user1',
        savingsAmount: 5000,
        investmentType: InvestmentType.allCountry,
        purchaseDate: DateTime(2026, 3, 1),
        purchaseIndexValue: 25000,
        status: InvestmentStatus.realized,
        realizedAt: DateTime(2026, 6, 1),
        realizedIndexValue: 26000,
      );

      final json = original.toJson();
      final restored = Investment.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.investmentType, equals(InvestmentType.allCountry));
      expect(restored.status, equals(InvestmentStatus.realized));
      expect(restored.realizedIndexValue, equals(26000));
    });
  });
}
