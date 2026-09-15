import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/social_contribution_provider.dart';
import '../widgets/social_impact_dashboard_card.dart';
import '../widgets/carbon_tracker_widget.dart';
import '../widgets/charity_card.dart';
import '../widgets/esg_score_card.dart';
import '../../domain/models/social_contribution.dart';
import '../../../../core/firebase/auth_provider.dart';

/// 社会貢献ページ
class SocialContributionPage extends ConsumerWidget {
  final String groupId;

  const SocialContributionPage({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(socialImpactDashboardProvider(groupId));
    final averageESGAsync = ref.watch(averageESGScoreProvider(groupId));
    final donationByCharityAsync = ref.watch(donationByCharityProvider(groupId));
    final charities = ref.watch(defaultCharitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🌍 社会貢献インパクト'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // インパクトダッシュボード
              dashboardAsync.when(
                data: (dashboard) {
                  return Column(
                    children: [
                      SocialImpactDashboardCard(
                        dashboard: dashboard,
                        onTap: () => _showDashboardDetails(context, dashboard),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, _) => const SizedBox.shrink(),
              ),

              // カーボントラッカー
              CarbonTrackerWidget(groupId: groupId),
              const SizedBox(height: 24),

              // ESGスコア
              averageESGAsync.when(
                data: (averageESG) {
                  return Column(
                    children: [
                      ESGScoreCard(
                        score: averageESG,
                        isAverage: true,
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, _) => const SizedBox.shrink(),
              ),

              // チャリティセクション
              Text(
                '💚 チャリティ寄付',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              donationByCharityAsync.when(
                data: (donationByCharity) {
                  return Column(
                    children: charities.map((charity) {
                      final userDonation = donationByCharity[charity.name];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CharityCard(
                          charity: charity,
                          userDonationAmount: userDonation,
                          onDonate: () {
                            _showDonationDialog(context, ref, charity);
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Text('エラー: $error'),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// ダッシュボード詳細を表示
  void _showDashboardDetails(
    BuildContext context,
    SocialImpactDashboard dashboard,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) => _DashboardDetailsSheet(dashboard: dashboard),
    );
  }

  /// 寄付ダイアログを表示
  void _showDonationDialog(
    BuildContext context,
    WidgetRef ref,
    CharityDonation charity,
  ) {
    showDialog(
      context: context,
      builder: (context) => _DonationDialog(
        groupId: groupId,
        charity: charity,
        ref: ref,
      ),
    );
  }
}

/// ダッシュボード詳細シート
class _DashboardDetailsSheet extends StatelessWidget {
  final SocialImpactDashboard dashboard;

  const _DashboardDetailsSheet({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '社会貢献インパクト詳細',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // 詳細メトリクス
          _buildDetailRow(theme, '🌳 樹木相当本数', '${dashboard.treesEquivalent}本'),
          const SizedBox(height: 12),
          _buildDetailRow(theme, '🚗 車走行削減', '${dashboard.carKmSaved}km'),
          const SizedBox(height: 12),
          _buildDetailRow(theme, '💚 寄付総額', '¥${dashboard.totalDonationsAmount}'),
          const SizedBox(height: 12),
          _buildDetailRow(theme, '👥 支援世帯数', '${dashboard.familiesHelped}世帯'),
          const SizedBox(height: 20),

          // インパクトレベルの説明
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border.all(color: Colors.green[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'あなたのインパクトレベル',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dashboard.impactLevelDescription,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
      ],
    );
  }
}

/// 寄付ダイアログ
class _DonationDialog extends ConsumerStatefulWidget {
  final String groupId;
  final CharityDonation charity;
  final WidgetRef ref;

  const _DonationDialog({
    required this.groupId,
    required this.charity,
    required this.ref,
  });

  @override
  ConsumerState<_DonationDialog> createState() => _DonationDialogState();
}

class _DonationDialogState extends ConsumerState<_DonationDialog> {
  late int _donationAmount;

  @override
  void initState() {
    super.initState();
    _donationAmount = 1000; // デフォルト1000円
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Text(widget.charity.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(widget.charity.name),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '寄付額を選択してください',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // 金額選択ボタン
          Wrap(
            spacing: 8,
            children: [500, 1000, 5000, 10000].map((amount) {
              final isSelected = _donationAmount == amount;
              return ChoiceChip(
                label: Text('¥$amount'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _donationAmount = amount);
                  }
                },
                selectedColor: Colors.blue,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // カスタム金額入力
          TextField(
            decoration: const InputDecoration(
              labelText: 'カスタム金額（円）',
              hintText: '1000',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final amount = int.tryParse(value);
              if (amount != null && amount > 0) {
                setState(() => _donationAmount = amount);
              }
            },
          ),
          const SizedBox(height: 16),

          // インパクト表示
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border.all(color: Colors.orange[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '💡 ${(_donationAmount * widget.charity.impactPerYen).toStringAsFixed(1)} ${widget.charity.impactDescription.split('\n')[1]}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.orange[900],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.favorite),
          label: const Text('寄付する'),
          onPressed: () => _recordDonation(context),
        ),
      ],
    );
  }

  /// 寄付記録をFirestoreに保存
  Future<void> _recordDonation(BuildContext context) async {
    try {
      // 現在のユーザーを取得
      final userAsync = ref.watch(currentUserProvider);
      final user = userAsync.asData?.value;

      if (user == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ログイン状態を確認できません。再度試してください。'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 寄付記録を保存
      final mutator = ref.read(socialContributionMutatorProvider);
      await mutator.recordDonation(
        widget.groupId,
        user.uid,
        widget.charity.id,
        widget.charity.name,
        _donationAmount,
        'ユーザー寄付',
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¥$_donationAmount を ${widget.charity.name} に寄付しました ❤️',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('寄付の保存に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
