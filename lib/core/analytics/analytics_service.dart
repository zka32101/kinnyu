import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logEvent(String eventName, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
    } catch (e, stack) {
      debugPrint('AnalyticsService.logEvent failed: $e\n$stack');
      try {
        await FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
      } catch (crashlyticsError, crashlyticsStack) {
        debugPrint(
          'AnalyticsService.logEvent: Crashlytics recordError failed: $crashlyticsError\n$crashlyticsStack',
        );
      }
    }
  }

  Future<void> logOnboardingComplete(String userId) async {
    try {
      await logEvent(
        'onboarding_complete',
        parameters: {
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e, stack) {
      debugPrint('AnalyticsService.logOnboardingComplete failed: $e\n$stack');
      try {
        await FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
      } catch (crashlyticsError, crashlyticsStack) {
        debugPrint(
          'AnalyticsService.logOnboardingComplete: Crashlytics recordError failed: $crashlyticsError\n$crashlyticsStack',
        );
      }
    }
  }

  Future<void> logAhaMomentReached(String userId, String patternId) async {
    try {
      await logEvent(
        'aha_moment_reached',
        parameters: {
          'user_id': userId,
          'pattern_id': patternId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e, stack) {
      debugPrint('AnalyticsService.logAhaMomentReached failed: $e\n$stack');
      try {
        await FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
      } catch (crashlyticsError, crashlyticsStack) {
        debugPrint(
          'AnalyticsService.logAhaMomentReached: Crashlytics recordError failed: $crashlyticsError\n$crashlyticsStack',
        );
      }
    }
  }

  Future<void> logQuizComplete(String userId, String category, int score) async {
    try {
      await logEvent(
        'quiz_complete_daily',
        parameters: {
          'user_id': userId,
          'category': category,
          'score': score,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e, stack) {
      debugPrint('AnalyticsService.logQuizComplete failed: $e\n$stack');
      try {
        await FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
      } catch (crashlyticsError, crashlyticsStack) {
        debugPrint(
          'AnalyticsService.logQuizComplete: Crashlytics recordError failed: $crashlyticsError\n$crashlyticsStack',
        );
      }
    }
  }

  Future<void> logStreakDay(String userId, int streakDays) async {
    try {
      await logEvent(
        'streak_day_${streakDays}',
        parameters: {
          'user_id': userId,
          'streak_days': streakDays,
        },
      );
    } catch (e, stack) {
      debugPrint('AnalyticsService.logStreakDay failed: $e\n$stack');
      try {
        await FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
      } catch (crashlyticsError, crashlyticsStack) {
        debugPrint(
          'AnalyticsService.logStreakDay: Crashlytics recordError failed: $crashlyticsError\n$crashlyticsStack',
        );
      }
    }
  }

  Future<void> logPaywallViewed(String userId) async {
    try {
      await logEvent(
        'paywall_viewed',
        parameters: {
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e, stack) {
      debugPrint('AnalyticsService.logPaywallViewed failed: $e\n$stack');
      try {
        await FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
      } catch (crashlyticsError, crashlyticsStack) {
        debugPrint(
          'AnalyticsService.logPaywallViewed: Crashlytics recordError failed: $crashlyticsError\n$crashlyticsStack',
        );
      }
    }
  }

  Future<void> logPurchased(String userId, String productId, double price) async {
    try {
      await logEvent(
        'purchased',
        parameters: {
          'user_id': userId,
          'product_id': productId,
          'price': price,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e, stack) {
      debugPrint('AnalyticsService.logPurchased failed: $e\n$stack');
      try {
        await FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
      } catch (crashlyticsError, crashlyticsStack) {
        debugPrint(
          'AnalyticsService.logPurchased: Crashlytics recordError failed: $crashlyticsError\n$crashlyticsStack',
        );
      }
    }
  }

  Future<void> setUserProperties(String userId, {int? level, int? totalXP}) async {
    try {
      await _analytics.setUserProperty(
        name: 'user_id',
        value: userId,
      );
      if (level != null) {
        await _analytics.setUserProperty(
          name: 'level',
          value: level.toString(),
        );
      }
      if (totalXP != null) {
        await _analytics.setUserProperty(
          name: 'total_xp',
          value: totalXP.toString(),
        );
      }
    } catch (e, stack) {
      debugPrint('AnalyticsService.setUserProperties failed: $e\n$stack');
      try {
        await FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
      } catch (crashlyticsError, crashlyticsStack) {
        debugPrint(
          'AnalyticsService.setUserProperties: Crashlytics recordError failed: $crashlyticsError\n$crashlyticsStack',
        );
      }
    }
  }
}
