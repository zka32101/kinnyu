import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../household/domain/models/household_expense_summary.dart';
import '../../../household/presentation/providers/household_budget_provider.dart';
import '../../../household/presentation/providers/social_contribution_provider.dart';
import '../providers/dashboard_provider.dart';

/// 統合メトリクスセクション - 独立したProvider監視
class UnifiedMetricsSection extends ConsumerWidget {
  final String groupId;

  const UnifiedMetricsSection({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // このセクションのみが savingsDashboardProvider を監視
    // 他のセクションが更新されても、このセクションは再構築されない
    final dashboardAsync = ref.watch(savingsDashboardProvider(groupId));

    return dashboardAsync.when(
      data: (dashboard) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📊 統合メトリクス',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricTile(
                      label: '今月の貯蓄',
                      value: '¥${(dashboard.totalIncome - dashboard.totalExpense).toStringAsFixed(0)}',
                      color: Colors.green,
                    ),
                    _MetricTile(
                      label: '貯蓄率',
                      value: '${((dashboard.savingsAmount / dashboard.totalIncome) * 100).toStringAsFixed(1)}%',
                      color: Colors.blue,
                    ),
                    _MetricTile(
                      label: '目標進捗',
                      value: '${(dashboard.goalProgress * 100).toStringAsFixed(0)}%',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const _SkeletonCard(),
      error: (err, st) => _ErrorCard(error: err.toString()),
    );
  }
}

/// 月間サマリーセクション - 独立したProvider監視
class MonthlySummarySection extends ConsumerWidget {
  final String groupId;
  final String month;

  const MonthlySummarySection({
    Key? key,
    required this.groupId,
    required this.month,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // このセクションのみが monthlyExpenseSummaryProvider を監視
    final summaryAsync = ref.watch(monthlyExpenseSummaryProvider(groupId, month));

    return summaryAsync.when(
      data: (summary) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💰 月間家計',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                _SummaryRow(
                  label: '収入',
                  value: '¥${summary.totalIncome.toStringAsFixed(0)}',
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  label: '支出',
                  value: '¥${summary.totalExpense.toStringAsFixed(0)}',
                  color: Colors.red,
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  label: '貯蓄',
                  value: '¥${summary.savingAmount.toStringAsFixed(0)}',
                  color: Colors.green,
                  bold: true,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const _SkeletonCard(),
      error: (err, st) => _ErrorCard(error: err.toString()),
    );
  }
}

/// カテゴリ別支出セクション - 独立したProvider監視
class CategoryBreakdownSection extends ConsumerWidget {
  final String groupId;
  final String month;

  const CategoryBreakdownSection({
    Key? key,
    required this.groupId,
    required this.month,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // このセクションのみが categoryBreakdownProvider を監視
    final breakdownAsync = ref.watch(categoryBreakdownProvider(groupId, month));

    return breakdownAsync.when(
      data: (breakdown) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📈 カテゴリ別支出',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ...breakdown.entries.map(
                  (e) => _CategoryRow(
                    category: e.key,
                    amount: e.value,
                    totalExpense: breakdown.values.fold(0, (a, b) => a + b),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const _SkeletonCard(),
      error: (err, st) => _ErrorCard(error: err.toString()),
    );
  }
}

/// 貯蓄目標セクション - 独立したProvider監視
class GoalsProgressSection extends ConsumerWidget {
  final String groupId;

  const GoalsProgressSection({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // このセクションのみが savingsGoalProvider を監視
    final goalsAsync = ref.watch(savingsGoalProvider(groupId));

    return goalsAsync.when(
      data: (goals) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎯 貯蓄目標',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ...goals.asMap().entries.map((entry) {
                  final goal = entry.value;
                  final progress = goal.currentAmount / goal.targetAmount;
                  return _GoalProgressRow(
                    goalName: goal.name,
                    current: goal.currentAmount,
                    target: goal.targetAmount,
                    progress: progress.clamp(0.0, 1.0),
                  );
                }),
              ],
            ),
          ),
        );
      },
      loading: () => const _SkeletonCard(),
      error: (err, st) => _ErrorCard(error: err.toString()),
    );
  }
}

/// 社会貢献インパクトセクション - 独立したProvider監視
class SocialImpactSection extends ConsumerWidget {
  final String groupId;

  const SocialImpactSection({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // このセクションのみが socialImpactDashboardProvider を監視
    final impactAsync = ref.watch(socialImpactDashboardProvider(groupId));

    return impactAsync.when(
      data: (impact) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🌍 社会貢献インパクト',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                _SummaryRow(
                  label: 'カーボン削減',
                  value: '${impact.totalCarbonSaved.toStringAsFixed(1)} kg CO₂',
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  label: '寄付総額',
                  value: '¥${impact.totalDonations.toStringAsFixed(0)}',
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  label: 'ESGスコア',
                  value: '${impact.averageESGScore.toStringAsFixed(0)}/100',
                  color: Colors.orange,
                  bold: true,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const _SkeletonCard(),
      error: (err, st) => _ErrorCard(error: err.toString()),
    );
  }
}

// ============================================================================
// ユーティリティウィジェット
// ============================================================================

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final int amount;
  final int totalExpense;

  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalExpense > 0 ? (amount / totalExpense) : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(category),
            Text('¥${amount.toStringAsFixed(0)}'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          minHeight: 6,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            Color.lerp(Colors.green, Colors.red, percentage)!,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _GoalProgressRow extends StatelessWidget {
  final String goalName;
  final int current;
  final int target;
  final double progress;

  const _GoalProgressRow({
    required this.goalName,
    required this.current,
    required this.target,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(goalName),
            Text('${(progress * 100).toStringAsFixed(0)}%'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 4),
        Text(
          '¥${current.toStringAsFixed(0)} / ¥${target.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 20,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Container(
              height: 100,
              color: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;

  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '⚠️ エラー',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
