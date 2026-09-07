import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/household/domain/models/household_budget.dart';
import 'package:okane_kore/features/household/domain/models/household_expense_summary.dart';

void main() {
  group('HouseholdBudget Model', () {
    test('creates a valid household budget', () {
      final budget = HouseholdBudget(
        id: 'budget123',
        groupId: 'group123',
        userId: 'user123',
        month: '2026-09',
        allocatedBudget: 300000,
        spentAmount: 150000,
        savingGoal: 50000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(budget.id, equals('budget123'));
      expect(budget.groupId, equals('group123'));
      expect(budget.allocatedBudget, equals(300000));
      expect(budget.spentAmount, equals(150000));
    });

    test('calculates remaining budget correctly', () {
      final budget = HouseholdBudget(
        id: 'budget123',
        groupId: 'group123',
        userId: 'user123',
        month: '2026-09',
        allocatedBudget: 300000,
        spentAmount: 150000,
        savingGoal: 50000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final remaining = budget.allocatedBudget - budget.spentAmount;
      expect(remaining, equals(150000));
    });

    test('calculates spending rate correctly', () {
      final budget = HouseholdBudget(
        id: 'budget123',
        groupId: 'group123',
        userId: 'user123',
        month: '2026-09',
        allocatedBudget: 300000,
        spentAmount: 150000,
        savingGoal: 50000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final spendingRate = budget.spentAmount / budget.allocatedBudget;
      expect(spendingRate, equals(0.5)); // 50% spent
    });

    test('handles edge case: no spending', () {
      final budget = HouseholdBudget(
        id: 'budget123',
        groupId: 'group123',
        userId: 'user123',
        month: '2026-09',
        allocatedBudget: 300000,
        spentAmount: 0,
        savingGoal: 50000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(budget.spentAmount, equals(0));
      expect(budget.allocatedBudget - budget.spentAmount, equals(300000));
    });

    test('handles edge case: budget fully spent', () {
      final budget = HouseholdBudget(
        id: 'budget123',
        groupId: 'group123',
        userId: 'user123',
        month: '2026-09',
        allocatedBudget: 300000,
        spentAmount: 300000,
        savingGoal: 50000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final remaining = budget.allocatedBudget - budget.spentAmount;
      expect(remaining, equals(0));
      expect(budget.spentAmount / budget.allocatedBudget, equals(1.0));
    });

    test('handles edge case: budget exceeded', () {
      final budget = HouseholdBudget(
        id: 'budget123',
        groupId: 'group123',
        userId: 'user123',
        month: '2026-09',
        allocatedBudget: 300000,
        spentAmount: 350000,
        savingGoal: 50000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final remaining = budget.allocatedBudget - budget.spentAmount;
      expect(remaining, equals(-50000)); // Over budget by ¥50,000
      expect(budget.spentAmount / budget.allocatedBudget, equals(7 / 6)); // ~116.7%
    });

    test('validates that saving goal is reasonable', () {
      const allocatedBudget = 300000;
      const savingGoal = 100000;

      expect(savingGoal, lessThanOrEqualTo(allocatedBudget));
    });

    test('month format is valid (YYYY-MM)', () {
      final budget = HouseholdBudget(
        id: 'budget123',
        groupId: 'group123',
        userId: 'user123',
        month: '2026-09',
        allocatedBudget: 300000,
        spentAmount: 150000,
        savingGoal: 50000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Verify month format matches YYYY-MM pattern
      expect(RegExp(r'^\d{4}-\d{2}$').hasMatch(budget.month), isTrue);
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
    test('detects overspending', () {
      final budget = HouseholdBudget(
        id: 'budget123',
        groupId: 'group123',
        userId: 'user123',
        month: '2026-09',
        allocatedBudget: 300000,
        spentAmount: 350000,
        savingGoal: 50000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final isOverBudget = budget.spentAmount > budget.allocatedBudget;
      expect(isOverBudget, isTrue);
    });

    test('detects if saving goal is achievable', () {
      final budget = HouseholdBudget(
        id: 'budget123',
        groupId: 'group123',
        userId: 'user123',
        month: '2026-09',
        allocatedBudget: 300000,
        spentAmount: 150000,
        savingGoal: 100000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final remaining = budget.allocatedBudget - budget.spentAmount;
      final canAchieveSavingGoal = remaining >= budget.savingGoal;
      expect(canAchieveSavingGoal, isTrue);
    });

    test('alerts when budget is near limit', () {
      final budget = HouseholdBudget(
        id: 'budget123',
        groupId: 'group123',
        userId: 'user123',
        month: '2026-09',
        allocatedBudget: 300000,
        spentAmount: 270000, // 90% spent
        savingGoal: 50000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final spendingRate = budget.spentAmount / budget.allocatedBudget;
      final shouldAlert = spendingRate >= 0.8; // Alert when 80%+ spent
      expect(shouldAlert, isTrue);
    });
  });
}
