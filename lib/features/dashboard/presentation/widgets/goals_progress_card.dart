import 'package:flutter/material.dart';

/// 目標進捗カード - 金融目標の達成状況表示
class GoalsProgressCard extends StatelessWidget {
  final List<FinancialGoal> goals;

  const GoalsProgressCard({
    Key? key,
    required this.goals,
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
              '🎯 目標進捗',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 目標リスト
            ...List.generate(goals.length, (index) {
              final goal = goals[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < goals.length - 1 ? 16 : 0,
                ),
                child: _buildGoalTile(context, goal),
              );
            }),

            if (goals.isEmpty)
              Center(
                child: Text(
                  '目標がまだ設定されていません',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTile(BuildContext context, FinancialGoal goal) {
    final theme = Theme.of(context);
    final progressPercent = (goal.currentAmount / goal.targetAmount).clamp(0, 1);
    final isCompleted = progressPercent >= 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '¥${goal.currentAmount} / ¥${goal.targetAmount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '達成',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                '${(progressPercent * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressPercent,
            minHeight: 6,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              isCompleted ? Colors.green : Colors.blue[700]!,
            ),
          ),
        ),
      ],
    );
  }
}

/// 金融目標モデル
class FinancialGoal {
  final String name;
  final int targetAmount;
  final int currentAmount;
  final DateTime deadline;
  final String category;

  FinancialGoal({
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.category,
  });

  double get progress => currentAmount / targetAmount;
}
