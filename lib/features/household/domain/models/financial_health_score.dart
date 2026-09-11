/// 財務健全性スコア - ユーザーの金融習慣を総合的に評価
class FinancialHealthScore {
  final String groupId;
  final DateTime calculatedAt;

  // Overall score (0-100)
  final int overallScore;

  // Category scores (0-100 each)
  final int savingsRatioScore;      // 貯蓄率スコア
  final int budgetAdherenceScore;   // 予算遵守率スコア
  final int expenseControlScore;    // 支出管理スコア
  final int investmentEngagementScore; // 投資参加スコア
  final int socialImpactScore;      // 社会貢献スコア

  // Grade (A+, A, B+, B, C+, C, D, F)
  final String grade;

  FinancialHealthScore({
    required this.groupId,
    required this.calculatedAt,
    required this.overallScore,
    required this.savingsRatioScore,
    required this.budgetAdherenceScore,
    required this.expenseControlScore,
    required this.investmentEngagementScore,
    required this.socialImpactScore,
  }) : grade = _calculateGrade(overallScore);

  /// スコアからグレード（A+, A, B+, B, C+, C, D, F）を計算
  static String _calculateGrade(int score) {
    if (score >= 95) return 'A+';
    if (score >= 90) return 'A';
    if (score >= 85) return 'B+';
    if (score >= 80) return 'B';
    if (score >= 75) return 'C+';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  /// JSON形式から復元
  factory FinancialHealthScore.fromJson(Map<String, dynamic> json) {
    return FinancialHealthScore(
      groupId: json['groupId'] as String,
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      overallScore: json['overallScore'] as int,
      savingsRatioScore: json['savingsRatioScore'] as int,
      budgetAdherenceScore: json['budgetAdherenceScore'] as int,
      expenseControlScore: json['expenseControlScore'] as int,
      investmentEngagementScore: json['investmentEngagementScore'] as int,
      socialImpactScore: json['socialImpactScore'] as int,
    );
  }

  /// JSON形式に変換
  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'calculatedAt': calculatedAt.toIso8601String(),
      'overallScore': overallScore,
      'savingsRatioScore': savingsRatioScore,
      'budgetAdherenceScore': budgetAdherenceScore,
      'expenseControlScore': expenseControlScore,
      'investmentEngagementScore': investmentEngagementScore,
      'socialImpactScore': socialImpactScore,
    };
  }
}

/// 健全性スコアの詳細情報とアドバイス
class FinancialHealthScoreDetail {
  final FinancialHealthScore score;
  final List<HealthScoreCategory> categories;
  final List<HealthScoreRecommendation> recommendations;
  final double monthlyTrend; // 前月比での変化（-10.0 ~ 10.0）

  FinancialHealthScoreDetail({
    required this.score,
    required this.categories,
    required this.recommendations,
    required this.monthlyTrend,
  });
}

/// カテゴリ別の健全性スコア情報
class HealthScoreCategory {
  final String categoryName;      // スコアカテゴリ名
  final String displayName;       // 表示名（日本語）
  final int score;                // カテゴリスコア
  final String description;       // カテゴリの説明
  final String status;            // ステータス: excellent, good, fair, poor

  HealthScoreCategory({
    required this.categoryName,
    required this.displayName,
    required this.score,
    required this.description,
  }) : status = _calculateStatus(score);

  static String _calculateStatus(int score) {
    if (score >= 85) return 'excellent';
    if (score >= 70) return 'good';
    if (score >= 50) return 'fair';
    return 'poor';
  }
}

/// 健全性スコア改善の推奨事項
class HealthScoreRecommendation {
  final String id;
  final String title;             // 推奨タイトル
  final String description;       // 詳細説明
  final String category;          // 対象カテゴリ
  final int potentialScoreGain;   // スコア改善ポイント
  final String priority;          // 優先度: high, medium, low
  final String actionType;        // アクション種類: budget, expense, saving, investment, social

  HealthScoreRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.potentialScoreGain,
    required this.priority,
    required this.actionType,
  });
}

/// 健全性スコアの月別履歴
class FinancialHealthScoreTrend {
  final String groupId;
  final String month;              // YYYY-MM形式
  final int overallScore;
  final Map<String, int> categoryScores;

  FinancialHealthScoreTrend({
    required this.groupId,
    required this.month,
    required this.overallScore,
    required this.categoryScores,
  });

  factory FinancialHealthScoreTrend.fromJson(Map<String, dynamic> json) {
    return FinancialHealthScoreTrend(
      groupId: json['groupId'] as String,
      month: json['month'] as String,
      overallScore: json['overallScore'] as int,
      categoryScores: Map<String, int>.from(
        json['categoryScores'] as Map<String, dynamic>
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'month': month,
      'overallScore': overallScore,
      'categoryScores': categoryScores,
    };
  }
}
