import 'household_budget.dart';

/// 月間家計サマリー - ダッシュボード用の集計情報
class HouseholdExpenseSummary {
  final String groupId;
  final String month; // YYYY-MM形式
  final int totalIncome;
  final int totalExpense;
  final int savingAmount;
  final Map<String, int> categoryBreakdown;

  HouseholdExpenseSummary({
    required this.groupId,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.savingAmount,
    required this.categoryBreakdown,
  });
}

class HouseholdMonthlyExpense {
  final String groupId;
  final DateTime month; // 年月を表す日付（日は1固定）
  final Map<BudgetCategory, List<HouseholdExpenseRecord>> expensesByCategory;
  final DateTime updatedAt;

  HouseholdMonthlyExpense({
    required this.groupId,
    required this.month,
    required this.expensesByCategory,
    required this.updatedAt,
  });

  // カテゴリ別の支出合計
  int getTotalByCategory(BudgetCategory category) {
    return expensesByCategory[category]?.fold<int>(
          0,
          (sum, expense) => sum + expense.amount,
        ) ??
        0;
  }

  // 全体の支出合計
  int get totalExpenses {
    int total = 0;
    for (var expenses in expensesByCategory.values) {
      total += expenses.fold(0, (sum, expense) => sum + expense.amount);
    }
    return total;
  }

  // カテゴリ別の人数（複数メンバーのデータを見る場合）
  int getExpenseCountByCategory(BudgetCategory category) {
    return expensesByCategory[category]?.length ?? 0;
  }
}

class HouseholdExpenseRecord {
  final String id;
  final String uid;
  final String userNickname; // 表示用ニックネーム
  final DateTime date;
  final BudgetCategory category;
  final int amount;
  final String? description;
  final String? receiptImagePath;

  HouseholdExpenseRecord({
    required this.id,
    required this.uid,
    required this.userNickname,
    required this.date,
    required this.category,
    required this.amount,
    this.description,
    this.receiptImagePath,
  });

  factory HouseholdExpenseRecord.fromJson(Map<String, dynamic> json) {
    return HouseholdExpenseRecord(
      id: json['id'] as String,
      uid: json['uid'] as String,
      userNickname: json['userNickname'] as String,
      date: DateTime.parse(json['date'] as String),
      category: BudgetCategory.values[json['category'] as int? ?? 7],
      amount: json['amount'] as int,
      description: json['description'] as String?,
      receiptImagePath: json['receiptImagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'userNickname': userNickname,
      'date': date.toIso8601String(),
      'category': category.index,
      'amount': amount,
      'description': description,
      'receiptImagePath': receiptImagePath,
    };
  }
}
