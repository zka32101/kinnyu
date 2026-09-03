import 'package:flutter/material.dart';

/// クイックアクションカード - よく使う機能へのショートカット
class QuickActionsCard extends StatelessWidget {
  final VoidCallback? onReceiptTap;
  final VoidCallback? onBudgetTap;
  final VoidCallback? onGoalTap;
  final VoidCallback? onDonationTap;

  const QuickActionsCard({
    Key? key,
    this.onReceiptTap,
    this.onBudgetTap,
    this.onGoalTap,
    this.onDonationTap,
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
              '⚡ クイックアクション',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // アクションボタングリッド
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.8,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.receipt_long,
                  label: 'レシート記録',
                  color: Colors.blue,
                  onTap: onReceiptTap,
                ),
                _buildActionButton(
                  context,
                  icon: Icons.account_balance_wallet,
                  label: '予算管理',
                  color: Colors.green,
                  onTap: onBudgetTap,
                ),
                _buildActionButton(
                  context,
                  icon: Icons.target,
                  label: '目標設定',
                  color: Colors.orange,
                  onTap: onGoalTap,
                ),
                _buildActionButton(
                  context,
                  icon: Icons.favorite,
                  label: '寄付する',
                  color: Colors.red,
                  onTap: onDonationTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
