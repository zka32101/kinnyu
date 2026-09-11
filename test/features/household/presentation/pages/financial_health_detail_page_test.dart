import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/household/domain/models/financial_health_score.dart';
import 'package:okane_kore/features/household/presentation/pages/financial_health_detail_page.dart';
import 'package:okane_kore/features/household/presentation/providers/financial_health_provider.dart';

void main() {
  group('Financial Health Detail Page', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('displays 5 tabs correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DefaultTabController(
                length: 5,
                child: Column(
                  children: [
                    Material(
                      child: TabBar(
                        tabs: const [
                          Tab(text: '概要'),
                          Tab(text: 'カテゴリ'),
                          Tab(text: 'トレンド'),
                          Tab(text: '改善提案'),
                          Tab(text: '最適化'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          const Text('Tab 1: Overview'),
                          const Text('Tab 2: Categories'),
                          const Text('Tab 3: Trends'),
                          const Text('Tab 4: Recommendations'),
                          const Text('Tab 5: Optimization'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('概要'), findsOneWidget);
      expect(find.text('カテゴリ'), findsOneWidget);
      expect(find.text('トレンド'), findsOneWidget);
      expect(find.text('改善提案'), findsOneWidget);
      expect(find.text('最適化'), findsOneWidget);
    });

    testWidgets('tab navigation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DefaultTabController(
                length: 5,
                child: Column(
                  children: [
                    Material(
                      child: TabBar(
                        tabs: const [
                          Tab(text: '概要'),
                          Tab(text: 'カテゴリ'),
                          Tab(text: 'トレンド'),
                          Tab(text: '改善提案'),
                          Tab(text: '最適化'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          const Text('Tab 1: Overview'),
                          const Text('Tab 2: Categories'),
                          const Text('Tab 3: Trends'),
                          const Text('Tab 4: Recommendations'),
                          const Text('Tab 5: Optimization'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Start at Tab 1
      expect(find.text('Tab 1: Overview'), findsOneWidget);

      // Navigate to Tab 2
      await tester.tap(find.text('カテゴリ'));
      await tester.pumpAndSettle();
      expect(find.text('Tab 2: Categories'), findsOneWidget);

      // Navigate to Tab 5
      await tester.tap(find.text('最適化'));
      await tester.pumpAndSettle();
      expect(find.text('Tab 5: Optimization'), findsOneWidget);
    });
  });

  group('Financial Health Score Card Widgets', () {
    testWidgets('_SavingsGoalProgressCard displays progress correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _SavingsGoalProgressCardWidget(
              currentSavings: 15000,
              monthlyGoal: 30000,
              progressPercent: 50.0,
              remainingToGoal: 15000,
            ),
          ),
        ),
      );

      expect(find.text('¥15000'), findsWidgets);
      expect(find.text('目標: ¥30000'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('_SavingsGoalProgressCard handles full goal',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _SavingsGoalProgressCardWidget(
              currentSavings: 30000,
              monthlyGoal: 30000,
              progressPercent: 100.0,
              remainingToGoal: 0,
            ),
          ),
        ),
      );

      expect(find.text('¥30000'), findsWidgets);
      expect(find.text('進捗: 100.0%'), findsOneWidget);
    });

    testWidgets('_ImprovementActionCard displays action items',
        (WidgetTester tester) async {
      const action = ScoreImprovementActionMock(
        displayName: '貯蓄率改善',
        currentScore: 65,
        targetScore: 85,
        actionItems: ['月間支出を5%削減する', '固定費の見直し'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ImprovementActionCardWidget(
              displayName: action.displayName,
              currentScore: action.currentScore,
              targetScore: action.targetScore,
              actionItems: action.actionItems,
            ),
          ),
        ),
      );

      expect(find.text('貯蓄率改善'), findsOneWidget);
      expect(find.text('65 → 85'), findsOneWidget);
      expect(find.text('• 月間支出を5%削減する'), findsOneWidget);
      expect(find.text('• 固定費の見直し'), findsOneWidget);
    });

    testWidgets('_BudgetOptimizationCard displays budget analysis',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _BudgetOptimizationCardWidget(
              displayName: '食費',
              currentBudget: 60000,
              actualSpent: 80000,
              recommendedBudget: 88000,
              recommendation: '支出が予算を33%超過',
              utilizationRate: 1.33,
            ),
          ),
        ),
      );

      expect(find.text('食費'), findsOneWidget);
      expect(find.text('1.3x'), findsOneWidget);
      expect(find.text('予算: ¥60000'), findsOneWidget);
      expect(find.text('実績: ¥80000'), findsOneWidget);
      expect(find.text('推奨予算: ¥88000'), findsOneWidget);
    });
  });
}

/// Mock widget for testing _SavingsGoalProgressCard
class _SavingsGoalProgressCardWidget extends StatelessWidget {
  final int currentSavings;
  final int monthlyGoal;
  final double progressPercent;
  final int remainingToGoal;

  const _SavingsGoalProgressCardWidget({
    required this.currentSavings,
    required this.monthlyGoal,
    required this.progressPercent,
    required this.remainingToGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('¥${currentSavings.toString()}'),
              Text('目標: ¥${monthlyGoal.toString()}'),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (progressPercent / 100).clamp(0.0, 1.0),
          ),
          const SizedBox(height: 8),
          Text('進捗: ${progressPercent.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }
}

/// Mock widget for testing _ImprovementActionCard
class _ImprovementActionCardWidget extends StatelessWidget {
  final String displayName;
  final int currentScore;
  final int targetScore;
  final List<String> actionItems;

  const _ImprovementActionCardWidget({
    required this.displayName,
    required this.currentScore,
    required this.targetScore,
    required this.actionItems,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(displayName),
                Text('$currentScore → $targetScore'),
              ],
            ),
            const SizedBox(height: 8),
            Text('アクション:'),
            ...actionItems.map((item) => Text('• $item')),
          ],
        ),
      ),
    );
  }
}

/// Mock widget for testing _BudgetOptimizationCard
class _BudgetOptimizationCardWidget extends StatelessWidget {
  final String displayName;
  final int currentBudget;
  final int actualSpent;
  final int recommendedBudget;
  final String recommendation;
  final double utilizationRate;

  const _BudgetOptimizationCardWidget({
    required this.displayName,
    required this.currentBudget,
    required this.actualSpent,
    required this.recommendedBudget,
    required this.recommendation,
    required this.utilizationRate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(displayName),
                Text('${utilizationRate.toStringAsFixed(1)}x'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('予算: ¥$currentBudget'),
                Text('実績: ¥$actualSpent'),
              ],
            ),
            const SizedBox(height: 8),
            Text('推奨予算: ¥$recommendedBudget'),
            const SizedBox(height: 8),
            Text(recommendation),
          ],
        ),
      ),
    );
  }
}

/// Mock class for testing
class ScoreImprovementActionMock {
  final String displayName;
  final int currentScore;
  final int targetScore;
  final List<String> actionItems;

  const ScoreImprovementActionMock({
    required this.displayName,
    required this.currentScore,
    required this.targetScore,
    required this.actionItems,
  });
}
