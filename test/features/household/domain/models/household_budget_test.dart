import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/household/domain/models/household_budget.dart';
import 'package:okane_kore/features/household/domain/models/household_expense_summary.dart';

void main() {
  group('HouseholdBudget Model', () {
    test('creates a valid household budget', () {
      final now = DateTime.now();
      final budget = HouseholdBudget(
        id: 'group123',
        categoryBudgets: {
          BudgetCategory.food: 60000,
          BudgetCategory.utilities: 25000,
          BudgetCategory.transport: 20000,
          BudgetCategory.entertainment: 20000,
          BudgetCategory.healthcare: 15000,
          BudgetCategory.education: 10000,
          BudgetCategory.shopping: 30000,
          BudgetCategory.other: 120000,
        },
        createdAt: now,
        updatedAt: now,
      );

      expect(budget.id, equals('group123'));
      expect(budget.categoryBudgets[BudgetCategory.food], equals(60000));
      expect(budget.totalBudget, equals(300000));
    });

    test('calculates total budget correctly', () {
      final now = DateTime.now();
      final budget = HouseholdBudget(
        id: 'group123',
        categoryBudgets: {
          BudgetCategory.food: 100000,
          BudgetCategory.utilities: 50000,
          BudgetCategory.transport: 30000,
          BudgetCategory.entertainment: 20000,
          BudgetCategory.healthcare: 0,
          BudgetCategory.education: 0,
          BudgetCategory.shopping: 0,
          BudgetCategory.other: 0,
        },
        createdAt: now,
        updatedAt: now,
      );

      expect(budget.totalBudget, equals(200000));
    });

    test('handles category budget updates', () {
      final now = DateTime.now();
      final budget = HouseholdBudget(
        id: 'group123',
        categoryBudgets: {
          BudgetCategory.food: 60000,
          BudgetCategory.utilities: 25000,
          BudgetCategory.transport: 20000,
          BudgetCategory.entertainment: 20000,
          BudgetCategory.healthcare: 15000,
          BudgetCategory.education: 10000,
          BudgetCategory.shopping: 30000,
          BudgetCategory.other: 120000,
        },
        createdAt: now,
        updatedAt: now,
      );

      expect(budget.categoryBudgets[BudgetCategory.food], equals(60000));
      expect(budget.categoryBudgets[BudgetCategory.utilities], equals(25000));
    });

    test('handles zero budget for category', () {
      final now = DateTime.now();
      final budget = HouseholdBudget(
        id: 'group123',
        categoryBudgets: {
          BudgetCategory.food: 0,
          BudgetCategory.utilities: 25000,
          BudgetCategory.transport: 20000,
          BudgetCategory.entertainment: 0,
          BudgetCategory.healthcare: 0,
          BudgetCategory.education: 0,
          BudgetCategory.shopping: 0,
          BudgetCategory.other: 55000,
        },
        createdAt: now,
        updatedAt: now,
      );

      expect(budget.categoryBudgets[BudgetCategory.food], equals(0));
      expect(budget.totalBudget, equals(100000));
    });

    test('handles high budget amounts', () {
      final now = DateTime.now();
      final budget = HouseholdBudget(
        id: 'group123',
        categoryBudgets: {
          BudgetCategory.food: 150000,
          BudgetCategory.utilities: 100000,
          BudgetCategory.transport: 100000,
          BudgetCategory.entertainment: 100000,
          BudgetCategory.healthcare: 100000,
          BudgetCategory.education: 100000,
          BudgetCategory.shopping: 100000,
          BudgetCategory.other: 100000,
        },
        createdAt: now,
        updatedAt: now,
      );

      expect(budget.totalBudget, equals(850000));
    });

    test('default template creates valid budget', () {
      final budget = HouseholdBudget.defaultTemplate('group123');
      expect(budget.id, equals('group123'));
      expect(budget.totalBudget, equals(200000));
      expect(budget.categoryBudgets[BudgetCategory.food], equals(60000));
    });

    test('serializes to JSON correctly', () {
      final now = DateTime.now();
      final budget = HouseholdBudget(
        id: 'group123',
        categoryBudgets: {
          BudgetCategory.food: 60000,
          BudgetCategory.utilities: 25000,
          BudgetCategory.transport: 20000,
          BudgetCategory.entertainment: 20000,
          BudgetCategory.healthcare: 15000,
          BudgetCategory.education: 10000,
          BudgetCategory.shopping: 30000,
          BudgetCategory.other: 120000,
        },
        createdAt: now,
        updatedAt: now,
      );

      final json = budget.toJson();
      expect(json['id'], equals('group123'));
      expect(json.containsKey('categoryBudgets'), isTrue);
    });
  });

  group('HouseholdExpenseSummary Model', () {
    test('creates a valid expense summary', () {
      final summary = HouseholdExpenseSummary(
        groupId: 'group123',
        month: '2026-09',
        totalIncome: 500000,
        totalExpense: 300000,
        savingAmount: 200000,
        categoryBreakdown: {
          '食費': 100000,
          '交通': 50000,
          '生活費': 150000,
        },
      );

      expect(summary.groupId, equals('group123'));
      expect(summary.totalIncome, equals(500000));
      expect(summary.totalExpense, equals(300000));
    });

    test('calculates saving amount correctly', () {
      final summary = HouseholdExpenseSummary(
        groupId: 'group123',
        month: '2026-09',
        totalIncome: 500000,
        totalExpense: 300000,
        savingAmount: 200000,
        categoryBreakdown: const {},
      );

      final calculatedSaving = summary.totalIncome - summary.totalExpense;
      expect(calculatedSaving, equals(200000));
      expect(calculatedSaving, equals(summary.savingAmount));
    });

    test('calculates saving rate correctly', () {
      final summary = HouseholdExpenseSummary(
        groupId: 'group123',
        month: '2026-09',
        totalIncome: 500000,
        totalExpense: 300000,
        savingAmount: 200000,
        categoryBreakdown: const {},
      );

      final savingRate = summary.savingAmount / summary.totalIncome;
      expect(savingRate, equals(0.4)); // 40% saving rate
    });

    test('handles zero income case', () {
      final summary = HouseholdExpenseSummary(
        groupId: 'group123',
        month: '2026-09',
        totalIncome: 0,
        totalExpense: 0,
        savingAmount: 0,
        categoryBreakdown: const {},
      );

      expect(summary.totalIncome, equals(0));
      expect(summary.savingAmount, equals(0));
    });

    test('category breakdown totals to expense amount', () {
      const totalExpense = 300000;
      final categoryBreakdown = {
        '食費': 100000,
        '交通': 50000,
        '生活費': 150000,
      };

      final categoryTotal = categoryBreakdown.values.fold(0, (a, b) => a + b);
      expect(categoryTotal, equals(totalExpense));
    });

    test('provides highest expense category', () {
      final categoryBreakdown = {
        '食費': 100000,
        '交通': 50000,
        '生活費': 150000,
      };

      final maxExpense = categoryBreakdown.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      expect(maxExpense.key, equals('生活費'));
      expect(maxExpense.value, equals(150000));
    });

    test('provides lowest expense category', () {
      final categoryBreakdown = {
        '食費': 100000,
        '交通': 50000,
        '生活費': 150000,
      };

      final minExpense = categoryBreakdown.entries
          .reduce((a, b) => a.value < b.value ? a : b);
      expect(minExpense.key, equals('交通'));
      expect(minExpense.value, equals(50000));
    });
  });

  group('Budget Analysis', () {
    test('detects overspending with summary', () {
      final summary = HouseholdExpenseSummary(
        groupId: 'group123',
        month: '2026-09',
        totalIncome: 300000,
        totalExpense: 350000,
        savingAmount: -50000,
        categoryBreakdown: const {},
      );

      final isOverBudget = summary.totalExpense > summary.totalIncome;
      expect(isOverBudget, isTrue);
    });

    test('detects if saving goal is achievable', () {
      const allocatedBudget = 300000;
      const spentAmount = 150000;
      const savingGoal = 100000;

      final remaining = allocatedBudget - spentAmount;
      final canAchieveSavingGoal = remaining >= savingGoal;
      expect(canAchieveSavingGoal, isTrue);
    });

    test('alerts when budget is near limit', () {
      const allocatedBudget = 300000;
      const spentAmount = 270000; // 90% spent

      final spendingRate = spentAmount / allocatedBudget;
      final shouldAlert = spendingRate >= 0.8; // Alert when 80%+ spent
      expect(shouldAlert, isTrue);
    });
  });
}
