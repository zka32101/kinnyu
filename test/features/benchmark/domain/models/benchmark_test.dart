import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/benchmark/domain/models/benchmark.dart';

void main() {
  group('Benchmark', () {
    test('isBelowAverage returns true when userAmount < average', () {
      final benchmark = Benchmark(
        category: BenchmarkCategory.food,
        userAmount: 40000,
        ageGroupAverage: 52000,
        ageGroupPercentile: 20,
        incomeGroupAverage: 50000,
      );

      expect(benchmark.isBelowAverage, equals(true));
    });

    test('isBelowAverage returns false when userAmount >= average', () {
      final benchmark = Benchmark(
        category: BenchmarkCategory.food,
        userAmount: 55000,
        ageGroupAverage: 52000,
        ageGroupPercentile: 60,
        incomeGroupAverage: 50000,
      );

      expect(benchmark.isBelowAverage, equals(false));
    });

    test('differenceFromAverage calculates correctly', () {
      final benchmark = Benchmark(
        category: BenchmarkCategory.utility,
        userAmount: 15000,
        ageGroupAverage: 18000,
        ageGroupPercentile: 30,
        incomeGroupAverage: 17000,
      );

      expect(benchmark.differenceFromAverage, equals(3000));
    });
  });

  group('BenchmarkStatsProvider', () {
    test('getNationalAverage returns correct values', () {
      expect(
        BenchmarkStatsProvider.getNationalAverage(BenchmarkCategory.food),
        equals(52000),
      );
      expect(
        BenchmarkStatsProvider.getNationalAverage(BenchmarkCategory.utility),
        equals(18000),
      );
      expect(
        BenchmarkStatsProvider.getNationalAverage(BenchmarkCategory.entertainment),
        equals(15000),
      );
      expect(
        BenchmarkStatsProvider.getNationalAverage(BenchmarkCategory.transport),
        equals(12000),
      );
    });

    test('calculatePercentile returns correct ranges', () {
      final average = 50000;

      // 60% of average → 10th percentile
      expect(
        BenchmarkStatsProvider.calculatePercentile(30000, BenchmarkCategory.food),
        equals(10),
      );

      // 100% of average → 40th percentile
      expect(
        BenchmarkStatsProvider.calculatePercentile(50000, BenchmarkCategory.food),
        equals(40),
      );

      // 150% of average → 80th percentile
      expect(
        BenchmarkStatsProvider.calculatePercentile(75000, BenchmarkCategory.food),
        equals(80),
      );

      // 200% of average → 90th percentile
      expect(
        BenchmarkStatsProvider.calculatePercentile(100000, BenchmarkCategory.food),
        equals(90),
      );
    });
  });
}
