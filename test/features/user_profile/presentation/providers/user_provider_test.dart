import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/user_profile/presentation/providers/user_provider.dart';

void main() {
  group('UserProfile', () {
    test('copyWith creates a new instance with updated fields', () {
      final user = UserProfile(
        uid: 'user1',
        email: 'test@example.com',
        streak: 5,
        totalXP: 100,
        level: 2,
        ahaAchieved: false,
      );

      final updated = user.copyWith(streak: 10, ahaAchieved: true);

      expect(updated.uid, equals('user1'));
      expect(updated.email, equals('test@example.com'));
      expect(updated.streak, equals(10));
      expect(updated.totalXP, equals(100));
      expect(updated.level, equals(2));
      expect(updated.ahaAchieved, equals(true));
    });

    test('copyWith without parameters returns identical copy', () {
      final user = UserProfile(
        uid: 'user1',
        email: 'test@example.com',
        streak: 3,
        totalXP: 50,
        level: 1,
        ahaAchieved: false,
      );

      final copy = user.copyWith();

      expect(copy.uid, equals(user.uid));
      expect(copy.email, equals(user.email));
      expect(copy.streak, equals(user.streak));
      expect(copy.totalXP, equals(user.totalXP));
    });
  });

  group('UserNotifier', () {
    test('build returns null initially', () {
      final notifier = UserNotifier();
      expect(notifier.build(), isNull);
    });

    test('initializeUser updates state', () {
      final notifier = UserNotifier();
      final user = UserProfile(
        uid: 'user1',
        email: 'test@example.com',
        streak: 0,
        totalXP: 0,
        level: 1,
        ahaAchieved: false,
      );

      notifier.initializeUser(user);
      expect(notifier.state, equals(user));
    });

    test('updateStreak updates streak when state is not null', () {
      final notifier = UserNotifier();
      final user = UserProfile(
        uid: 'user1',
        email: 'test@example.com',
        streak: 5,
        totalXP: 100,
        level: 2,
        ahaAchieved: false,
      );

      notifier.initializeUser(user);
      notifier.updateStreak(10);

      expect(notifier.state?.streak, equals(10));
    });

    test('addXP increases totalXP and updates level', () {
      final notifier = UserNotifier();
      final user = UserProfile(
        uid: 'user1',
        email: 'test@example.com',
        streak: 0,
        totalXP: 50,
        level: 1,
        ahaAchieved: false,
      );

      notifier.initializeUser(user);
      notifier.addXP(60);

      expect(notifier.state?.totalXP, equals(110));
      expect(notifier.state?.level, equals(2));
    });

    test('setAhaAchieved sets flag to true', () {
      final notifier = UserNotifier();
      final user = UserProfile(
        uid: 'user1',
        email: 'test@example.com',
        streak: 0,
        totalXP: 0,
        level: 1,
        ahaAchieved: false,
      );

      notifier.initializeUser(user);
      notifier.setAhaAchieved();

      expect(notifier.state?.ahaAchieved, equals(true));
    });

    test('updateStreak does nothing if state is null', () {
      final notifier = UserNotifier();
      notifier.updateStreak(5);
      expect(notifier.state, isNull);
    });

    test('addXP does nothing if state is null', () {
      final notifier = UserNotifier();
      notifier.addXP(10);
      expect(notifier.state, isNull);
    });

    test('setAhaAchieved does nothing if state is null', () {
      final notifier = UserNotifier();
      notifier.setAhaAchieved();
      expect(notifier.state, isNull);
    });
  });
}
