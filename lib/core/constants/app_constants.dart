class AppConstants {
  // App info
  static const String appName = 'お金コレ！';
  static const String appVersion = '1.0.0';

  // UI/UX
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;

  // Quiz settings
  static const int questionsPerDaily = 5;
  static const int initialQuizQuestionsCount = 3;

  // Firebase collections
  static const String usersCollection = 'users';
  static const String questionsCollection = 'questions';
  static const String streaksCollection = 'streaks';
  static const String patternDiagnosisCollection = 'pattern_diagnosis';
  static const String missionsCollection = 'missions';
  static const String householdGroupsCollection = 'household_groups';
  static const String challengesCollection = 'challenges';

  // Analytics events
  static const String eventAhaMomentReached = 'aha_moment_reached';
  static const String eventOnboardingComplete = 'onboarding_complete';
  static const String eventQuizCompleteDaily = 'quiz_complete_daily';
  static const String eventPaywallViewed = 'paywall_viewed';
  static const String eventPurchased = 'purchased';
  static const String eventMissionCompleted = 'mission_completed';
  static const String eventHouseholdJoined = 'household_joined';
  static const String eventChallengeJoined = 'challenge_joined';

  // Quiz categories
  static const Map<String, String> categoryNames = {
    'savings': '貯蓄',
    'tax': '税金',
    'invest': '投資',
    'insurance': '保険',
  };

  // Pricing
  // プレミアム(広告なし+出力などの全機能)は月額1米ドル。実際の請求額・表示価格は
  // Google Play の商品設定を RevenueCat 経由で取得した値が正（この定数は参考値）。
  static const double premiumMonthlyUsd = 1.0;
  static const int trialDays = 14; // 2-week free trial
}
