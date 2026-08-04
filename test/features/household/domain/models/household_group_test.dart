import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/household/domain/models/household_group.dart';

void main() {
  group('HouseholdGroup', () {
    test('fromJson creates a valid household group', () {
      final now = DateTime.now();
      final json = {
        'id': 'HH001',
        'name': 'Tanaka Family',
        'members': ['user1', 'user2'],
        'totalSavings': 50000,
        'monthlyGoal': 100000,
        'createdAt': now.toIso8601String(),
      };

      final group = HouseholdGroup.fromJson(json);

      expect(group.id, equals('HH001'));
      expect(group.name, equals('Tanaka Family'));
      expect(group.members.length, equals(2));
      expect(group.totalSavings, equals(50000));
      expect(group.monthlyGoal, equals(100000));
    });

    test('toJson serializes correctly', () {
      final now = DateTime.now();
      final group = HouseholdGroup(
        id: 'HH001',
        name: 'Tanaka Family',
        members: ['user1', 'user2'],
        totalSavings: 75000,
        monthlyGoal: 100000,
        createdAt: now,
      );

      final json = group.toJson();

      expect(json['id'], equals('HH001'));
      expect(json['name'], equals('Tanaka Family'));
      expect(json['members'].length, equals(2));
      expect(json['totalSavings'], equals(75000));
    });

    test('progressRatio calculates correctly', () {
      final now = DateTime.now();

      final group50 = HouseholdGroup(
        id: 'HH001',
        name: 'Test Family',
        members: ['user1'],
        totalSavings: 50000,
        monthlyGoal: 100000,
        createdAt: now,
      );

      expect(group50.progressRatio, equals(0.5));

      final group150 = HouseholdGroup(
        id: 'HH001',
        name: 'Test Family',
        members: ['user1'],
        totalSavings: 150000,
        monthlyGoal: 100000,
        createdAt: now,
      );

      expect(group150.progressRatio, equals(1.0)); // Clamped to 1.0
    });

    test('progressRatio returns 0 when monthlyGoal is 0', () {
      final now = DateTime.now();
      final group = HouseholdGroup(
        id: 'HH001',
        name: 'Test Family',
        members: ['user1'],
        totalSavings: 50000,
        monthlyGoal: 0,
        createdAt: now,
      );

      expect(group.progressRatio, equals(0.0));
    });
  });
}
