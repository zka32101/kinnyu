import 'package:riverpod/riverpod.dart';

class UserProfile {
  final String uid;
  final String? email;
  final int streak;
  final int totalXP;
  final int level;
  final bool ahaAchieved;

  UserProfile({
    required this.uid,
    this.email,
    required this.streak,
    required this.totalXP,
    required this.level,
    required this.ahaAchieved,
  });

  UserProfile copyWith({
    String? uid,
    String? email,
    int? streak,
    int? totalXP,
    int? level,
    bool? ahaAchieved,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      streak: streak ?? this.streak,
      totalXP: totalXP ?? this.totalXP,
      level: level ?? this.level,
      ahaAchieved: ahaAchieved ?? this.ahaAchieved,
    );
  }
}

final userProvider = NotifierProvider<UserNotifier, UserProfile?>(() {
  return UserNotifier();
});

class UserNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() {
    return null;
  }

  void initializeUser(UserProfile user) {
    state = user;
  }

  void updateStreak(int newStreak) {
    if (state != null) {
      state = state!.copyWith(streak: newStreak);
    }
  }

  void addXP(int xp) {
    if (state != null) {
      final newTotalXP = state!.totalXP + xp;
      final newLevel = (newTotalXP ~/ 100) + 1;
      state = state!.copyWith(
        totalXP: newTotalXP,
        level: newLevel,
      );
    }
  }

  void setAhaAchieved() {
    if (state != null) {
      state = state!.copyWith(ahaAchieved: true);
    }
  }
}
