import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/subscription.dart';
import '../providers/subscription_audit_provider.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';
import 'payment_calendar_page.dart';

class SubscriptionAuditPage extends ConsumerWidget {
  const SubscriptionAuditPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final uid = user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('サブスク棚卸し'),
        actions: [
          if (uid != null)
            IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: '支払いカレンダー',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PaymentCalendarPage(uid: uid)),
              ),
            ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('ログインしてください'))
          : _SubscriptionList(uid: uid),
      floatingActionButton: uid == null
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddSheet(context, ref, uid),
              child: const Icon(Icons.add),
            ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddSubscriptionSheet(uid: uid),
    );
  }
}

class _SubscriptionList extends ConsumerWidget {
  final String uid;

  const _SubscriptionList({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionsStreamProvider(uid));

    return subscriptionsAsync.when(
      data: (subscriptions) {
        if (subscriptions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'まだサブスクが登録されていません。\n右下の＋ボタンから登録してみましょう。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final active = subscriptions.where((s) => s.isActive).toList();
        final inactive = subscriptions.where((s) => !s.isActive).toList();
        final totalMonthly = active.fold<int>(
            0, (sum, s) => sum + s.monthlyEquivalentAmount);
        final totalAnnual = active.fold<int>(0, (sum, s) => sum + s.annualAmount);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummaryCard(totalMonthly, totalAnnual, active.length),
            const SizedBox(height: 20),
            if (active.isNotEmpty) ...[
              const Text('契約中', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...active.map((s) => _SubscriptionTile(uid: uid, subscription: s)),
            ],
            if (inactive.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('解約済み',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              ...inactive.map((s) => _SubscriptionTile(uid: uid, subscription: s)),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, st) => Center(child: Text('エラー: $error')),
    );
  }

  Widget _buildSummaryCard(int totalMonthly, int totalAnnual, int activeCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade300, Colors.orange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('契約中サブスクの月額合計',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            '¥$totalMonthly',
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text('年間換算: ¥$totalAnnual（$activeCount件契約中）',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SubscriptionTile extends ConsumerWidget {
  final String uid;
  final Subscription subscription;

  const _SubscriptionTile({required this.uid, required this.subscription});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(subscriptionAuditServiceProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          subscription.name,
          style: TextStyle(
            decoration: subscription.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Text(
          '${subscription.category.displayName} ・ ¥${subscription.amount}/'
          '${subscription.billingCycle.displayName == '月払い' ? '月' : '年'}'
          '（月換算 ¥${subscription.monthlyEquivalentAmount}）',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: subscription.isActive,
              onChanged: (v) => service.setActive(
                uid: uid,
                subscriptionId: subscription.id,
                isActive: v,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () => service.deleteSubscription(uid, subscription.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSubscriptionSheet extends ConsumerStatefulWidget {
  final String uid;

  const _AddSubscriptionSheet({required this.uid});

  @override
  ConsumerState<_AddSubscriptionSheet> createState() =>
      _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends ConsumerState<_AddSubscriptionSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  SubscriptionBillingCycle _billingCycle = SubscriptionBillingCycle.monthly;
  SubscriptionCategory _category = SubscriptionCategory.video;
  int? _billingDay;
  int _billingMonth = DateTime.now().month;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amount = int.tryParse(_amountController.text);
    if (name.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('サービス名と金額を正しく入力してください')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final service = ref.read(subscriptionAuditServiceProvider);
      await service.addSubscription(
        uid: widget.uid,
        name: name,
        amount: amount,
        billingCycle: _billingCycle,
        category: _category,
        billingDay: _billingDay,
        billingMonth: _billingCycle == SubscriptionBillingCycle.yearly ? _billingMonth : null,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登録に失敗しました')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('サブスクを登録', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'サービス名',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '金額',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<SubscriptionBillingCycle>(
            value: _billingCycle,
            decoration: const InputDecoration(labelText: '請求サイクル'),
            items: SubscriptionBillingCycle.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.displayName)))
                .toList(),
            onChanged: (v) => setState(() => _billingCycle = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<SubscriptionCategory>(
            value: _category,
            decoration: const InputDecoration(labelText: 'カテゴリ'),
            items: SubscriptionCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.displayName)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _billingDay,
                  decoration: const InputDecoration(
                    labelText: '請求日（任意・リマインダー用）',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('設定しない')),
                    for (var d = 1; d <= 28; d++)
                      DropdownMenuItem(value: d, child: Text('毎月$d日')),
                  ],
                  onChanged: (v) => setState(() => _billingDay = v),
                ),
              ),
              if (_billingCycle == SubscriptionBillingCycle.yearly && _billingDay != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _billingMonth,
                    decoration: const InputDecoration(labelText: '請求月', isDense: true),
                    items: [
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem(value: m, child: Text('$m月')),
                    ],
                    onChanged: (v) => setState(() => _billingMonth = v!),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('登録する'),
          ),
        ],
      ),
    );
  }
}
