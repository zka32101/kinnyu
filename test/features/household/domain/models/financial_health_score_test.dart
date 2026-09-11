import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/household/domain/models/financial_health_score.dart';

void main() {
  group('FinancialHealthScore', () {
    test('creates a valid financial health score', () {
      final now = DateTime.now();
      final score = FinancialHealthScore(
        groupId: 'group123',
        calculatedAt: now,
        overallScore: 85,
        savingsRatioScore: 90,
        budgetAdherenceScore: 80,
        expenseControlScore: 85,
        investmentEngagementScore: 80,
        socialImpactScore: 75,
      );

      expect(score.groupId, equals('group123'));
      expect(score.calculatedAt, equals(now));
      expect(score.overallScore, equals(85));
      expect(score.savingsRatioScore, equals(90));
      expect(score.budgetAdherenceScore, equals(80));
    });

    test('assigns correct grade based on score', () {
      expect(
        FinancialHealthScore(
          groupId: 'g1',
          calculatedAt: DateTime.now(),
          overallScore: 95,
          savingsRatioScore: 95,
          budgetAdherenceScore: 95,
          expenseControlScore: 95,
          investmentEngagementScore: 95,
          socialImpactScore: 95,
        ).grade,
        equals('A+'),
      );

      expect(
        FinancialHealthScore(
          groupId: 'g1',
          calculatedAt: DateTime.now(),
          overallScore: 90,
          savingsRatioScore: 90,
          budgetAdherenceScore: 90,
          expenseControlScore: 90,
          investmentEngagementScore: 90,
          socialImpactScore: 90,
        ).grade,
        equals('A'),
      );

      expect(
        FinancialHealthScore(
          groupId: 'g1',
          calculatedAt: DateTime.now(),
          overallScore: 85,
          savingsRatioScore: 85,
          budgetAdherenceScore: 85,
          expenseControlScore: 85,
          investmentEngagementScore: 85,
          socialImpactScore: 85,
        ).grade,
        equals('B+'),
      );

      expect(
        FinancialHealthScore(
          groupId: 'g1',
          calculatedAt: DateTime.now(),
          overallScore: 65,
          savingsRatioScore: 65,
          budgetAdherenceScore: 65,
          expenseControlScore: 65,
          investmentEngagementScore: 65,
          socialImpactScore: 65,
        ).grade,
        equals('D'),
      );

      expect(
        FinancialHealthScore(
          groupId: 'g1',
          calculatedAt: DateTime.now(),
          overallScore: 45,
          savingsRatioScore: 45,
          budgetAdherenceScore: 45,
          expenseControlScore: 45,
          investmentEngagementScore: 45,
          socialImpactScore: 45,
        ).grade,
        equals('F'),
      );
    });

    test('serializes to JSON correctly', () {
      final now = DateTime.now();
      final score = FinancialHealthScore(
        groupId: 'group123',
        calculatedAt: now,
        overallScore: 85,
        savingsRatioScore: 90,
        budgetAdherenceScore: 80,
        expenseControlScore: 85,
        investmentEngagementScore: 80,
        socialImpactScore: 75,
      );

      final json = score.toJson();

      expect(json['groupId'], equals('group123'));
      expect(json['overallScore'], equals(85));
      expect(json['savingsRatioScore'], equals(90));
      expect(json['budgetAdherenceScore'], equals(80));
      expect(json['expenseControlScore'], equals(85));
      expect(json['investmentEngagementScore'], equals(80));
      expect(json['socialImpactScore'], equals(75));
      expect(json['calculatedAt'], equals(now.toIso8601String()));
    });

    test('deserializes from JSON correctly', () {
      final now = DateTime.now();
      final json = {
        'groupId': 'group123',
        'calculatedAt': now.toIso8601String(),
        'overallScore': 85,
        'savingsRatioScore': 90,
        'budgetAdherenceScore': 80,
        'expenseControlScore': 85,
        'investmentEngagementScore': 80,
        'socialImpactScore': 75,
      };

      final score = FinancialHealthScore.fromJson(json);

      expect(score.groupId, equals('group123'));
      expect(score.overallScore, equals(85));
      expect(score.savingsRatioScore, equals(90));
      expect(score.budgetAdherenceScore, equals(80));
    });

    test('roundtrip serialization works correctly', () {
      final original = FinancialHealthScore(
        groupId: 'group456',
        calculatedAt: DateTime(2026, 9, 11),
        overallScore: 78,
        savingsRatioScore: 85,
        budgetAdherenceScore: 75,
        expenseControlScore: 70,
        investmentEngagementScore: 80,
        socialImpactScore: 72,
      );

      final json = original.toJson();
      final restored = FinancialHealthScore.fromJson(json);

      expect(restored.groupId, equals(original.groupId));
      expect(restored.overallScore, equals(original.overallScore));
      expect(restored.savingsRatioScore, equals(original.savingsRatioScore));
      expect(restored.budgetAdherenceScore, equals(original.budgetAdherenceScore));
      expect(restored.expenseControlScore, equals(original.expenseControlScore));
      expect(restored.investmentEngagementScore,
          equals(original.investmentEngagementScore));
      expect(restored.socialImpactScore, equals(original.socialImpactScore));
    });
  });

  group('HealthScoreCategory', () {
    test('creates a valid category', () {
      final category = HealthScoreCategory(
        categoryName: 'savingsRatio',
        displayName: '貯蓄率',
        score: 85,
        description: '毎月の貯蓄額の割合',
      );

      expect(category.categoryName, equals('savingsRatio'));
      expect(category.displayName, equals('貯蓄率'));
      expect(category.score, equals(85));
      expect(category.status, equals('excellent'));
    });

    test('assigns correct status based on score', () {
      expect(
        HealthScoreCategory(
          categoryName: 'test',
          displayName: 'Test',
          score: 90,
          description: 'Test category',
        ).status,
        equals('excellent'),
      );

      expect(
        HealthScoreCategory(
          categoryName: 'test',
          displayName: 'Test',
          score: 75,
          description: 'Test category',
        ).status,
        equals('good'),
      );

      expect(
        HealthScoreCategory(
          categoryName: 'test',
          displayName: 'Test',
          score: 55,
          description: 'Test category',
        ).status,
        equals('fair'),
      );

      expect(
        HealthScoreCategory(
          categoryName: 'test',
          displayName: 'Test',
          score: 30,
          description: 'Test category',
        ).status,
        equals('poor'),
      );
    });
  });

  group('HealthScoreRecommendation', () {
    test('creates a valid recommendation', () {
      final recommendation = HealthScoreRecommendation(
        id: 'rec_001',
        title: '貯蓄率を高める',
        description: '毎月20%以上の貯蓄を目指しましょう',
        category: 'Savings Ratio',
        potentialScoreGain: 15,
        priority: 'high',
        actionType: 'saving',
      );

      expect(recommendation.id, equals('rec_001'));
      expect(recommendation.title, equals('貯蓄率を高める'));
      expect(recommendation.potentialScoreGain, equals(15));
      expect(recommendation.priority, equals('high'));
    });
  });

  group('FinancialHealthScoreTrend', () {
    test('creates a valid trend', () {
      final trend = FinancialHealthScoreTrend(
        groupId: 'group123',
        month: '2026-09',
        overallScore: 85,
        categoryScores: {
          'savingsRatio': 90,
          'budgetAdherence': 80,
          'expenseControl': 85,
        },
      );

      expect(trend.groupId, equals('group123'));
      expect(trend.month, equals('2026-09'));
      expect(trend.overallScore, equals(85));
      expect(trend.categoryScores['savingsRatio'], equals(90));
    });

    test('serializes and deserializes correctly', () {
      final original = FinancialHealthScoreTrend(
        groupId: 'group123',
        month: '2026-09',
        overallScore: 85,
        categoryScores: {
          'savingsRatio': 90,
          'budgetAdherence': 80,
        },
      );

      final json = original.toJson();
      final restored = FinancialHealthScoreTrend.fromJson(json);

      expect(restored.groupId, equals(original.groupId));
      expect(restored.month, equals(original.month));
      expect(restored.overallScore, equals(original.overallScore));
      expect(restored.categoryScores, equals(original.categoryScores));
    });
  });
}
