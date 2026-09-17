import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/household_expense_summary.dart';
import '../providers/expense_list_provider.dart';

/// 月間支出一覧ページ
class ExpenseListPage extends ConsumerStatefulWidget {
  final String groupId;
  final String userId;

  const ExpenseListPage({
    Key? key,
    required this.groupId,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends ConsumerState<ExpenseListPage> {
  late DateTime _selectedMonth;
  String? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(
      monthlyExpenseListProvider((widget.userId, _selectedMonth.year, _selectedMonth.month)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('支出一覧'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Month Selector
          _buildMonthSelector(context),
          // Filter Bar
          _buildFilterBar(),
          // Expense List
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                final filtered = _selectedCategoryFilter != null
                    ? expenses
                        .where((e) => e.category.toString().contains(_selectedCategoryFilter!))
                        .toList()
                    : expenses;

                if (filtered.isEmpty) {
                  return _buildEmptyState(context);
                }

                return _buildExpenseList(context, filtered);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(context, error),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to expense recording page
          Navigator.of(context).pushNamed('/receipt-capture');
        },
        label: const Text('支出を記録'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              });
            },
          ),
          InkWell(
            onTap: () => _showMonthPicker(context),
            child: Text(
              '${_selectedMonth.year}年${_selectedMonth.month}月',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final categories = ['food', 'transportation', 'utilities', 'entertainment', 'healthcare', 'education', 'shopping', 'other'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('すべて'),
              selected: _selectedCategoryFilter == null,
              onSelected: (_) {
                setState(() => _selectedCategoryFilter = null);
              },
            ),
          ),
          ...categories.map((category) {
            final isSelected = _selectedCategoryFilter == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_formatCategoryName(category)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategoryFilter = selected ? category : null;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExpenseList(BuildContext context, List<ExpenseRecord> expenses) {
    // Group by date
    final groupedByDate = <DateTime, List<ExpenseRecord>>{};
    for (final expense in expenses) {
      final dateKey = DateTime(expense.date.year, expense.date.month, expense.date.day);
      (groupedByDate[dateKey] ??= []).add(expense);
    }

    final sortedDates = groupedByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayExpenses = groupedByDate[date]!;
        final dayTotal = dayExpenses.fold<int>(0, (sum, e) => sum + e.amount);

        return Column(
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${date.month}月${date.day}日',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '¥$dayTotal',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            // Expense items
            ...dayExpenses.asMap().entries.map((entry) {
              final expense = entry.value;
              return _buildExpenseItem(context, expense);
            }),
            if (index < sortedDates.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Colors.grey[300]),
              ),
          ],
        );
      },
    );
  }

  Widget _buildExpenseItem(BuildContext context, ExpenseRecord expense) {
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteExpense(expense.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red[400],
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: _buildCategoryIcon(expense.category),
        title: Text(expense.categoryDisplay),
        subtitle: Text(
          expense.userNickname != null ? 'by ${expense.userNickname}' : '',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '¥${expense.amount}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        onTap: () {
          _showEditDialog(context, expense);
        },
      ),
    );
  }

  Widget _buildCategoryIcon(String category) {
    final icons = {
      'food': '🍔',
      'transportation': '🚗',
      'utilities': '💡',
      'entertainment': '🎬',
      'healthcare': '🏥',
      'education': '📚',
      'shopping': '🛍️',
      'other': '📦',
    };
    return Text(icons[category] ?? '📌', style: const TextStyle(fontSize: 24));
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'この月の支出はありません',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/receipt-capture');
            },
            icon: const Icon(Icons.add),
            label: const Text('支出を記録'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'エラーが発生しました',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  void _showMonthPicker(BuildContext context) {
    showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    ).then((date) {
      if (date != null) {
        setState(() => _selectedMonth = date);
      }
    });
  }

  void _showEditDialog(BuildContext context, ExpenseRecord expense) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('支出を編集'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('カテゴリ: ${expense.categoryDisplay}'),
            const SizedBox(height: 8),
            Text('金額: ¥${expense.amount}'),
            const SizedBox(height: 8),
            Text('日付: ${expense.date.toString().split(' ')[0]}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Open edit form
              Navigator.pop(context);
            },
            child: const Text('編集'),
          ),
        ],
      ),
    );
  }

  void _deleteExpense(String expenseId) {
    ref.read(expenseServiceProvider).deleteReceipt(widget.userId, expenseId).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('支出を削除しました')),
      );
      // Refresh the list
      ref.refresh(
        monthlyExpenseListProvider(
          (widget.userId, _selectedMonth.year, _selectedMonth.month),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $error')),
      );
    });
  }

  String _formatCategoryName(String category) {
    const names = {
      'food': '食費',
      'transportation': '交通',
      'utilities': '光熱費',
      'entertainment': '娯楽',
      'healthcare': '医療',
      'education': '教育',
      'shopping': 'ショッピング',
      'other': 'その他',
    };
    return names[category] ?? category;
  }
}

// ===== Supporting Models =====

/// 支出レコード
class ExpenseRecord {
  final String id;
  final String category;
  final String categoryDisplay;
  final int amount;
  final DateTime date;
  final String? userNickname;

  ExpenseRecord({
    required this.id,
    required this.category,
    required this.categoryDisplay,
    required this.amount,
    required this.date,
    this.userNickname,
  });
}
