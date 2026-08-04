import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/challenge/domain/models/challenge.dart';

void main() {
  group('ChallengeParticipant', () {
    test('fromJson creates a valid participant instance', () {
      final json = {
        'uid': 'user123',
        'reductionAmount': 5000,
      };

      final participant = ChallengeParticipant.fromJson(json);

      expect(participant.uid, equals('user123'));
      expect(participant.reductionAmount, equals(5000));
    });

    test('toJson serializes correctly', () {
      final participant = ChallengeParticipant(
        uid: 'user123',
        reductionAmount: 3000,
      );

      final json = participant.toJson();

      expect(json['uid'], equals('user123'));
      expect(json['reductionAmount'], equals(3000));
    });
  });

  group('Challenge', () {
    test('isActive returns true for ongoing challenge', () {
      final now = DateTime.now();
      final challenge = Challenge(
        id: 'ch1',
        title: 'Test Challenge',
        description: 'Test description',
        startDate: now.subtract(const Duration(hours: 1)),
        endDate: now.add(const Duration(days: 1)),
        targetReduction: 1000,
        participants: [],
        rewardXP: 150,
      );

      expect(challenge.isActive, equals(true));
    });

    test('isActive returns false for expired challenge', () {
      final now = DateTime.now();
      final challenge = Challenge(
        id: 'ch1',
        title: 'Test Challenge',
        description: 'Test description',
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.subtract(const Duration(hours: 1)),
        targetReduction: 1000,
        participants: [],
        rewardXP: 150,
      );

      expect(challenge.isActive, equals(false));
    });

    test('ranking orders participants by reduction amount descending', () {
      final participants = [
        ChallengeParticipant(uid: 'user1', reductionAmount: 1000),
        ChallengeParticipant(uid: 'user2', reductionAmount: 5000),
        ChallengeParticipant(uid: 'user3', reductionAmount: 3000),
      ];

      final now = DateTime.now();
      final challenge = Challenge(
        id: 'ch1',
        title: 'Test Challenge',
        description: 'Test description',
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
        targetReduction: 1000,
        participants: participants,
        rewardXP: 150,
      );

      final ranked = challenge.ranking;

      expect(ranked[0].uid, equals('user2'));
      expect(ranked[0].reductionAmount, equals(5000));
      expect(ranked[1].uid, equals('user3'));
      expect(ranked[2].uid, equals('user1'));
    });

    test('isParticipating returns true for participating user', () {
      final participants = [
        ChallengeParticipant(uid: 'user1', reductionAmount: 1000),
      ];

      final now = DateTime.now();
      final challenge = Challenge(
        id: 'ch1',
        title: 'Test Challenge',
        description: 'Test description',
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
        targetReduction: 1000,
        participants: participants,
        rewardXP: 150,
      );

      expect(challenge.isParticipating('user1'), equals(true));
      expect(challenge.isParticipating('user2'), equals(false));
    });

    test('daysRemaining calculates correctly', () {
      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 5));

      final challenge = Challenge(
        id: 'ch1',
        title: 'Test Challenge',
        description: 'Test description',
        startDate: now,
        endDate: endDate,
        targetReduction: 1000,
        participants: [],
        rewardXP: 150,
      );

      expect(challenge.daysRemaining, equals(5));
    });
  });

  group('ChallengeTemplates', () {
    test('currentWeeklyChallenge returns a valid challenge', () {
      final challenge = ChallengeTemplates.currentWeeklyChallenge();

      expect(challenge.title, isNotEmpty);
      expect(challenge.description, isNotEmpty);
      expect(challenge.isActive, equals(true));
      expect(challenge.participants.isEmpty, equals(true));
    });

    test('pool has multiple challenge templates', () {
      expect(ChallengeTemplates.pool.length, greaterThanOrEqualTo(5));
    });

    test('every template has non-empty fields and positive reward', () {
      for (final t in ChallengeTemplates.pool) {
        expect(t.slug.trim(), isNotEmpty);
        expect(t.title.trim(), isNotEmpty);
        expect(t.description.trim(), isNotEmpty);
        expect(t.targetReduction, greaterThan(0));
        expect(t.rewardXP, greaterThan(0));
      }
    });

    test('all template slugs are unique', () {
      final slugs = ChallengeTemplates.pool.map((t) => t.slug).toSet();
      expect(slugs.length, equals(ChallengeTemplates.pool.length));
    });

    test('challenge id includes a template slug', () {
      final challenge = ChallengeTemplates.currentWeeklyChallenge();
      final matchesSome = ChallengeTemplates.pool
          .any((t) => challenge.id.contains(t.slug));
      expect(matchesSome, isTrue);
    });
  });
}
