import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_service.dart';

final notificationServiceProvider = Provider((ref) {
  return NotificationService();
});

final streakReminderEnabledProvider =
    StateNotifierProvider<StreamNotifier, bool>((ref) {
  return StreamNotifier();
});

class StreamNotifier extends StateNotifier<bool> {
  StreamNotifier() : super(true);

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
