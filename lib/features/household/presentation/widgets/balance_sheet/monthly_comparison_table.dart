import 'package:flutter/material.dart';
import '../../../domain/models/spending_evaluation.dart';

/// 月別比較テーブル - 6ヶ月の詳細データを表示
class MonthlyComparisonTable extends StatelessWidget {
  final HistoricalComparison comparison;

  const MonthlyComparisonTable({
    Key? key,
    required this.comparison,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (comparison.monthlySnapshots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('比較データが利用可能ではありません'),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        horizontalMargin: 8,
        columns: const [
          DataColumn(
            label: Text(
              '月',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              '収入',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              '支出',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              '貯蓄',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              '率%',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
        ],
        rows: comparison.monthlySnapshots.asMap().entries.map((entry) {
          final index = entry.key;
          final snapshot = entry.value;
          final isCurrentMonth =
              index == comparison.monthlySnapshots.length - 1;
          final isPreviousMonth =
              index == comparison.monthlySnapshots.length - 2;

          return DataRow(
            color: WidgetStatePropertyAll(
              isCurrentMonth
                  ? Colors.blue.withValues(alpha: 0.1)
                  : isPreviousMonth
                      ? Colors.grey.withValues(alpha: 0.05)
                      : null,
            ),
            cells: [
              DataCell(
                Row(
                  children: [
                    Text(
                      _formatMonth(snapshot.month),
                      style: TextStyle(
                        fontWeight: isCurrentMonth ? FontWeight.bold : null,
                      ),
                    ),
                    if (isCurrentMonth)
                      const SizedBox(width: 4),
                    if (isCurrentMonth)
                      const Icon(Icons.info, size: 14, color: Colors.blue),
                  ],
                ),
              ),
              DataCell(
                Text(
                  '¥${(snapshot.income / 10000).toStringAsFixed(0)}万',
                  style: TextStyle(
                    fontWeight: isCurrentMonth ? FontWeight.bold : null,
                    color: Colors.blue,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '¥${(snapshot.expense / 10000).toStringAsFixed(0)}万',
                  style: TextStyle(
                    fontWeight: isCurrentMonth ? FontWeight.bold : null,
                    color: Colors.red,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '¥${(snapshot.savings / 10000).toStringAsFixed(0)}万',
                  style: TextStyle(
                    fontWeight: isCurrentMonth ? FontWeight.bold : null,
                    color: Colors.green,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${snapshot.savingsRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: isCurrentMonth ? FontWeight.bold : null,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatMonth(String yearMonth) {
    final parts = yearMonth.split('-');
    if (parts.length == 2) {
      return '${parts[1]}月';
    }
    return yearMonth;
  }
}
