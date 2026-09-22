import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/benchmark.dart';
import '../providers/benchmark_provider.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';
import '../../../../core/analytics/analytics_provider.dart';

class BenchmarkPage extends ConsumerWidget {
  const BenchmarkPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('ログインが必要です')));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logEvent(
        'benchmark_viewed',
        parameters: {'user_id': user.uid},
      );
    });

    final benchmarksAsync = ref.watch(allBenchmarksProvider(user.uid));
    final indicatorsAsync = ref.watch(financialIndicatorBenchmarksProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('統計ベンチマーク')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '同じ年代・年収帯の目安（公表統計を参考にした近似値）と比較しています。'
              'あなたの状況に完全一致するものではなく、あくまで参考値です。',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 16),
          _buildGroupSelectors(context, ref),
          const SizedBox(height: 20),
          const Text('貯蓄率・純資産', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          indicatorsAsync.when(
            data: (indicators) => Column(
              children: indicators.map((i) => _buildIndicatorCard(i)).toList(),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('エラー: $error'),
            ),
          ),
          const SizedBox(height: 24),
          const Text('カテゴリ別支出', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          benchmarksAsync.when(
            data: (benchmarks) => Column(
              children: benchmarks.map((b) => _buildBenchmarkCard(context, b)).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('エラー: $error')),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSelectors(BuildContext context, WidgetRef ref) {
    final ageGroup = ref.watch(benchmarkAgeGroupProvider);
    final incomeGroup = ref.watch(benchmarkIncomeGroupProvider);

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<AgeGroup>(
            value: ageGroup,
            decoration: const InputDecoration(
              labelText: '年代',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: AgeGroup.values
                .map((g) => DropdownMenuItem(value: g, child: Text(g.displayName)))
                .toList(),
            onChanged: (v) => ref.read(benchmarkAgeGroupProvider.notifier).select(v!),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<IncomeGroup>(
            value: incomeGroup,
            decoration: const InputDecoration(
              labelText: '世帯年収',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: IncomeGroup.values
                .map((g) => DropdownMenuItem(value: g, child: Text(g.displayName)))
                .toList(),
            onChanged: (v) => ref.read(benchmarkIncomeGroupProvider.notifier).select(v!),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicatorCard(FinancialIndicatorBenchmark indicator) {
    final isGood = indicator.isAboveAverage;
    final displayUserValue = indicator.unit == '%'
        ? '${indicator.userValue.toStringAsFixed(1)}%'
        : '¥${indicator.userValue.toStringAsFixed(0)}';
    final displayAverage = indicator.unit == '%'
        ? '${indicator.ageGroupAverage.toStringAsFixed(1)}%'
        : '¥${indicator.ageGroupAverage.toStringAsFixed(0)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(indicator.indicatorName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isGood ? Colors.green : Colors.orange).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '同世代内で上位${100 - indicator.ageGroupPercentile}%',
                    style: TextStyle(
                      color: isGood ? Colors.green.shade800 : Colors.orange.shade800,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('あなた', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(displayUserValue,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isGood ? Colors.green : Colors.orange)),
                  ],
                ),
                const Icon(Icons.compare_arrows, color: Colors.grey),
                Column(
                  children: [
                    const Text('同世代平均', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(displayAverage,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenchmarkCard(BuildContext context, Benchmark benchmark) {
    final isGood = benchmark.isBelowAverage;
    final progressValue = benchmark.ageGroupAverage > 0
        ? (benchmark.userAmount / (benchmark.ageGroupAverage * 1.5))
            .clamp(0.0, 1.0)
        : 0.0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  BenchmarkCategoryInfo.displayNames[benchmark.category]!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (isGood)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '下位${benchmark.ageGroupPercentile}%（節約上手！）',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAmountColumn('あなた', benchmark.userAmount, isGood ? Colors.green : Colors.red),
                const Icon(Icons.compare_arrows, color: Colors.grey),
                _buildAmountColumn('同年代平均', benchmark.ageGroupAverage, Colors.grey),
                _buildAmountColumn('同年収帯平均', benchmark.incomeGroupAverage, Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.grey.shade200,
              color: isGood ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountColumn(String label, int amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          '¥$amount',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
        ),
      ],
    );
  }
}
