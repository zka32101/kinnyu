import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/savings_goal.dart';
import '../providers/savings_goal_provider.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';

class SavingsGoalPage extends ConsumerWidget {
  const SavingsGoalPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final uid = user?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('貯金目標プランナー')),
      body: uid == null
          ? const Center(child: Text('ログインしてください'))
          : _GoalList(uid: uid),
      floatingActionButton: uid == null
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddSheet(context, uid),
              child: const Icon(Icons.add),
            ),
    );
  }

  void _showAddSheet(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddGoalSheet(uid: uid),
    );
  }
}

class _GoalList extends ConsumerWidget {
  final String uid;

  const _GoalList({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsStreamProvider(uid));

    return goalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'まだ貯金目標が登録されていません。\n右下の＋ボタンから目標を作ってみましょう。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: goals.map((g) => _GoalCard(uid: uid, goal: g)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, st) => Center(child: Text('エラー: $error')),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final String uid;
  final SavingsGoal goal;

  const _GoalCard({required this.uid, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountFormat = NumberFormat('#,###');
    final service = ref.read(savingsGoalServiceProvider);
    final monthsLeft = goal.deadline.difference(DateTime.now()).inDays ~/ 30;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(goal.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    goal.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (goal.isAchieved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('達成！',
                        style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: () => service.deleteGoal(uid, goal.id),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: goal.isAchieved ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¥${amountFormat.format(goal.currentAmount)} / ¥${amountFormat.format(goal.targetAmount)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              goal.isAchieved
                  ? '目標を達成しました🎉'
                  : monthsLeft > 0
                      ? '期限まであと約$monthsLeftヶ月・毎月¥${amountFormat.format(goal.requiredMonthlyAmount)}の積立が目安'
                      : '期限が過ぎています。残り¥${amountFormat.format(goal.remainingAmount)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: goal.isAchieved
                  ? null
                  : () => _showAddContributionDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('積立を記録する'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContributionDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('積立額を追加'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: '金額', prefixText: '¥'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                ref.read(savingsGoalServiceProvider).updateProgress(
                      uid: uid,
                      goalId: goal.id,
                      currentAmount: goal.currentAmount + amount,
                    );
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('追加する'),
          ),
        ],
      ),
    );
  }
}

class _AddGoalSheet extends ConsumerStatefulWidget {
  final String uid;

  const _AddGoalSheet({required this.uid});

  @override
  ConsumerState<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<_AddGoalSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 365));
  String _emoji = '🎯';
  bool _isSaving = false;

  static const _emojiOptions = ['🎯', '✈️', '🏠', '🚗', '💍', '👶', '🎓', '🛡️'];

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
        const SnackBar(content: Text('目標名と目標金額を正しく入力してください')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final service = ref.read(savingsGoalServiceProvider);
      await service.addGoal(
        uid: widget.uid,
        name: name,
        emoji: _emoji,
        targetAmount: amount,
        deadline: _deadline,
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

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
    );
    if (picked != null) setState(() => _deadline = picked);
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
          const Text('貯金目標を作成', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _emojiOptions.map((e) {
              final selected = e == _emoji;
              return ChoiceChip(
                label: Text(e, style: const TextStyle(fontSize: 18)),
                selected: selected,
                onSelected: (_) => setState(() => _emoji = e),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '目標名（例：旅行資金）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '目標金額',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('達成期限'),
            subtitle: Text(DateFormat('yyyy年M月d日').format(_deadline)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDeadline,
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
                : const Text('作成する'),
          ),
        ],
      ),
    );
  }
}
