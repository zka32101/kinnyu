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
  static const double pricePerCategory = 300.0; // ¥300/month per category
  static const double priceBundle = 1200.0; // ¥1,200/month for all 4 categories
  static const int trialDays = 14; // 2-week free trial
}
