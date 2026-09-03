import 'package:flutter/material.dart';

/// 月間財務概要カード - 収入・支出・貯蓄の概要表示
class MonthlySummaryCard extends StatelessWidget {
  final int income;
  final int expenses;
  final int savings;
  final double savingsRate;

  const MonthlySummaryCard({
    Key? key,
    required this.income,
    required this.expenses,
    required this.savings,
    required this.savingsRate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📈 今月の家計',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 収入・支出・貯蓄行
            _buildSummaryRow(
              context,
              icon: '📥',
              label: '収入',
              amount: income,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              context,
              icon: '📤',
              label: '支出',
              amount: expenses,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              context,
              icon: '💵',
              label: '貯蓄',
              amount: savings,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),

            // 貯蓄率
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '貯蓄率',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${(savingsRate * 100).toStringAsFixed(1)}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 進捗バー
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: savingsRate.clamp(0, 1).toDouble(),
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  savingsRate >= 0.20
                      ? Colors.green
                      : savingsRate >= 0.10
                          ? Colors.blue
                          : Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              savingsRate >= 0.20
                  ? '優秀な貯蓄率です！'
                  : savingsRate >= 0.10
                      ? '良好な貯蓄ペースです'
                      : '目標貯蓄率: 20%を目指そう',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required String icon,
    required String label,
    required int amount,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          '¥${amount.toString()}',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
