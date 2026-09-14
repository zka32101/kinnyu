import 'package:flutter/material.dart';
import '../../domain/models/household_balance_sheet.dart';

/// 簡易バランスカード - 当月の収支概要を表示
class SimpleBalanceCard extends StatelessWidget {
  final SimpleBalanceSummary summary;

  const SimpleBalanceCard({
    Key? key,
    required this.summary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 貯蓄率に基づいてステータスを決定
    late final String statusEmoji;
    late final Color statusColor;

    if (summary.savingsRate >= 30) {
      statusEmoji = '✅';
      statusColor = Colors.green;
    } else if (summary.savingsRate >= 15) {
      statusEmoji = '⚠️';
      statusColor = Colors.orange;
    } else {
      statusEmoji = '❌';
      statusColor = Colors.red;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '💰 簡易バランス',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  statusEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 収入
            _BalanceRow(
              label: '月間収入',
              value: '¥${summary.monthlyIncome}',
              color: Colors.green,
            ),
            const SizedBox(height: 12),

            // 支出
            _BalanceRow(
              label: '月間支出',
              value: '¥${summary.monthlyExpense}',
              color: Colors.red,
            ),
            const SizedBox(height: 12),

            // 貯蓄
            _BalanceRow(
              label: '月間貯蓄',
              value: '¥${summary.monthlySavings}',
              color: Colors.blue,
              bold: true,
            ),
            const SizedBox(height: 16),

            // 貯蓄率インジケータ
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '貯蓄率',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${summary.savingsRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (summary.savingsRate / 50).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ステータス説明
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getStatusMessage(summary.savingsRate),
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusMessage(double savingsRate) {
    if (savingsRate >= 30) {
      return '優秀です！貯蓄率${savingsRate.toStringAsFixed(1)}%で、財務状況が良好です。';
    } else if (savingsRate >= 15) {
      return '良好な貯蓄率です。さらに改善を目指しましょう。';
    } else {
      return '貯蓄率が低いです。支出の見直しを検討してください。';
    }
  }
}

/// バランス行
class _BalanceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _BalanceRow({
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
            fontSize: bold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
