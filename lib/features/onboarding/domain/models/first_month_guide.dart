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
  final String? explanationTitle; // 解説のタイトル
  final String? explanationText; // テキストによる解説本文

  const FirstMonthGuideStep({
    required this.type,
    required this.week,
    required this.title,
    required this.description,
    required this.emoji,
    required this.actionLabel,
    required this.isCompleted,
    this.explanationTitle,
    this.explanationText,
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
      explanationTitle: explanationTitle,
      explanationText: explanationText,
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
        explanationTitle: '家計管理の基本を学ぶ',
        explanationText:
            '家計管理は「支出を把握する」ことから始まります。まずは1ヶ月分のレシートや明細を見返して、'
            '何にいくら使っているかを確認しましょう。\n\n'
            'よく使われる目安が「50:30:20ルール」です。手取り収入を「生活費50%・娯楽30%・貯蓄20%」の'
            '目安で配分すると、無理なく貯蓄を続けやすくなります。\n\n'
            'okane_kore！では、レシートの自動読み取りや家族との支出共有機能を使って、この「把握する」'
            'ステップを簡単に続けられるようにしています。',
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
        explanationTitle: '世帯メンバー登録ガイド',
        explanationText:
            'ご家族やパートナーをメンバーとして登録すると、それぞれの支出を1つの家計として'
            'まとめて把握できるようになります。\n\n'
            '登録方法はシンプルです。「メンバーを追加」から名前を入力するだけで、あとは各メンバーが'
            '記録した支出が自動的に世帯全体の集計に反映されます。\n\n'
            '誰が何にいくら使ったかが見える化されることで、家計の話し合いもしやすくなります。',
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
        explanationTitle: '予算設定のコツ',
        explanationText:
            '予算はカテゴリー別（食費・交際費・娯楽費など）に設定すると、どこで使いすぎているかが'
            'すぐに分かるようになります。\n\n'
            'コツは、いきなり厳しい金額にしないことです。まずは過去1〜2ヶ月の実績に近い金額から'
            '始めて、慣れてきたら少しずつ目標を下げていくと無理なく続けられます。\n\n'
            '予算を超えそうになると通知でお知らせする機能もあるので、使いすぎに早めに気づけます。',
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
        explanationTitle: 'レシート撮影のコツ',
        explanationText:
            'レシートは平らな場所に置き、影が入らない明るい場所で真上から撮影すると、文字の'
            '自動読み取り精度が上がります。\n\n'
            '折れ曲がったレシートは軽く伸ばしてから撮影しましょう。金額や日付が読み取れれば、'
            '店名や品目は自動でカテゴリー分けされます。\n\n'
            '読み取り結果に間違いがあれば、後からタップして手動で修正することもできます。',
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
        explanationTitle: 'チャレンジ機能ガイド',
        explanationText:
            '貯蓄チャレンジは、家族やお友達と一緒に貯蓄目標に挑戦できる機能です。ゲーム感覚で'
            '取り組めるので、1人では続きにくい節約や貯蓄も楽しく継続できます。\n\n'
            '参加者ごとの進捗が見えるので、お互いに励まし合いながら目標達成を目指せます。'
            '目標を達成するとバッジがもらえる仕組みもあります。\n\n'
            'まずは小さな目標（例：1ヶ月で1万円貯める）から始めてみましょう。',
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
