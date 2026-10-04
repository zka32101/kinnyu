import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:okane_kore/features/user_profile/presentation/providers/user_provider.dart';

/// Riverpod 3 では Notifier を直接生成して state を触れないため、
/// ProviderContainer 経由で操作する。
ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

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
      final container = _container();
      final notifier = container.read(userProvider.notifier);
      expect(notifier.build(), isNull);
    });

    test('initializeUser updates state', () {
      final container = _container();
      final notifier = container.read(userProvider.notifier);
      final user = UserProfile(
        uid: 'user1',
        email: 'test@example.com',
        streak: 0,
        totalXP: 0,
        level: 1,
        ahaAchieved: false,
      );

      notifier.initializeUser(user);
      expect(container.read(userProvider), equals(user));
    });

    test('updateStreak updates streak when state is not null', () {
      final container = _container();
      final notifier = container.read(userProvider.notifier);
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

      expect(container.read(userProvider)?.streak, equals(10));
    });

    test('addXP increases totalXP and updates level', () {
      final container = _container();
      final notifier = container.read(userProvider.notifier);
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

      expect(container.read(userProvider)?.totalXP, equals(110));
      expect(container.read(userProvider)?.level, equals(2));
    });

    test('setAhaAchieved sets flag to true', () {
      final container = _container();
      final notifier = container.read(userProvider.notifier);
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

      expect(container.read(userProvider)?.ahaAchieved, equals(true));
    });

    test('updateStreak does nothing if state is null', () {
      final container = _container();
      final notifier = container.read(userProvider.notifier);
      notifier.updateStreak(5);
      expect(container.read(userProvider), isNull);
    });

    test('addXP does nothing if state is null', () {
      final container = _container();
      final notifier = container.read(userProvider.notifier);
      notifier.addXP(10);
      expect(container.read(userProvider), isNull);
    });

    test('setAhaAchieved does nothing if state is null', () {
      final container = _container();
      final notifier = container.read(userProvider.notifier);
      notifier.setAhaAchieved();
      expect(container.read(userProvider), isNull);
    });
  });
}
