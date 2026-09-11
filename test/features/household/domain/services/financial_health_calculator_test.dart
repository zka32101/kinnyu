import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/household/domain/models/household_budget.dart';
import 'package:okane_kore/features/household/domain/models/household_expense_summary.dart';
import 'package:okane_kore/features/household/domain/models/financial_health_score.dart';
import 'package:okane_kore/features/household/domain/services/financial_health_calculator.dart';

void main() {
  group('FinancialHealthCalculator', () {
    late HouseholdBudget testBudget;
    late HouseholdExpenseSummary testSummary;

    setUp(() {
      final now = DateTime.now();
      testBudget = HouseholdBudget(
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

      testSummary = HouseholdExpenseSummary(
        groupId: 'group123',
        month: '2026-09',
        totalIncome: 500000,
        totalExpense: 300000,
        savingAmount: 200000,
        categoryBreakdown: {
          '食費': 60000,
          '光熱費': 25000,
          '交通費': 20000,
          '娯楽': 20000,
          '医療': 15000,
          '教育': 10000,
          'ショッピング': 30000,
          'その他': 120000,
        },
      );
    });

    test('calculates overall score correctly', () {
      final score = FinancialHealthCalculator.calculateScore(
        groupId: 'group123',
        budget: testBudget,
        summary: testSummary,
        investmentAmount: 50000,
        socialContributionAmount: 10000,
      );

      expect(score.overallScore, isNotNull);
      expect(score.overallScore, greaterThanOrEqualTo(0));
      expect(score.overallScore, lessThanOrEqualTo(100));
    });

    test('calculates savings ratio score correctly', () {
      // Test case 1: 40% savings rate (excellent)
      final summary1 = HouseholdExpenseSummary(
        groupId: 'group123',
        month: '2026-09',
        totalIncome: 500000,
        totalExpense: 300000,
        savingAmount: 200000,
        categoryBreakdown: {},
      );

      final score1 = FinancialHealthCalculator.calculateScore(
        groupId: 'group123',
        budget: testBudget,
        summary: summary1,
        investmentAmount: 0,
        socialContributionAmount: 0,
      );

      expect(score1.savingsRatioScore, greaterThanOrEqualTo(90));

      // Test case 2: 10% savings rate (good)
      final summary2 = HouseholdExpenseSummary(
        groupId: 'group123',
        month: '2026-09',
        totalIncome: 500000,
        totalExpense: 450000,
        savingAmount: 50000,
        categoryBreakdown: {},
      );

      final score2 = FinancialHealthCalculator.calculateScore(
        groupId: 'group123',
        budget: testBudget,
        summary: summary2,
        investmentAmount: 0,
        socialContributionAmount: 0,
      );

      expect(score2.savingsRatioScore, lessThan(score1.savingsRatioScore));
    });

    test('calculates budget adherence score correctly', () {
      // Test case 1: Spending 80% of budget (excellent)
      final summary1 = HouseholdExpenseSummary(
        groupId: 'group123',
        month: '2026-09',
        totalIncome: 500000,
        totalExpense: 160000, // 80% of 200000
        savingAmount: 340000,
        categoryBreakdown: {},
      );

      final score1 = FinancialHealthCalculator.calculateScore(
        groupId: 'group123',
        budget: testBudget,
        summary: summary1,
        investmentAmount: 0,
        socialContributionAmount: 0,
      );

      expect(score1.budgetAdherenceScore, greaterThanOrEqualTo(90));

      // Test case 2: Spending 120% of budget (poor)
      final summary2 = HouseholdExpenseSummary(
        groupId: 'group123',
        month: '2026-09',
        totalIncome: 500000,
        totalExpense: 240000, // 120% of 200000
        savingAmount: 260000,
        categoryBreakdown: {},
      );

      final score2 = FinancialHealthCalculator.calculateScore(
        groupId: 'group123',
        budget: testBudget,
        summary: summary2,
        investmentAmount: 0,
        socialContributionAmount: 0,
      );

      expect(score2.budgetAdherenceScore, lessThan(score1.budgetAdherenceScore));
    });

    test('calculates investment engagement score correctly', () {
      // Test case 1: 15% investment rate
      final score1 = FinancialHealthCalculator.calculateScore(
        groupId: 'group123',
        budget: testBudget,
        summary: testSummary,
        investmentAmount: 75000, // 15% of 500000
        socialContributionAmount: 0,
      );

      // Test case 2: 5% investment rate
      final score2 = FinancialHealthCalculator.calculateScore(
        groupId: 'group123',
        budget: testBudget,
        summary: testSummary,
        investmentAmount: 25000, // 5% of 500000
        socialContributionAmount: 0,
      );

      expect(score1.investmentEngagementScore, greaterThan(score2.investmentEngagementScore));
    });

    test('calculates social impact score correctly', () {
      // Test case 1: 5% social contribution rate
      final score1 = FinancialHealthCalculator.calculateScore(
        groupId: 'group123',
        budget: testBudget,
        summary: testSummary,
        investmentAmount: 0,
        socialContributionAmount: 25000, // 5% of 500000
      );

      // Test case 2: No social contribution
      final score2 = FinancialHealthCalculator.calculateScore(
        groupId: 'group123',
        budget: testBudget,
        summary: testSummary,
        investmentAmount: 0,
        socialContributionAmount: 0,
      );

      expect(score1.socialImpactScore, greaterThan(score2.socialImpactScore));
    });

    test('generates correct grade from score', () {
      expect(FinancialHealthScore(
        groupId: 'g1',
        calculatedAt: DateTime.now(),
        overallScore: 95,
        savingsRatioScore: 95,
        budgetAdherenceScore: 95,
        expenseControlScore: 95,
        investmentEngagementScore: 95,
        socialImpactScore: 95,
      ).grade, equals('A+'));

      expect(FinancialHealthScore(
        groupId: 'g1',
        calculatedAt: DateTime.now(),
        overallScore: 85,
        savingsRatioScore: 85,
        budgetAdherenceScore: 85,
        expenseControlScore: 85,
        investmentEngagementScore: 85,
        socialImpactScore: 85,
      ).grade, equals('B+'));

      expect(FinancialHealthScore(
        groupId: 'g1',
        calculatedAt: DateTime.now(),
        overallScore: 55,
        savingsRatioScore: 55,
        budgetAdherenceScore: 55,
        expenseControlScore: 55,
        investmentEngagementScore: 55,
        socialImpactScore: 55,
      ).grade, equals('F'));
    });

    test('generates recommendations for low savings rate', () {
      final summary = HouseholdExpenseSummary(
        groupId: 'group123',
        month: '2026-09',
        totalIncome: 500000,
        totalExpense: 475000, // Only 5% savings
        savingAmount: 25000,
        categoryBreakdown: {},
      );

      final score = FinancialHealthCalculator.calculateScore(
        groupId: 'group123',
        budget: testBudget,
        summary: summary,
        investmentAmount: 0,
        socialContributionAmount: 0,
      );

      final recommendations =
          FinancialHealthCalculator.generateRecommendations(score);

      expect(
        recommendations.any((r) => r.actionType == 'saving'),
        isTrue,
        reason: 'Should recommend saving for low savings rate',
      );
    });

    test('generates recommendations for budget overspending', () {
      final summary = HouseholdExpenseSummary(
        groupId: 'group123',
        month: '2026-09',
        totalIncome: 500000,
        totalExpense: 220000, // 110% of budget
        savingAmount: 280000,
        categoryBreakdown: {},
      );

      final score = FinancialHealthCalculator.calculateScore(
        groupId: 'group123',
        budget: testBudget,
        summary: summary,
        investmentAmount: 0,
        socialContributionAmount: 0,
      );

      final recommendations =
          FinancialHealthCalculator.generateRecommendations(score);

      expect(
        recommendations.any((r) => r.actionType == 'budget'),
        isTrue,
        reason: 'Should recommend budget management for overspending',
      );
    });

    test('score is always between 0 and 100', () {
      // Test with extreme values
      final extremeSummary = HouseholdExpenseSummary(
        groupId: 'group123',
        month: '2026-09',
        totalIncome: 10000,
        totalExpense: 100000, // Over budget
        savingAmount: -90000, // Negative savings
        categoryBreakdown: {},
      );

      final score = FinancialHealthCalculator.calculateScore(
        groupId: 'group123',
        budget: testBudget,
        summary: extremeSummary,
        investmentAmount: 500000,
        socialContributionAmount: 500000,
      );

      expect(score.overallScore, greaterThanOrEqualTo(0));
      expect(score.overallScore, lessThanOrEqualTo(100));
    });
  });
}
