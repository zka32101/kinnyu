import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/household/domain/models/financial_insight.dart';
import 'package:okane_kore/features/household/domain/models/household_expense_summary.dart';
import 'package:okane_kore/features/household/domain/models/financial_health_score.dart';
import 'package:okane_kore/features/household/domain/services/financial_insights_service.dart';

void main() {
  group('FinancialInsightsService.analyzeAnomalies', () {
    late HouseholdExpenseSummary currentMonth;
    late HouseholdExpenseSummary previousMonth;
    late Map<String, int> budgetTargets;

    setUp(() {
      budgetTargets = {
        'food': 60000,
        'transportation': 20000,
        'utilities': 10000,
        'entertainment': 15000,
      };
    });

    test('detects spending increase anomaly (>20% variance)', () {
      previousMonth = HouseholdExpenseSummary(
        groupId: 'group1',
        totalExpense: 100000,
        totalIncome: 300000,
        savingAmount: 200000,
        month: '2026-08',
        categoryBreakdown: {
          'food': 50000,
          'transportation': 20000,
          'utilities': 10000,
          'entertainment': 20000,
        },
      );

      currentMonth = HouseholdExpenseSummary(
        groupId: 'group1',
        totalExpense: 130000,
        totalIncome: 300000,
        savingAmount: 170000,
        month: '2026-09',
        categoryBreakdown: {
          'food': 68000, // 36% increase - should be detected
          'transportation': 20000,
          'utilities': 10000,
          'entertainment': 32000, // 60% increase - critical
        },
      );

      final anomalies = FinancialInsightsService.analyzeAnomalies(
        currentMonth,
        previousMonth,
        budgetTargets,
      );

      expect(anomalies, isNotEmpty);
      expect(anomalies.length, equals(2));

      // Check food anomaly
      final foodAnomaly = anomalies.firstWhere((a) => a.categoryName == 'food');
      expect(foodAnomaly.variancePercent, equals(36));
      expect(foodAnomaly.trendDirection, equals(TrendDirection.increasing));
      expect(foodAnomaly.severity, equals(AnomalySeverity.warning));

      // Check entertainment anomaly (critical due to 60%)
      final entertainmentAnomaly =
          anomalies.firstWhere((a) => a.categoryName == 'entertainment');
      expect(entertainmentAnomaly.variancePercent, equals(60));
      expect(entertainmentAnomaly.severity, equals(AnomalySeverity.critical));
    });

    test('detects spending decrease anomaly', () {
      previousMonth = HouseholdExpenseSummary(
        groupId: 'group1',
        totalExpense: 100000,
        totalIncome: 300000,
        savingAmount: 200000,
        month: '2026-08',
        categoryBreakdown: {
          'food': 50000,
          'transportation': 20000,
        },
      );

      currentMonth = HouseholdExpenseSummary(
        groupId: 'group1',
        totalExpense: 60000,
        totalIncome: 300000,
        savingAmount: 240000,
        month: '2026-09',
        categoryBreakdown: {
          'food': 35000, // 30% decrease
          'transportation': 20000,
        },
      );

      final anomalies = FinancialInsightsService.analyzeAnomalies(
        currentMonth,
        previousMonth,
        budgetTargets,
      );

      final foodAnomaly = anomalies.firstWhere((a) => a.categoryName == 'food');
      expect(foodAnomaly.trendDirection, equals(TrendDirection.decreasing));
      expect(foodAnomaly.severity, equals(AnomalySeverity.critical));
    });

    test('ignores anomalies below 20% variance threshold', () {
      previousMonth = HouseholdExpenseSummary(
        groupId: 'group1',
        totalExpense: 100000,
        totalIncome: 300000,
        savingAmount: 200000,
        month: '2026-08',
        categoryBreakdown: {
          'food': 50000,
          'transportation': 20000,
        },
      );

      currentMonth = HouseholdExpenseSummary(
        groupId: 'group1',
        totalExpense: 102000,
        totalIncome: 300000,
        savingAmount: 198000,
        month: '2026-09',
        categoryBreakdown: {
          'food': 52000, // Only 4% increase - below threshold
          'transportation': 20000,
        },
      );

      final anomalies = FinancialInsightsService.analyzeAnomalies(
        currentMonth,
        previousMonth,
        budgetTargets,
      );

      expect(anomalies, isEmpty);
    });

    test('handles first month edge case (skips categories with zero previous data)', () {
      previousMonth = HouseholdExpenseSummary(
        groupId: 'group1',
        totalExpense: 0,
        totalIncome: 0,
        savingAmount: 0,
        month: '2026-08',
        categoryBreakdown: {
          'food': 0,
          'transportation': 0,
        },
      );

      currentMonth = HouseholdExpenseSummary(
        groupId: 'group1',
        totalExpense: 70000,
        totalIncome: 300000,
        savingAmount: 230000,
        month: '2026-09',
        categoryBreakdown: {
          'food': 50000,
          'transportation': 20000,
        },
      );

      final anomalies = FinancialInsightsService.analyzeAnomalies(
        currentMonth,
        previousMonth,
        budgetTargets,
      );

      // Should not detect anomalies when previous is 0
      expect(anomalies, isEmpty);
    });

    test('handles flat spending (no anomalies)', () {
      previousMonth = HouseholdExpenseSummary(
        groupId: 'group1',
        totalExpense: 100000,
        totalIncome: 300000,
        savingAmount: 200000,
        month: '2026-08',
        categoryBreakdown: {
          'food': 50000,
          'transportation': 20000,
          'utilities': 10000,
          'entertainment': 20000,
        },
      );

      currentMonth = HouseholdExpenseSummary(
        groupId: 'group1',
        totalExpense: 100000,
        totalIncome: 300000,
        savingAmount: 200000,
        month: '2026-09',
        categoryBreakdown: {
          'food': 50000,
          'transportation': 20000,
          'utilities': 10000,
          'entertainment': 20000,
        },
      );

      final anomalies = FinancialInsightsService.analyzeAnomalies(
        currentMonth,
        previousMonth,
        budgetTargets,
      );

      expect(anomalies, isEmpty);
    });

    test('sorts anomalies by severity (critical first)', () {
      previousMonth = HouseholdExpenseSummary(
        groupId: 'group1',
        totalExpense: 100000,
        totalIncome: 300000,
        savingAmount: 200000,
        month: '2026-08',
        categoryBreakdown: {
          'food': 50000,
          'transportation': 20000,
          'entertainment': 10000,
        },
      );

      currentMonth = HouseholdExpenseSummary(
        groupId: 'group1',
        totalExpense: 160000,
        totalIncome: 300000,
        savingAmount: 140000,
        month: '2026-09',
        categoryBreakdown: {
          'food': 85000, // 70% - critical
          'transportation': 30000, // 50% - critical
          'entertainment': 25000, // 150% - critical
        },
      );

      final anomalies = FinancialInsightsService.analyzeAnomalies(
        currentMonth,
        previousMonth,
        budgetTargets,
      );

      expect(anomalies, isNotEmpty);
      for (int i = 0; i < anomalies.length - 1; i++) {
        expect(anomalies[i].severity.index,
            greaterThanOrEqualTo(anomalies[i + 1].severity.index));
      }
    });

    test('calculates correct variance percentage', () {
      previousMonth = HouseholdExpenseSummary(
        groupId: 'group1',
        totalExpense: 100000,
        totalIncome: 300000,
        savingAmount: 200000,
        month: '2026-08',
        categoryBreakdown: {'food': 100},
      );

      currentMonth = HouseholdExpenseSummary(
        groupId: 'group1',
        totalExpense: 130,
        totalIncome: 300000,
        savingAmount: 299870,
        month: '2026-09',
        categoryBreakdown: {'food': 130},
      );

      final anomalies = FinancialInsightsService.analyzeAnomalies(
        currentMonth,
        previousMonth,
        budgetTargets,
      );

      expect(anomalies.first.variancePercent, equals(30));
    });
  });

  group('FinancialInsightsService.generateRecommendations', () {
    late FinancialHealthScore score;
    late List<FinancialHealthScoreTrend> trends;
    late List<SpendingAnomaly> anomalies;

    setUp(() {
      score = FinancialHealthScore(
        groupId: 'group1',
        calculatedAt: DateTime.now(),
        overallScore: 70,
        savingsRatioScore: 65,
        budgetAdherenceScore: 70,
        expenseControlScore: 75,
        investmentEngagementScore: 70,
        socialImpactScore: 70,
      );

      trends = [
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-07',
          overallScore: 68,
          categoryScores: {'savingsRatio': 63},
        ),
      ];

      anomalies = [];
    });

    test('generates recommendations for lowest scoring categories', () {
      final recommendations = FinancialInsightsService.generateRecommendations(
        score,
        trends,
        anomalies,
      );

      expect(recommendations, isNotEmpty);
      expect(recommendations.length, greaterThanOrEqualTo(1));

      // All should be recommendations type
      expect(
        recommendations.every((r) => r.type == InsightType.recommendation),
        isTrue,
      );

      // Should have priorities 1, 2, 3
      expect(
        recommendations.every((r) => r.priority >= 1 && r.priority <= 3),
        isTrue,
      );
    });

    test('generates insights from critical anomalies', () {
      anomalies = [
        SpendingAnomaly(
          categoryName: 'food',
          previousMonthAmount: 50000,
          currentMonthAmount: 85000,
          variancePercent: 70,
          trendDirection: TrendDirection.increasing,
          severity: AnomalySeverity.critical,
          description: 'Food spending spike',
        ),
      ];

      final recommendations = FinancialInsightsService.generateRecommendations(
        score,
        trends,
        anomalies,
      );

      expect(recommendations, isNotEmpty);

      // Should include anomaly-based insight
      final anomalyInsights =
          recommendations.where((r) => r.type == InsightType.anomaly);
      expect(anomalyInsights, isNotEmpty);
    });

    test('handles empty trends list', () {
      final recommendations = FinancialInsightsService.generateRecommendations(
        score,
        [],
        anomalies,
      );

      expect(recommendations, isNotEmpty);
    });

    test('handles empty anomalies list', () {
      final recommendations = FinancialInsightsService.generateRecommendations(
        score,
        trends,
        [],
      );

      expect(recommendations, isNotEmpty);
    });

    test('generates actionable items for each recommendation', () {
      final recommendations = FinancialInsightsService.generateRecommendations(
        score,
        trends,
        anomalies,
      );

      for (final rec in recommendations) {
        if (rec.type == InsightType.recommendation) {
          expect(rec.actionableItems, isNotEmpty);
          expect(rec.actionableItems.length, greaterThan(0));
        }
      }
    });

    test('sets appropriate expiration dates', () {
      final recommendations = FinancialInsightsService.generateRecommendations(
        score,
        trends,
        anomalies,
      );

      final now = DateTime.now();
      for (final rec in recommendations) {
        expect(rec.expiresAt.isAfter(now), isTrue);
      }
    });

    test('calculates score impact correctly', () {
      final recommendations = FinancialInsightsService.generateRecommendations(
        score,
        trends,
        anomalies,
      );

      for (final rec in recommendations) {
        if (rec.type == InsightType.recommendation) {
          expect(rec.scoreImpact, greaterThan(0));
          expect(rec.scoreImpact, lessThanOrEqualTo(100));
        }
      }
    });
  });

  group('FinancialInsightsService.assessUserContext', () {
    test('classifies starter user (less than 2 months of data)', () {
      final trends = [
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-09',
          overallScore: 55,
          categoryScores: {},
        ),
      ];

      final context =
          FinancialInsightsService.assessUserContext(trends, 55);

      expect(context.userState, equals(UserState.starter));
    });

    test('classifies improver user (60-80 score, 2+ months)', () {
      final trends = [
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-07',
          overallScore: 60,
          categoryScores: {},
        ),
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-08',
          overallScore: 70,
          categoryScores: {},
        ),
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-09',
          overallScore: 75,
          categoryScores: {},
        ),
      ];

      final context =
          FinancialInsightsService.assessUserContext(trends, 75);

      expect(context.userState, equals(UserState.improver));
    });

    test('classifies achiever user (>80 score)', () {
      final trends = [
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-07',
          overallScore: 82,
          categoryScores: {},
        ),
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-08',
          overallScore: 85,
          categoryScores: {},
        ),
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-09',
          overallScore: 88,
          categoryScores: {},
        ),
      ];

      final context =
          FinancialInsightsService.assessUserContext(trends, 88);

      expect(context.userState, equals(UserState.achiever));
    });

    test('classifies starter when score < 60', () {
      final trends = [
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-07',
          overallScore: 45,
          categoryScores: {},
        ),
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-08',
          overallScore: 50,
          categoryScores: {},
        ),
      ];

      final context = FinancialInsightsService.assessUserContext(trends, 50);

      expect(context.userState, equals(UserState.starter));
    });

    test('handles empty trends (returns starter status)', () {
      final context = FinancialInsightsService.assessUserContext([], 70);

      expect(context.userState, equals(UserState.starter));
      expect(context.scoreTrajectory, equals(ScoreTrajectory.stable));
    });

    test('detects improving trajectory', () {
      final trends = [
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-07',
          overallScore: 65,
          categoryScores: {},
        ),
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-08',
          overallScore: 70,
          categoryScores: {},
        ),
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-09',
          overallScore: 75,
          categoryScores: {},
        ),
      ];

      final context =
          FinancialInsightsService.assessUserContext(trends, 75);

      expect(context.scoreTrajectory, equals(ScoreTrajectory.improving));
    });

    test('detects declining trajectory', () {
      final trends = [
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-07',
          overallScore: 85,
          categoryScores: {},
        ),
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-08',
          overallScore: 75,
          categoryScores: {},
        ),
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-09',
          overallScore: 70,
          categoryScores: {},
        ),
      ];

      final context =
          FinancialInsightsService.assessUserContext(trends, 70);

      expect(context.scoreTrajectory, equals(ScoreTrajectory.declining));
    });

    test('detects stable trajectory', () {
      final trends = [
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-07',
          overallScore: 75,
          categoryScores: {},
        ),
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-08',
          overallScore: 75,
          categoryScores: {},
        ),
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-09',
          overallScore: 76,
          categoryScores: {},
        ),
      ];

      final context =
          FinancialInsightsService.assessUserContext(trends, 76);

      expect(context.scoreTrajectory, equals(ScoreTrajectory.stable));
    });

    test('calculates three-month average correctly', () {
      final trends = [
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-07',
          overallScore: 60,
          categoryScores: {},
        ),
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-08',
          overallScore: 70,
          categoryScores: {},
        ),
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-09',
          overallScore: 80,
          categoryScores: {},
        ),
      ];

      final context =
          FinancialInsightsService.assessUserContext(trends, 80);

      expect(context.previousThreeMonthAverage, equals(70));
    });

    test('calculates months at current level', () {
      final trends = [
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-05',
          overallScore: 50,
          categoryScores: {},
        ),
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-07',
          overallScore: 75,
          categoryScores: {},
        ),
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-08',
          overallScore: 76,
          categoryScores: {},
        ),
        FinancialHealthScoreTrend(
          groupId: 'group1',
          month: '2026-09',
          overallScore: 74,
          categoryScores: {},
        ),
      ];

      final context =
          FinancialInsightsService.assessUserContext(trends, 74);

      // Should have 3 months within ±5 of current score
      expect(context.monthsAtCurrentLevel, equals(3));
    });
  });

  group('FinancialInsightsService.composeContextualMessage', () {
    late InsightContext context;

    setUp(() {
      context = InsightContext(
        userState: UserState.improver,
        scoreTrajectory: ScoreTrajectory.improving,
        monthsAtCurrentLevel: 2,
        previousThreeMonthAverage: 72,
        benchmarkPercentile: 65.0,
      );
    });

    test('composes Japanese recommendation message', () {
      final insight = FinancialInsight(
        id: 'test1',
        type: InsightType.recommendation,
        title: '食費を改善して +8 ポイント',
        description: '食費の支出を ¥8000 削減することで、スコアを +8 ポイント改善できます。',
        category: 'food',
        priority: 1,
        scoreImpact: 8,
        actionableItems: [],
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        contextIndicators: {},
      );

      final message = FinancialInsightsService.composeContextualMessage(
        insight,
        context,
        'ja',
      );

      expect(message, isNotEmpty);
      expect(message.contains('改善'), isTrue);
    });

    test('composes English recommendation message', () {
      final insight = FinancialInsight(
        id: 'test1',
        type: InsightType.recommendation,
        title: 'Improve Food Score by +8',
        description: 'Cut food spending by ¥8000/month to gain +8 points.',
        category: 'food',
        priority: 1,
        scoreImpact: 8,
        actionableItems: [],
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        contextIndicators: {},
      );

      final message = FinancialInsightsService.composeContextualMessage(
        insight,
        context,
        'en',
      );

      expect(message, isNotEmpty);
    });

    test('composes anomaly message from insight description', () {
      final insight = FinancialInsight(
        id: 'test2',
        type: InsightType.anomaly,
        title: 'Alert: Food spending surge',
        description: '食費 の支出が前月比70%増加 しました（¥50000 → ¥85000）',
        category: 'food',
        priority: 1,
        scoreImpact: -5,
        actionableItems: [],
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        contextIndicators: {},
      );

      final message = FinancialInsightsService.composeContextualMessage(
        insight,
        context,
        'ja',
      );

      expect(message, equals(insight.description));
    });

    test('composes milestone message', () {
      final insight = FinancialInsight(
        id: 'test3',
        type: InsightType.milestone,
        title: 'Score Milestone: 80 Reached!',
        description: 'You have reached a score of 80!',
        category: 'overall',
        priority: 1,
        scoreImpact: 0,
        actionableItems: [],
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        contextIndicators: {},
      );

      final message = FinancialInsightsService.composeContextualMessage(
        insight,
        context,
        'ja',
      );

      expect(message, isNotEmpty);
    });

    test('composes trend message', () {
      final insight = FinancialInsight(
        id: 'test4',
        type: InsightType.trend,
        title: 'Improving Trend',
        description: 'Your score has been improving for 3 months straight.',
        category: 'overall',
        priority: 1,
        scoreImpact: 0,
        actionableItems: [],
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        contextIndicators: {},
      );

      final message = FinancialInsightsService.composeContextualMessage(
        insight,
        context,
        'ja',
      );

      expect(message, equals(insight.description));
    });
  });

  group('FinancialInsightsService.prioritizeInsights', () {
    test('sorts insights by priority (1 highest)', () {
      final insights = [
        FinancialInsight(
          id: '1',
          type: InsightType.recommendation,
          title: 'Test 1',
          description: 'Test',
          category: 'food',
          priority: 3,
          scoreImpact: 5,
          actionableItems: [],
          generatedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
          contextIndicators: {},
        ),
        FinancialInsight(
          id: '2',
          type: InsightType.recommendation,
          title: 'Test 2',
          description: 'Test',
          category: 'food',
          priority: 1,
          scoreImpact: 8,
          actionableItems: [],
          generatedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
          contextIndicators: {},
        ),
        FinancialInsight(
          id: '3',
          type: InsightType.recommendation,
          title: 'Test 3',
          description: 'Test',
          category: 'food',
          priority: 2,
          scoreImpact: 6,
          actionableItems: [],
          generatedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
          contextIndicators: {},
        ),
      ];

      final prioritized = FinancialInsightsService.prioritizeInsights(insights, 3);

      expect(prioritized[0].priority, equals(1));
      expect(prioritized[1].priority, equals(2));
      expect(prioritized[2].priority, equals(3));
    });

    test('respects max count limit', () {
      final insights = [
        FinancialInsight(
          id: '1',
          type: InsightType.recommendation,
          title: 'Test 1',
          description: 'Test',
          category: 'food',
          priority: 1,
          scoreImpact: 5,
          actionableItems: [],
          generatedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
          contextIndicators: {},
        ),
        FinancialInsight(
          id: '2',
          type: InsightType.recommendation,
          title: 'Test 2',
          description: 'Test',
          category: 'food',
          priority: 2,
          scoreImpact: 8,
          actionableItems: [],
          generatedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
          contextIndicators: {},
        ),
        FinancialInsight(
          id: '3',
          type: InsightType.recommendation,
          title: 'Test 3',
          description: 'Test',
          category: 'food',
          priority: 3,
          scoreImpact: 6,
          actionableItems: [],
          generatedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
          contextIndicators: {},
        ),
      ];

      final prioritized = FinancialInsightsService.prioritizeInsights(insights, 2);

      expect(prioritized.length, equals(2));
    });

    test('returns empty list when maxCount is 0', () {
      final insights = [
        FinancialInsight(
          id: '1',
          type: InsightType.recommendation,
          title: 'Test 1',
          description: 'Test',
          category: 'food',
          priority: 1,
          scoreImpact: 5,
          actionableItems: [],
          generatedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
          contextIndicators: {},
        ),
      ];

      final prioritized =
          FinancialInsightsService.prioritizeInsights(insights, 0);

      expect(prioritized, isEmpty);
    });

    test('handles empty insights list', () {
      final prioritized =
          FinancialInsightsService.prioritizeInsights([], 3);

      expect(prioritized, isEmpty);
    });
  });

  group('FinancialInsightsService - Edge Cases', () {
    test('handles all categories overspent scenario', () {
      final previousMonth = HouseholdExpenseSummary(
        groupId: 'group1',
        totalExpense: 100000,
        totalIncome: 300000,
        savingAmount: 200000,
        month: '2026-08',
        categoryBreakdown: {
          'food': 30000,
          'transportation': 20000,
          'utilities': 15000,
          'entertainment': 35000,
        },
      );

      final currentMonth = HouseholdExpenseSummary(
        groupId: 'group1',
        totalExpense: 150000,
        totalIncome: 300000,
        savingAmount: 150000,
        month: '2026-09',
        categoryBreakdown: {
          'food': 50000,
          'transportation': 35000,
          'utilities': 30000,
          'entertainment': 35000,
        },
      );

      final anomalies = FinancialInsightsService.analyzeAnomalies(
        currentMonth,
        previousMonth,
        {'food': 60000, 'transportation': 20000},
      );

      expect(anomalies, isNotEmpty);
      // Most should be critical or warning
      final severeAnomalies = anomalies
          .where((a) => a.severity == AnomalySeverity.critical ||
              a.severity == AnomalySeverity.warning)
          .toList();
      expect(severeAnomalies, isNotEmpty);
    });

    test('handles income spike scenario', () {
      // Income spike doesn't directly affect anomaly detection
      // but we should handle it gracefully
      final previousMonth = HouseholdExpenseSummary(
        groupId: 'group1',
        totalExpense: 100000,
        totalIncome: 300000,
        savingAmount: 200000,
        month: '2026-08',
        categoryBreakdown: {'food': 50000},
      );

      final currentMonth = HouseholdExpenseSummary(
        groupId: 'group1',
        totalExpense: 120000,
        totalIncome: 600000,
        savingAmount: 480000, // Income doubled
        month: '2026-09',
        categoryBreakdown: {'food': 60000}, // 20% increase
      );

      final anomalies = FinancialInsightsService.analyzeAnomalies(
        currentMonth,
        previousMonth,
        {'food': 60000},
      );

      expect(anomalies, isNotEmpty);
      // Anomaly should still be detected despite income increase
      final foodAnomaly =
          anomalies.firstWhere((a) => a.categoryName == 'food');
      expect(foodAnomaly.variancePercent, equals(20));
    });

    test('handles missing categories gracefully', () {
      final previousMonth = HouseholdExpenseSummary(
        groupId: 'group1',
        totalExpense: 50000,
        totalIncome: 300000,
        savingAmount: 250000,
        month: '2026-08',
        categoryBreakdown: {'food': 50000},
      );

      final currentMonth = HouseholdExpenseSummary(
        groupId: 'group1',
        totalExpense: 80000,
        totalIncome: 300000,
        savingAmount: 220000,
        month: '2026-09',
        categoryBreakdown: {
          'food': 50000,
          'transportation': 30000, // New category in current month
        },
      );

      final anomalies = FinancialInsightsService.analyzeAnomalies(
        currentMonth,
        previousMonth,
        {},
      );

      // Should handle new category (previous = 0, skipped)
      expect(anomalies, isEmpty);
    });

    test('generates recommendations even with minimal score data', () {
      final score = FinancialHealthScore(
        groupId: 'group1',
        calculatedAt: DateTime.now(),
        overallScore: 40,
        savingsRatioScore: 30,
        budgetAdherenceScore: 40,
        expenseControlScore: 40,
        investmentEngagementScore: 40,
        socialImpactScore: 50,
      );

      final recommendations = FinancialInsightsService.generateRecommendations(
        score,
        [],
        [],
      );

      expect(recommendations, isNotEmpty);
      // Should focus on lowest scoring categories
      final lowestCategory = recommendations.first.category;
      expect(lowestCategory, isNotEmpty);
    });
  });
}
