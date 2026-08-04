import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/mission/domain/models/mission.dart';

void main() {
  group('Mission', () {
    test('fromJson creates a valid Mission instance', () {
      final now = DateTime.now();
      final json = {
        'id': 'mission1',
        'type': 0, // MissionType.furusatoNozei
        'title': 'ふるさと納税を申し込む',
        'description': 'ふるさと納税を1件申し込みましょう',
        'rewardXP': 50,
        'deadline': now.toIso8601String(),
        'status': 0, // MissionStatus.pending
        'completedAt': null,
      };

      final mission = Mission.fromJson(json);

      expect(mission.id, equals('mission1'));
      expect(mission.type, equals(MissionType.furusatoNozei));
      expect(mission.title, equals('ふるさと納税を申し込む'));
      expect(mission.rewardXP, equals(50));
      expect(mission.status, equals(MissionStatus.pending));
      expect(mission.completedAt, isNull);
    });

    test('copyWith creates updated instance', () {
      final now = DateTime.now();
      final mission = Mission(
        id: 'mission1',
        type: MissionType.insuranceReview,
        title: 'Insurance Review',
        description: 'Review your insurance policy',
        rewardXP: 50,
        deadline: now,
        status: MissionStatus.pending,
      );

      final completed = mission.copyWith(
        status: MissionStatus.completed,
        completedAt: now,
      );

      expect(completed.id, equals(mission.id));
      expect(completed.status, equals(MissionStatus.completed));
      expect(completed.completedAt, isNotNull);
    });

    test('isExpired returns true for past deadline', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final mission = Mission(
        id: 'mission1',
        type: MissionType.receiptReduction,
        title: 'Reduce receipts',
        description: 'Reduce receipt spending',
        rewardXP: 50,
        deadline: pastDate,
        status: MissionStatus.pending,
      );

      expect(mission.isExpired, equals(true));
    });

    test('isExpired returns false for future deadline', () {
      final futureDate = DateTime.now().add(const Duration(days: 1));
      final mission = Mission(
        id: 'mission1',
        type: MissionType.savingsTarget,
        title: 'Savings Target',
        description: 'Save 10000 yen',
        rewardXP: 50,
        deadline: futureDate,
        status: MissionStatus.pending,
      );

      expect(mission.isExpired, equals(false));
    });
  });

  group('MissionTemplates', () {
    test('pool has plenty of templates', () {
      expect(MissionTemplates.pool.length, greaterThanOrEqualTo(10));
    });

    test('every template has non-empty fields and positive reward', () {
      for (final t in MissionTemplates.pool) {
        expect(t.title.trim(), isNotEmpty);
        expect(t.description.trim(), isNotEmpty);
        expect(t.rewardXP, greaterThan(0));
        expect(t.slug.trim(), isNotEmpty);
      }
    });

    test('all template slugs are unique', () {
      final slugs = MissionTemplates.pool.map((t) => t.slug).toSet();
      expect(slugs.length, equals(MissionTemplates.pool.length));
    });

    test('generateWeeklyMissions creates the requested count', () {
      final missions = MissionTemplates.generateWeeklyMissions();
      expect(missions.length, equals(3));

      final five = MissionTemplates.generateWeeklyMissions(count: 5);
      expect(five.length, equals(5));
    });

    test('generateWeeklyMissions missions have future deadlines', () {
      final missions = MissionTemplates.generateWeeklyMissions();
      final now = DateTime.now();

      for (final mission in missions) {
        expect(mission.deadline.isAfter(now), equals(true));
        expect(mission.status, equals(MissionStatus.pending));
      }
    });

    test('generateWeeklyMissions prefers distinct mission types', () {
      final missions = MissionTemplates.generateWeeklyMissions(count: 3);
      final types = missions.map((m) => m.type).toSet();
      // 3件は異なる種別になるはず（プールに5種別あるため）
      expect(types.length, equals(3));
    });

    test('same seed produces the same missions (deterministic)', () {
      final a = MissionTemplates.generateWeeklyMissions(seed: 12345);
      final b = MissionTemplates.generateWeeklyMissions(seed: 12345);
      expect(a.map((m) => m.title).toList(),
          equals(b.map((m) => m.title).toList()));
    });

    test('different seeds can produce different missions', () {
      final a = MissionTemplates.generateWeeklyMissions(seed: 1);
      final b = MissionTemplates.generateWeeklyMissions(seed: 99999);
      // 少なくとも構成が変わり得る（同一とは限らないが型は保つ）
      expect(a.length, equals(b.length));
    });
  });
}
