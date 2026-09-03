enum BudgetCategory {
  food,
  utilities,
  transport,
  entertainment,
  healthcare,
  education,
  shopping,
  other,
}

extension BudgetCategoryX on BudgetCategory {
  String get displayName {
    switch (this) {
      case BudgetCategory.food:
        return '食費';
      case BudgetCategory.utilities:
        return '光熱費';
      case BudgetCategory.transport:
        return '交通費';
      case BudgetCategory.entertainment:
        return '娯楽';
      case BudgetCategory.healthcare:
        return '医療・健康';
      case BudgetCategory.education:
        return '教育';
      case BudgetCategory.shopping:
        return 'ショッピング';
      case BudgetCategory.other:
        return 'その他';
    }
  }

  String get icon {
    switch (this) {
      case BudgetCategory.food:
        return '🍔';
      case BudgetCategory.utilities:
        return '💡';
      case BudgetCategory.transport:
        return '🚗';
      case BudgetCategory.entertainment:
        return '🎬';
      case BudgetCategory.healthcare:
        return '⚕️';
      case BudgetCategory.education:
        return '📚';
      case BudgetCategory.shopping:
        return '🛍️';
      case BudgetCategory.other:
        return '📌';
    }
  }
}

class HouseholdBudget {
  final String id; // groupId
  final Map<BudgetCategory, int> categoryBudgets; // 各カテゴリの月間予算（円）
  final DateTime createdAt;
  final DateTime updatedAt;

  HouseholdBudget({
    required this.id,
    required this.categoryBudgets,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HouseholdBudget.fromJson(Map<String, dynamic> json) {
    final budgets = <BudgetCategory, int>{};
    final budgetsMap = json['categoryBudgets'] as Map<String, dynamic>? ?? {};

    for (var category in BudgetCategory.values) {
      final amount = budgetsMap[category.name] as int? ?? 0;
      budgets[category] = amount;
    }

    return HouseholdBudget(
      id: json['id'] as String,
      categoryBudgets: budgets,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryBudgets': {
        for (var category in categoryBudgets.entries)
          category.key.name: category.value,
      },
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Default budget template: 30万円の月間家計予算を標準配分
  static HouseholdBudget defaultTemplate(String groupId) {
    return HouseholdBudget(
      id: groupId,
      categoryBudgets: {
        BudgetCategory.food: 60000,
        BudgetCategory.utilities: 25000,
        BudgetCategory.transport: 20000,
        BudgetCategory.entertainment: 20000,
        BudgetCategory.healthcare: 15000,
        BudgetCategory.education: 10000,
        BudgetCategory.shopping: 30000,
        BudgetCategory.other: 20000,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  int get totalBudget => categoryBudgets.values.fold(0, (a, b) => a + b);
}

class HouseholdExpenseSummary {
  final BudgetCategory category;
  final int spent; // 実際に使った金額
  final int budget; // 予算
  final double usageRatio; // 使用率（0.0-1.0）
  final int remaining; // 残り予算

  HouseholdExpenseSummary({
    required this.category,
    required this.spent,
    required this.budget,
  })  : usageRatio = budget > 0 ? (spent / budget).clamp(0.0, 2.0) : 0.0,
        remaining = budget - spent;

  bool get isOverBudget => spent > budget;
  bool get isWarning => usageRatio >= 0.8 && usageRatio < 1.0;
}
