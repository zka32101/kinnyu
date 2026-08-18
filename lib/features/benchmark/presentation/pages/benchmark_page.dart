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

    return Scaffold(
      appBar: AppBar(title: const Text('支出ベンチマーク')),
      body: benchmarksAsync.when(
        data: (benchmarks) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '同年代・同年収の平均と比較しています（5人以上のグループで匿名集計）',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 16),
            ...benchmarks.map((b) => _buildBenchmarkCard(context, b)),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
        ),
      ],
    );
  }
}
