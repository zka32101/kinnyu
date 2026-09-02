/// 最初の1ヶ月ガイドのステップ定義
enum FirstMonthGuideStepType {
  /// Week 1: クイズに挑戦
  quiz,
  /// Week 2: 世帯メンバー登録
  householdMembers,
  /// Week 3: 予算設定
  budgetSetup,
  /// Week 4: レシート3枚スキャン
  receiptCapture,
  /// Week 5: チャレンジ開始
  challengeStart,
}

/// 最初の1ヶ月ガイドのステップ
class FirstMonthGuideStep {
  final FirstMonthGuideStepType type;
  final String week;
  final String title;
  final String description;
  final String emoji;
  final String actionLabel;
  final bool isCompleted;

  const FirstMonthGuideStep({
    required this.type,
    required this.week,
    required this.title,
    required this.description,
    required this.emoji,
    required this.actionLabel,
    required this.isCompleted,
  });

  /// ステップを完了にマークする
  FirstMonthGuideStep copyWithCompleted(bool completed) {
    return FirstMonthGuideStep(
      type: type,
      week: week,
      title: title,
      description: description,
      emoji: emoji,
      actionLabel: actionLabel,
      isCompleted: completed,
    );
  }

  /// すべてのステップを定義
  static List<FirstMonthGuideStep> createAllSteps({
    Map<FirstMonthGuideStepType, bool>? completedStatus,
  }) {
    return [
      FirstMonthGuideStep(
        type: FirstMonthGuideStepType.quiz,
        week: 'Week 1',
        title: '金融クイズに挑戦',
        description: '3つの金融知識クイズに答えて、家計管理のコツを学びましょう',
        emoji: '🧠',
        actionLabel: 'クイズを開く',
        isCompleted: completedStatus?[FirstMonthGuideStepType.quiz] ?? false,
      ),
      FirstMonthGuideStep(
        type: FirstMonthGuideStepType.householdMembers,
        week: 'Week 2',
        title: '世帯メンバーを登録',
        description: 'ご家族やお友達をメンバーとして登録して、一緒に家計管理しましょう',
        emoji: '👨‍👩‍👧‍👦',
        actionLabel: 'メンバーを追加',
        isCompleted:
            completedStatus?[FirstMonthGuideStepType.householdMembers] ?? false,
      ),
      FirstMonthGuideStep(
        type: FirstMonthGuideStepType.budgetSetup,
        week: 'Week 3',
        title: '月間予算を設定',
        description:
            'カテゴリー別に月間予算を設定して、支出管理の目標を作りましょう',
        emoji: '💰',
        actionLabel: '予算を設定',
        isCompleted: completedStatus?[FirstMonthGuideStepType.budgetSetup] ??
            false,
      ),
      FirstMonthGuideStep(
        type: FirstMonthGuideStepType.receiptCapture,
        week: 'Week 4',
        title: 'レシートをスキャン',
        description: 'レシート3枚をスキャンして、自動家計分析を体験しましょう',
        emoji: '📸',
        actionLabel: 'レシートをスキャン',
        isCompleted:
            completedStatus?[FirstMonthGuideStepType.receiptCapture] ?? false,
      ),
      FirstMonthGuideStep(
        type: FirstMonthGuideStepType.challengeStart,
        week: 'Week 5',
        title: 'チャレンジを開始',
        description: '家族で貯蓄チャレンジに参加して、ゲーム感覚で家計管理を楽しもう',
        emoji: '🎯',
        actionLabel: 'チャレンジ開始',
        isCompleted:
            completedStatus?[FirstMonthGuideStepType.challengeStart] ?? false,
      ),
    ];
  }

  /// 完了したステップの数を計算
  static int countCompletedSteps(List<FirstMonthGuideStep> steps) {
    return steps.where((step) => step.isCompleted).length;
  }

  /// すべてのステップが完了したかチェック
  static bool areAllStepsCompleted(List<FirstMonthGuideStep> steps) {
    return steps.every((step) => step.isCompleted);
  }
}
