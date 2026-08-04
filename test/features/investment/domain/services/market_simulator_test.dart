import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/investment/domain/models/investment.dart';
import 'package:okane_kore/features/investment/domain/services/market_simulator.dart';

void main() {
  group('MarketSimulator', () {
    test('getCurrentIndexValue returns consistent value for same date', () {
      final date1 = DateTime(2026, 3, 15);
      final value1 = MarketSimulator.getCurrentIndexValue(
        InvestmentType.topix,
        asOf: date1,
      );
      final value2 = MarketSimulator.getCurrentIndexValue(
        InvestmentType.topix,
        asOf: date1,
      );

      expect(value1, equals(value2));
    });

    test('getCurrentIndexValue varies for different dates', () {
      final date1 = DateTime(2026, 3, 15);
      final date2 = DateTime(2026, 3, 16);

      final value1 = MarketSimulator.getCurrentIndexValue(
        InvestmentType.topix,
        asOf: date1,
      );
      final value2 = MarketSimulator.getCurrentIndexValue(
        InvestmentType.topix,
        asOf: date2,
      );

      expect(value1, isNotNull);
      expect(value2, isNotNull);
      // Values should differ due to daily noise
      expect(value1, isNot(equals(value2)));
    });

    test('different investment types have different base values', () {
      final date = DateTime(2026, 3, 15);
      final topixValue =
          MarketSimulator.getCurrentIndexValue(InvestmentType.topix, asOf: date);
      final nasdaqValue = MarketSimulator.getCurrentIndexValue(
        InvestmentType.nasdaq,
        asOf: date,
      );

      expect(topixValue, isNotNull);
      expect(nasdaqValue, isNotNull);
      // TOPIX ~2800, NASDAQ ~16000, so they should differ significantly
      expect((nasdaqValue - topixValue).abs(), greaterThan(1000));
    });

    test('getHistorySeries returns correct number of values', () {
      final series = MarketSimulator.getHistorySeries(
        InvestmentType.topix,
        days: 30,
      );

      expect(series.length, equals(30));
    });

    test('getHistorySeries values are positive', () {
      final series = MarketSimulator.getHistorySeries(
        InvestmentType.topix,
        days: 10,
      );

      for (final value in series) {
        expect(value, isPositive);
      }
    });

    test('base index values are defined for all investment types', () {
      expect(
        InvestmentTypeInfo.baseIndexValues[InvestmentType.topix],
        equals(2800.0),
      );
      expect(
        InvestmentTypeInfo.baseIndexValues[InvestmentType.nasdaq],
        equals(16000.0),
      );
      expect(
        InvestmentTypeInfo.baseIndexValues[InvestmentType.sp500],
        equals(5500.0),
      );
    });

    test('annual growth rates are reasonable', () {
      final rates = InvestmentTypeInfo.annualGrowthRate;
      expect(rates[InvestmentType.topix], equals(0.05)); // 5%
      expect(rates[InvestmentType.nasdaq], equals(0.09)); // 9%
      expect(rates[InvestmentType.sp500], equals(0.07)); // 7%
    });
  });
}
