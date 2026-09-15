import 'package:flutter/material.dart';
import 'feature_gate.dart';

/// 無料ユーザーがプレミアム機能にアクセスしようとした時に表示するダイアログ。
/// 機能の説明とプレミアムアップグレードへの誘導を行う。
class PremiumFeatureDialog extends StatelessWidget {
  final PremiumFeature feature;
  final VoidCallback onUpgradeTap;
  final VoidCallback? onDismiss;

  const PremiumFeatureDialog({
    Key? key,
    required this.feature,
    required this.onUpgradeTap,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.amber[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature.displayName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'この機能はプレミアム会員限定です',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.workspace_premium, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '月額 ¥200 でプレミアムに\nアップグレードして利用できます',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDismiss?.call();
          },
          child: const Text('後で'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onUpgradeTap();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700],
          ),
          child: const Text('プレミアムになる'),
        ),
      ],
    );
  }

  static void show(
    BuildContext context, {
    required PremiumFeature feature,
    required VoidCallback onUpgradeTap,
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      builder: (context) => PremiumFeatureDialog(
        feature: feature,
        onUpgradeTap: onUpgradeTap,
        onDismiss: onDismiss,
      ),
    );
  }
}
