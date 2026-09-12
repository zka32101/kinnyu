import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/household_budget.dart';
import '../providers/household_budget_provider.dart';
import '../providers/household_provider.dart';

class BudgetSettingsDialog extends ConsumerStatefulWidget {
  final String groupId;
  final HouseholdBudget? initialBudget;

  const BudgetSettingsDialog({
    Key? key,
    required this.groupId,
    this.initialBudget,
  }) : super(key: key);

  @override
  ConsumerState<BudgetSettingsDialog> createState() =>
      _BudgetSettingsDialogState();
}

class _BudgetSettingsDialogState extends ConsumerState<BudgetSettingsDialog> {
  late Map<BudgetCategory, TextEditingController> controllers;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    controllers = {};
    for (var category in BudgetCategory.values) {
      final amount = widget.initialBudget?.categoryBudgets[category] ?? 0;
      controllers[category] = TextEditingController(text: amount.toString());
    }
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (isSubmitting) return;

    setState(() => isSubmitting = true);

    try {
      final budgets = <BudgetCategory, int>{};
      for (var category in BudgetCategory.values) {
        final value = int.tryParse(controllers[category]?.text ?? '0') ?? 0;
        budgets[category] = value;
      }

      final service = ref.read(householdServiceProvider);
      await service.updateBudget(groupId: widget.groupId, budgets: budgets);

      // キャッシュを無効化
      ref.invalidate(householdBudgetProvider(widget.groupId));
      ref.invalidate(
        householdExpenseSummaryProvider(
          (groupId: widget.groupId, month: DateTime.now()),
        ),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('予算を更新しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '予算設定',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ..._buildBudgetInputs(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.pop(context, false),
                    child: const Text('キャンセル'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : _saveBudget,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBudgetInputs() {
    return [
      for (var category in BudgetCategory.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildBudgetInput(category),
        ),
    ];
  }

  Widget _buildBudgetInput(BudgetCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              category.icon,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              category.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controllers[category],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '¥ ',
            hintText: '0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }
}
