import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/investment.dart';
import '../../domain/services/market_simulator.dart';
import '../providers/investment_provider.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';
import '../../../../core/analytics/analytics_provider.dart';

class InvestmentPortfolioPage extends ConsumerWidget {
  const InvestmentPortfolioPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('ログインが必要です')));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logEvent(
        'investment_portfolio_viewed',
        parameters: {'user_id': user.uid},
      );
    });

    final investmentsAsync = ref.watch(activeInvestmentsProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('見える投資')),
      body: investmentsAsync.when(
        data: (investments) {
          if (investments.isEmpty) {
            return _buildEmptyState(context, ref, user.uid);
          }
          return _buildPortfolioList(context, ref, user.uid, investments);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateInvestmentDialog(context, ref, user.uid),
        icon: const Icon(Icons.add),
        label: const Text('節約額を投資する'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, String uid) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'まだ投資がありません',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '節約した金額を仮想投資してみましょう',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioList(BuildContext context, WidgetRef ref, String uid,
      List<Investment> investments) {
    final totalSavings = investments.fold<int>(
        0, (sum, inv) => sum + inv.savingsAmount);
    final totalCurrentValue = investments.fold<double>(0, (sum, inv) {
      final currentIndex =
          MarketSimulator.getCurrentIndexValue(inv.investmentType);
      return sum + inv.currentValue(currentIndex);
    });
    final totalProfitLoss = totalCurrentValue - totalSavings;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(totalSavings, totalCurrentValue, totalProfitLoss),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: const Text(
            '教育目的シミュレーションです。実売買機能はありません。実際の投資は専門家にご相談ください。',
            style: TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 16),
        ...investments.map((inv) => _buildInvestmentCard(context, ref, uid, inv)),
      ],
    );
  }

  Widget _buildSummaryCard(
      int totalSavings, double totalCurrentValue, double totalProfitLoss) {
    final isProfit = totalProfitLoss >= 0;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit
              ? [Colors.green.shade300, Colors.green.shade600]
              : [Colors.red.shade300, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '投資評価額',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '¥${totalCurrentValue.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '元本: ¥$totalSavings （${isProfit ? '+' : ''}¥${totalProfitLoss.toStringAsFixed(0)}）',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentCard(
      BuildContext context, WidgetRef ref, String uid, Investment inv) {
    final currentIndex =
        MarketSimulator.getCurrentIndexValue(inv.investmentType);
    final currentValue = inv.currentValue(currentIndex);
    final profitLoss = inv.profitLoss(currentIndex);
    final isProfit = profitLoss >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  InvestmentTypeInfo.displayNames[inv.investmentType]!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '¥${currentValue.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '元本 ¥${inv.savingsAmount}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '${isProfit ? '+' : ''}¥${profitLoss.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isProfit ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _realizeInvestment(context, ref, uid, inv),
                child: const Text('利益確定'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _realizeInvestment(
      BuildContext context, WidgetRef ref, String uid, Investment inv) async {
    final service = ref.read(investmentServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    await service.realizeInvestment(uid, inv.id);
    await analytics.logEvent('investment_profit_realized', parameters: {
      'user_id': uid,
      'investment_type': inv.investmentType.index.toString(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('利益を確定しました')),
      );
    }
  }

  void _showCreateInvestmentDialog(
      BuildContext context, WidgetRef ref, String uid) {
    final amountController = TextEditingController(text: '10000');
    InvestmentType selectedType = InvestmentType.topix;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('節約額を投資する'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '投資額（円）',
                      prefixText: '¥',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<InvestmentType>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: '投資先'),
                    items: InvestmentType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(InvestmentTypeInfo.displayNames[type]!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedType = value!);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    InvestmentTypeInfo.descriptions[selectedType] ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amount = int.tryParse(amountController.text) ?? 0;
                    if (amount <= 0) return;

                    final service = ref.read(investmentServiceProvider);
                    await service.createInvestment(
                      uid: uid,
                      savingsAmount: amount,
                      type: selectedType,
                    );

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('投資する'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
