import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../../core/subscription/subscription_provider.dart';
import '../../../../core/theme/app_colors.dart';

class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  Offerings? _offerings;
  bool _loadingOfferings = true;
  bool _purchasing = false;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final service = ref.read(subscriptionServiceProvider);
    final offerings = await service.getOfferings();
    if (mounted) {
      setState(() {
        _offerings = offerings;
        _loadingOfferings = false;
      });
    }
  }

  Future<void> _purchase(Package package) async {
    if (_purchasing) return;
    setState(() => _purchasing = true);
    final service = ref.read(subscriptionServiceProvider);
    try {
      await service.purchasePackage(package);
      await ref.read(isPremiumProvider.notifier).refresh();
      if (mounted) {
        if (ref.read(isPremiumProvider)) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('購入処理が完了しました。反映まで少し時間がかかる場合があります。'),
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('購入処理に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    if (_restoring) return;
    setState(() => _restoring = true);
    try {
      final service = ref.read(subscriptionServiceProvider);
      await service.restorePurchases();
      await ref.read(isPremiumProvider.notifier).refresh();
      final restored = ref.read(isPremiumProvider);
      if (mounted) {
        if (restored) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('購入履歴を復元しました')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('復元できる購入履歴が見つかりませんでした')),
          );
        }
      }
    } catch (e) {
      debugPrint('Restore purchases failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('復元処理に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final packages = _offerings?.current?.availablePackages ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('金融オンライン大学 プレミアム')),
      body: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade300, Colors.amber.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppSpacing.radiusLarge,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.workspace_premium, color: Colors.white, size: 40),
                SizedBox(height: 12),
                Text(
                  'プレミアムで、もっと本格的に学ぼう',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildFeatureRow(
            Icons.trending_up,
            '投資シミュレーション 全8パターン',
            'ライフステージ別プリセットを制限なく試せる',
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            Icons.ios_share,
            'Excel出力',
            'シミュレーション結果を.xlsxでいつでも書き出し',
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            Icons.account_balance,
            '制度・補助金を無制限に閲覧',
            '児童手当からNISA・医療費控除まで、全22制度の詳細を確認できる',
          ),
          const SizedBox(height: 32),
          if (_loadingOfferings)
            const Center(child: CircularProgressIndicator())
          else if (packages.isEmpty)
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: AppSpacing.radiusMedium,
              ),
              child: const Text(
                '現在プランを準備中です。しばらくしてから再度お試しください。',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            )
          else
            ...packages.map((p) {
              final intro = p.storeProduct.introductoryPrice;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (intro != null) _buildTrialBadge(intro),
                    ElevatedButton(
                      onPressed: _purchasing ? null : () => _purchase(p),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: _purchasing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              '${p.storeProduct.title} — ${p.storeProduct.priceString}',
                            ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _restoring ? null : _restore,
            child: _restoring
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('購入履歴を復元'),
          ),
        ],
      ),
    );
  }

  /// イントロダクトリー価格（トライアル/初回割引）の期間を
  /// 人が読める形式（例: 7日間、1ヶ月）に変換する。
  String _formatIntroPeriod(IntroductoryPrice intro) {
    final n = intro.periodNumberOfUnits;
    switch (intro.periodUnit) {
      case PeriodUnit.day:
        return '$n日間';
      case PeriodUnit.week:
        return '$n週間';
      case PeriodUnit.month:
        return '$nヶ月';
      case PeriodUnit.year:
        return '$n年間';
      default:
        return '';
    }
  }

  /// パッケージのボタン直前に表示するトライアル訴求バッジ。
  Widget _buildTrialBadge(IntroductoryPrice intro) {
    final period = _formatIntroPeriod(intro);
    final text = intro.price == 0 ? '$periodお試し無料' : '初回お得な価格';
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.amber.shade900,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.amber.shade800),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 2),
              Text(description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}
