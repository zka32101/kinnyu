import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ダッシュボードプレビューカード - ホームページに表示される統合メトリクス
class DashboardPreviewCard extends ConsumerWidget {
  final VoidCallback? onTap;

  const DashboardPreviewCard({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal[100]!, Colors.green[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal[200]!),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '📊 家計ダッシュボード',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward, color: Colors.teal[700]),
              ],
            ),
            const SizedBox(height: 12),

            // メトリクス行
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetric(
                  context,
                  label: '月間貯蓄',
                  value: '¥45,000',
                  icon: '💰',
                ),
                _buildMetric(
                  context,
                  label: '貯蓄率',
                  value: '12.9%',
                  icon: '📈',
                ),
                _buildMetric(
                  context,
                  label: 'CO2削減',
                  value: '2.5kg',
                  icon: '🌍',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '家計全体の状況をまとめて確認しよう',
              style: theme.textTheme.caption?.copyWith(
                color: Colors.teal[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(
    BuildContext context, {
    required String label,
    required String value,
    required String icon,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.teal[900],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.caption?.copyWith(
            fontSize: 10,
            color: Colors.teal[700],
          ),
        ),
      ],
    );
  }
}
