import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/benchmark_service.dart';
import '../../domain/models/benchmark.dart';
import '../../../household/presentation/providers/household_balance_sheet_provider.dart';

final benchmarkServiceProvider = Provider((ref) {
  return BenchmarkService();
});

/// ベンチマーク比較の対象とする年代（デフォルト30代）
class BenchmarkAgeGroupNotifier extends Notifier<AgeGroup> {
  @override
  AgeGroup build() => AgeGroup.thirties;

  void select(AgeGroup ageGroup) => state = ageGroup;
}

final benchmarkAgeGroupProvider =
    NotifierProvider<BenchmarkAgeGroupNotifier, AgeGroup>(
        BenchmarkAgeGroupNotifier.new);

/// ベンチマーク比較の対象とする世帯年収帯（デフォルト500〜700万円）
class BenchmarkIncomeGroupNotifier extends Notifier<IncomeGroup> {
  @override
  IncomeGroup build() => IncomeGroup.m5to7;

  void select(IncomeGroup incomeGroup) => state = incomeGroup;
}

final benchmarkIncomeGroupProvider =
    NotifierProvider<BenchmarkIncomeGroupNotifier, IncomeGroup>(
        BenchmarkIncomeGroupNotifier.new);

final allBenchmarksProvider =
    FutureProvider.family<List<Benchmark>, String>((ref, uid) async {
  final service = ref.watch(benchmarkServiceProvider);
  final ageGroup = ref.watch(benchmarkAgeGroupProvider);
  final incomeGroup = ref.watch(benchmarkIncomeGroupProvider);
  return service.getAllBenchmarks(uid, ageGroup: ageGroup, incomeGroup: incomeGroup);
});

/// 貯蓄率・純資産の同世代比較
/// NOTE: 家計のバランスシートはgroupId単位で管理されているため、
/// 個人単位のuidをgroupIdとして代用する（household機能の他プロバイダーと同様の暫定対応）。
final financialIndicatorBenchmarksProvider =
    FutureProvider.autoDispose.family<List<FinancialIndicatorBenchmark>, String>(
  (ref, uid) async {
    final ageGroup = ref.watch(benchmarkAgeGroupProvider);
    final summary = await ref.watch(simpleBalanceSummaryProvider(uid).future);
    final balanceSheet = await ref.watch(householdBalanceSheetProvider(uid).future);

    final savingsRateAverage = BenchmarkStatsProvider.savingsRateByAgeGroup[ageGroup] ?? 0;
    final netWorthAverage = BenchmarkStatsProvider.netWorthByAgeGroup[ageGroup] ?? 0;

    return [
      FinancialIndicatorBenchmark(
        indicatorName: '貯蓄率',
        userValue: summary.savingsRate,
        ageGroupAverage: savingsRateAverage,
        ageGroupPercentile: BenchmarkStatsProvider.calculatePercentileForHigherIsBetter(
          summary.savingsRate,
          savingsRateAverage,
        ),
        unit: '%',
      ),
      FinancialIndicatorBenchmark(
        indicatorName: '純資産',
        userValue: balanceSheet.netWorth.toDouble(),
        ageGroupAverage: netWorthAverage.toDouble(),
        ageGroupPercentile: BenchmarkStatsProvider.calculatePercentileForHigherIsBetter(
          balanceSheet.netWorth.toDouble(),
          netWorthAverage.toDouble(),
        ),
        unit: '円',
      ),
    ];
  },
);
