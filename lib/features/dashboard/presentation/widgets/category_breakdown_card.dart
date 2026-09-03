import 'package:flutter/material.dart';

/// カテゴリ別支出内訳カード - 支出をカテゴリ別に可視化
class CategoryBreakdownCard extends StatelessWidget {
  final Map<String, CategoryExpense> expenses;
  final int totalExpense;

  const CategoryBreakdownCard({
    Key? key,
    required this.expenses,
    required this.totalExpense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedExpenses = expenses.entries.toList()
      ..sort((a, b) => b.value.amount.compareTo(a.value.amount));

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
              '📊 カテゴリ別支出',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // カテゴリの円グラフ表現（シンプル版）
            if (sortedExpenses.isNotEmpty)
              Column(
                children: List.generate(sortedExpenses.length, (index) {
                  final entry = sortedExpenses[index];
                  final percentage =
                      totalExpense > 0 ? entry.value.amount / totalExpense : 0;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < sortedExpenses.length - 1 ? 12 : 0,
                    ),
                    child: _buildCategoryRow(
                      context,
                      category: entry.key,
                      emoji: entry.value.emoji,
                      amount: entry.value.amount,
                      percentage: percentage,
                      color: entry.value.color,
                    ),
                  );
                }),
              )
            else
              Center(
                child: Text(
                  'データがありません',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),

            if (sortedExpenses.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '合計支出',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '¥${totalExpense.toString()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(
    BuildContext context, {
    required String category,
    required String emoji,
    required int amount,
    required double percentage,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
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
            const SizedBox(width: 8),
            Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

/// カテゴリ別支出モデル
class CategoryExpense {
  final String emoji;
  final Color color;
  final int amount;

  CategoryExpense({
    required this.emoji,
    required this.color,
    required this.amount,
  });
}
