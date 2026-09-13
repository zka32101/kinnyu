import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/household/data/social_contribution_service.dart';
import 'package:okane_kore/features/household/domain/models/social_contribution.dart';

void main() {
  group('SocialContributionService', () {
    // Note: Mock generation requires build_runner which is not available in this environment
    // Full integration tests with Firestore mocks are pending proper mockito setup

    test('ESGScore models have correct structure', () {
      const esgScore = ESGScore(
        categoryName: 'Test Category',
        environmentScore: 75,
        socialScore: 80,
        governanceScore: 85,
      );

      expect(esgScore.categoryName, equals('Test Category'));
      expect(esgScore.totalScore, greaterThan(0));
      expect(esgScore.totalScore, lessThanOrEqualTo(100));
    });

    test('ESGScore defaultScores is populated', () {
      final scores = ESGScore.defaultScores;
      expect(scores.isNotEmpty, isTrue);

      for (final score in scores.values) {
        expect(score.environmentScore, greaterThanOrEqualTo(0));
        expect(score.environmentScore, lessThanOrEqualTo(100));
      }
    });

    test('Carbon emission factors are available', () {
      final factors = CarbonEmissionFactor.defaultFactors;
      expect(factors.isNotEmpty, isTrue);
      expect(factors.containsKey('食費'), isTrue);
    });

    test('Charity donations list is populated', () {
      final charities = CharityDonation.defaultCharities;
      expect(charities.isNotEmpty, isTrue);
      expect(charities.first.name, isNotEmpty);
    });

    test('SocialImpactDashboard calculates impact levels', () {
      const dashboard = SocialImpactDashboard(
        groupId: 'test_group',
        totalCarbonSaved: 20000,
        totalDonationsAmount: 50000,
        familiesHelped: 10,
        impactByCharity: {},
        topCategories: [],
      );

      expect(dashboard.impactLevel, equals(4)); // 50000 >= 50000
      expect(dashboard.treesEquivalent, equals(1)); // 20000 / 20000 = 1
    });
  });
}
