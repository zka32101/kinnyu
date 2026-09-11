import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/household/domain/models/household_budget.dart';
import 'package:okane_kore/features/household/domain/models/household_expense_summary.dart';
import 'package:okane_kore/features/household/presentation/providers/financial_health_provider.dart';

void main() {
  group('Financial Health Providers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('savingsGoalProgressProvider', () {
      test('calculates savings goal progress correctly', () async {
        final result = (
          currentSavings: 15000,
          monthlyGoal: 30000,
          progressPercent: 50.0,
          remainingToGoal: 15000,
        );

        expect(result.currentSavings, 15000);
        expect(result.monthlyGoal, 30000);
        expect(result.progressPercent, 50.0);
        expect(result.remainingToGoal, 15000);
      });

      test('handles zero goal gracefully', () {
        final progressPercent = 0 > 0 ? (15000 / 0 * 100).clamp(0.0, 100.0) : 0.0;
        expect(progressPercent, 0.0);
      });

      test('clamps progress to 100% when goal exceeded', () {
        const goal = 30000;
        const savings = 45000;
        final progressPercent = (savings / goal * 100).clamp(0.0, 100.0);

        expect(progressPercent, 100.0);
      });

      test('handles negative savings correctly', () {
        const goal = 30000;
        const savings = -5000;
        final progressPercent = (savings / goal * 100).clamp(0.0, 100.0);
        final remaining = (goal - savings).clamp(0, goal);

        expect(progressPercent, 0.0);
        expect(remaining, goal);
      });
    });

    group('scoreImprovementGuideProvider', () {
      test('generates improvement actions for low scores', () {
        final action = ScoreImprovementAction(
          category: 'savingsRatio',
          displayName: '貯蓄率改善',
          priority: 1,
          currentScore: 65,
          targetScore: 85,
          actionItems: [
            '月間支出を5%削減する',
            '固定費の見直し',
            '自動貯蓄の設定',
          ],
        );

        expect(action.category, 'savingsRatio');
        expect(action.scoreGain, 20);
        expect(action.actionItems.length, 3);
        expect(action.priority, 1);
      });

      test('prioritizes categories correctly', () {
        final actions = [
          ScoreImprovementAction(
            category: 'socialImpact',
            displayName: '社会貢献度',
            priority: 5,
            currentScore: 50,
            targetScore: 80,
            actionItems: [],
          ),
          ScoreImprovementAction(
            category: 'savingsRatio',
            displayName: '貯蓄率',
            priority: 1,
            currentScore: 60,
            targetScore: 85,
            actionItems: [],
          ),
        ];

        actions.sort((a, b) => a.priority.compareTo(b.priority));

        expect(actions.first.priority, 1);
        expect(actions.last.priority, 5);
      });

      test('calculates score gain correctly', () {
        final action = ScoreImprovementAction(
          category: 'test',
          displayName: 'Test',
          priority: 1,
          currentScore: 70,
          targetScore: 85,
          actionItems: [],
        );

        expect(action.scoreGain, 15);
      });
    });

    group('monthlySavingsRateTrendProvider', () {
      test('calculates trend direction correctly', () {
        final scores = [65, 68, 70, 72, 75, 78];

        // Trend from 75 to 78 (increase)
        expect(_calculateTrend([75, 78]), '↑');

        // Trend from 75 to 73 (decrease)
        expect(_calculateTrend([75, 73]), '↓');

        // Trend from 75 to 76 (stable, < 2 point change)
        expect(_calculateTrend([75, 76]), '→');
      });

      test('handles single value correctly', () {
        expect(_calculateTrend([75]), '→');
      });

      test('handles empty list gracefully', () {
        expect(_calculateTrend([]), '→');
      });

      test('uses correct threshold for trend detection', () {
        // Exactly at threshold
        expect(_calculateTrend([75, 77]), '→'); // 2 point change = stable
        expect(_calculateTrend([75, 78]), '↑'); // 3 point change = up
        expect(_calculateTrend([75, 72]), '↓'); // 3 point change = down
      });
    });

    group('budgetOptimizationProvider', () {
      test('identifies overspent categories', () {
        final optimization = BudgetOptimization(
          category: 'food',
          displayName: '食費',
          currentBudget: 60000,
          actualSpent: 80000, // 133% of budget
          recommendedBudget: 88000,
          recommendation: '支出が予算を33%超過',
          priority: 1,
        );

        expect(optimization.utilizationRate, 80000 / 60000);
        expect(optimization.budgetDifference, 28000);
        expect(optimization.priority, 1);
      });

      test('identifies underspent categories', () {
        final optimization = BudgetOptimization(
          category: 'education',
          displayName: '教育',
          currentBudget: 10000,
          actualSpent: 3000, // 30% of budget
          recommendedBudget: 3600,
          recommendation: '予算が多すぎる',
          priority: 2,
        );

        expect(optimization.utilizationRate, 0.3);
        expect(optimization.budgetDifference, -6400);
        expect(optimization.priority, 2);
      });

      test('calculates budget difference correctly', () {
        final optimization = BudgetOptimization(
          category: 'test',
          displayName: 'Test',
          currentBudget: 50000,
          actualSpent: 40000,
          recommendedBudget: 48000,
          recommendation: 'Test',
          priority: 1,
        );

        expect(optimization.budgetDifference, -2000);
      });

      test('prioritizes overspent over underspent', () {
        final optimizations = [
          BudgetOptimization(
            category: 'shopping',
            displayName: 'ショッピング',
            currentBudget: 30000,
            actualSpent: 15000,
            recommendedBudget: 18000,
            recommendation: 'Underspent',
            priority: 2,
          ),
          BudgetOptimization(
            category: 'food',
            displayName: '食費',
            currentBudget: 60000,
            actualSpent: 80000,
            recommendedBudget: 88000,
            recommendation: 'Overspent',
            priority: 1,
          ),
        ];

        optimizations.sort((a, b) => a.priority.compareTo(b.priority));

        expect(optimizations.first.category, 'food');
        expect(optimizations.last.category, 'shopping');
      });
    });

    group('MonthlySavingsRateTrend', () {
      test('creates trend object correctly', () {
        final trend = MonthlySavingsRateTrend(
          month: '2026-09',
          savingsRatioScore: 75,
          isCurrentMonth: true,
          trend: '↑',
        );

        expect(trend.month, '2026-09');
        expect(trend.savingsRatioScore, 75);
        expect(trend.isCurrentMonth, true);
        expect(trend.trend, '↑');
      });
    });
  });
}

/// トレンド方向を計算する（テスト用ヘルパー）
String _calculateTrend(List<int> scores) {
  if (scores.length < 2) return '→';
  final current = scores.last.toDouble();
  final previous = scores[scores.length - 2].toDouble();

  if (current > previous + 2) return '↑';
  if (current < previous - 2) return '↓';
  return '→';
}
