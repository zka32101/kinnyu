class StreakData {
  final int days;
  final DateTime lastLoggedDate;
  final bool loggedToday;

  StreakData({
    required this.days,
    required this.lastLoggedDate,
    required this.loggedToday,
  });
}

class StreakService {
  Future<StreakData> getStreak(String uid) async {
    return StreakData(
      days: 5,
      lastLoggedDate: DateTime.now(),
      loggedToday: true,
    );
  }

  Stream<StreakData> getStreakStream(String uid) {
    return Stream.value(
      StreakData(
        days: 5,
        lastLoggedDate: DateTime.now(),
        loggedToday: true,
      ),
    );
  }

  Future<void> updateStreak(String uid) async {
    // Dummy implementation
  }
}
