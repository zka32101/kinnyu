import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_service.dart';

final notificationServiceProvider = Provider((ref) {
  return NotificationService();
});

final streakReminderEnabledProvider =
    NotifierProvider<StreakReminderNotifier, bool>(StreakReminderNotifier.new);

class StreakReminderNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() {
    state = !state;
  }

  void enable() {
    state = true;
  }

  void disable() {
    state = false;
  }
}
