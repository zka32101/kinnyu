import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/subscription.dart';
import '../providers/subscription_audit_provider.dart';

/// 契約中サブスクの次回請求日を一覧表示するカレンダー的ビュー。
/// 請求日（billingDay）が設定されているサブスクのみ表示する。
class PaymentCalendarPage extends ConsumerWidget {
  final String uid;

  const PaymentCalendarPage({Key? key, required this.uid}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionsStreamProvider(uid));

    return Scaffold(
      appBar: AppBar(title: const Text('支払いカレンダー')),
      body: subscriptionsAsync.when(
        data: (subscriptions) {
          final withBillingDate = subscriptions
              .where((s) => s.isActive && s.nextBillingDate != null)
              .toList()
            ..sort((a, b) => a.nextBillingDate!.compareTo(b.nextBillingDate!));

          if (withBillingDate.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  '請求日が設定されているサブスクがありません。\n'
                  'サブスク編集画面から請求日を設定すると、ここに表示され'
                  '支払い前にリマインダー通知が届きます。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: withBillingDate.length,
            itemBuilder: (context, index) =>
                _PaymentTile(subscription: withBillingDate[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(child: Text('エラー: $error')),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Subscription subscription;

  const _PaymentTile({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final amountFormat = NumberFormat('#,###');
    final nextDate = subscription.nextBillingDate!;
    // nextDateは00:00:00固定のため、時刻を持つDateTime.now()とそのまま差分を
    // 取ると.inDaysが1日分切り捨てられる。日付のみ（today）と比較する。
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysUntil = nextDate.difference(today).inDays;
    final isUrgent = daysUntil <= 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUrgent ? Colors.red.shade100 : Colors.blue.shade50,
          child: Text(
            '${nextDate.day}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isUrgent ? Colors.red.shade700 : Colors.blue.shade700,
            ),
          ),
        ),
        title: Text(subscription.name),
        subtitle: Text(
          '${DateFormat('yyyy/MM/dd').format(nextDate)}（あと$daysUntil日）',
        ),
        trailing: Text(
          '¥${amountFormat.format(subscription.amount)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
