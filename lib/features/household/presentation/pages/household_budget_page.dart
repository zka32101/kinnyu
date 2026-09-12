import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/household_budget_provider.dart';
import '../../domain/models/household_budget.dart';
import '../../../../core/theme/app_colors.dart';

class HouseholdBudgetPage extends ConsumerStatefulWidget {
  final String groupId;

  const HouseholdBudgetPage({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  ConsumerState<HouseholdBudgetPage> createState() =>
      _HouseholdBudgetPageState();
}

class _HouseholdBudgetPageState extends ConsumerState<HouseholdBudgetPage> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('世帯予算'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 月選択
          _buildMonthSelector(),
          const SizedBox(height: 20),

          // 予算サマリー
          _buildBudgetSummary(),
          const SizedBox(height: 20),

          // カテゴリ別予算カード
          _buildCategoryBudgets(),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final format = DateFormat('yyyy年M月');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _previousMonth,
        ),
        Text(
          format.format(_selectedMonth),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _nextMonth,
        ),
      ],
    );
  }

  Widget _buildBudgetSummary() {
    final summaryAsync = ref.watch(
      householdExpenseSummaryProvider(
        (groupId: widget.groupId, month: _selectedMonth),
      ),
    );
    final budgetAsync = ref.watch(householdBudgetProvider(widget.groupId));

    return summaryAsync.when(
      data: (summaries) {
        final totalSpent =
            summaries.values.fold<int>(0, (sum, s) => sum + s.totalExpense);
        final totalBudget = budgetAsync.maybeWhen(
          data: (budget) => budget?.totalBudget ?? 0,
          orElse: () => 0,
        );

        final budgetFormat = NumberFormat('#,###');
        final ratio = totalBudget > 0 ? totalSpent / totalBudget : 0.0;
        final isOverBudget = totalSpent > totalBudget;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isOverBudget
                  ? [Colors.red.shade300, Colors.red.shade600]
                  : [Colors.green.shade300, Colors.green.shade600],
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
                '月間予算',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                '¥${budgetFormat.format(totalSpent)} / ¥${budgetFormat.format(totalBudget)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(ratio * 100).toStringAsFixed(1)}% 使用済み',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラー: $error')),
    );
  }

  Widget _buildCategoryBudgets() {
    final summaryAsync = ref.watch(
      householdExpenseSummaryProvider(
        (groupId: widget.groupId, month: _selectedMonth),
      ),
    );

    return summaryAsync.when(
      data: (summaries) {
        // カテゴリを支出順でソート
        final sortedCategories = summaries.entries.toList()
          ..sort((a, b) => b.value.totalExpense.compareTo(a.value.totalExpense));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'カテゴリ別予算',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...sortedCategories.map((entry) {
              return _buildCategoryCard(entry.key, entry.value);
            }).toList(),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラー: $error')),
    );
  }

  Widget _buildCategoryCard(BudgetCategory category, HouseholdExpenseSummary summary) {
    final budgetFormat = NumberFormat('#,###');
    final spent = summary.totalExpense;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  category.icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '¥${budgetFormat.format(spent)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0.5,
                backgroundColor: Colors.grey.shade200,
                color: Colors.blue,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
