import 'package:riverpod/riverpod.dart';

class UserProfile {
  final String uid;
  final String? email;
  final int streak;
  final int totalXP;
  final int level;
  final bool ahaAchieved;
  // 初回家計診断クイズの結果パターンID（"q1_q2_q3"形式）。未診断ならnull。
  final String? diagnosisPatternId;

  UserProfile({
    required this.uid,
    this.email,
    required this.streak,
    required this.totalXP,
    required this.level,
    required this.ahaAchieved,
    this.diagnosisPatternId,
  });

  UserProfile copyWith({
    String? uid,
    String? email,
    int? streak,
    int? totalXP,
    int? level,
    bool? ahaAchieved,
    String? diagnosisPatternId,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      streak: streak ?? this.streak,
      totalXP: totalXP ?? this.totalXP,
      level: level ?? this.level,
      ahaAchieved: ahaAchieved ?? this.ahaAchieved,
      diagnosisPatternId: diagnosisPatternId ?? this.diagnosisPatternId,
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
      final clampedTotalXP = newTotalXP < 0 ? 0 : newTotalXP;
      final newLevel = (clampedTotalXP ~/ 100) + 1;
      state = state!.copyWith(
        totalXP: clampedTotalXP,
        level: newLevel,
      );
    }
  }

  void setAhaAchieved() {
    if (state != null) {
      state = state!.copyWith(ahaAchieved: true);
    }
  }

  void setDiagnosisPattern(String patternId) {
    if (state != null) {
      state = state!.copyWith(diagnosisPatternId: patternId);
    }
  }
}
