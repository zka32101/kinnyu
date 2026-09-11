import '../models/household_budget.dart';
import '../models/household_expense_summary.dart';
import '../models/financial_health_score.dart';

/// 財務健全性スコア計算エンジン
class FinancialHealthCalculator {
  /// 総合スコアとカテゴリ別スコアを計算
  static FinancialHealthScore calculateScore({
    required String groupId,
    required HouseholdBudget budget,
    required HouseholdExpenseSummary summary,
    required int investmentAmount,
    required int socialContributionAmount,
  }) {
    // 各カテゴリのスコアを計算
    final savingsRatioScore = _calculateSavingsRatioScore(summary);
    final budgetAdherenceScore = _calculateBudgetAdherenceScore(summary, budget);
    final expenseControlScore = _calculateExpenseControlScore(summary);
    final investmentEngagementScore = _calculateInvestmentEngagementScore(
      investmentAmount,
      summary.totalIncome,
    );
    final socialImpactScore = _calculateSocialImpactScore(
      socialContributionAmount,
      summary.totalIncome,
    );

    // 総合スコアを計算（各カテゴリの加重平均）
    final overallScore = (
      (savingsRatioScore * 0.25) +      // 25%: 貯蓄率
      (budgetAdherenceScore * 0.25) +  // 25%: 予算遵守率
      (expenseControlScore * 0.20) +   // 20%: 支出管理
      (investmentEngagementScore * 0.15) + // 15%: 投資参加
      (socialImpactScore * 0.15)       // 15%: 社会貢献
    ).toInt();

    return FinancialHealthScore(
      groupId: groupId,
      calculatedAt: DateTime.now(),
      overallScore: overallScore.clamp(0, 100),
      savingsRatioScore: savingsRatioScore,
      budgetAdherenceScore: budgetAdherenceScore,
      expenseControlScore: expenseControlScore,
      investmentEngagementScore: investmentEngagementScore,
      socialImpactScore: socialImpactScore,
    );
  }

  /// 貯蓄率スコアを計算（目標: 20%+）
  static int _calculateSavingsRatioScore(HouseholdExpenseSummary summary) {
    if (summary.totalIncome == 0) return 0;

    final savingsRatio = summary.savingAmount / summary.totalIncome;

    if (savingsRatio >= 0.30) return 100;      // 30%以上: 満点
    if (savingsRatio >= 0.25) return 95;       // 25-30%: A+相当
    if (savingsRatio >= 0.20) return 90;       // 20-25%: A相当
    if (savingsRatio >= 0.15) return 80;       // 15-20%: B相当
    if (savingsRatio >= 0.10) return 70;       // 10-15%: C相当
    if (savingsRatio >= 0.05) return 50;       // 5-10%: D相当
    return 30;                                  // 5%未満: F相当
  }

  /// 予算遵守率スコアを計算
  static int _calculateBudgetAdherenceScore(
    HouseholdExpenseSummary summary,
    HouseholdBudget budget,
  ) {
    if (budget.totalBudget == 0) return 50;

    final adherenceRatio = summary.totalExpense / budget.totalBudget;

    if (adherenceRatio <= 0.80) return 100;    // 予算の80%以下: 満点
    if (adherenceRatio <= 0.90) return 90;     // 予算の90%以下
    if (adherenceRatio <= 1.00) return 80;     // 予算以下
    if (adherenceRatio <= 1.10) return 70;     // 予算の110%以下
    if (adherenceRatio <= 1.20) return 50;     // 予算の120%以下
    return 30;                                  // 予算の120%以上
  }

  /// 支出管理スコアを計算（変動性が低いほど高スコア）
  static int _calculateExpenseControlScore(HouseholdExpenseSummary summary) {
    // 実装例: 支出の安定性に基づくスコア
    // 理想的には複数月のデータが必要ですが、ここでは単月データで推定

    if (summary.totalExpense == 0) return 50;

    // カテゴリ別の偏差を計算して支出バランスを評価
    final categoryBreakdown = summary.categoryBreakdown;
    if (categoryBreakdown.isEmpty) return 50;

    final totalExpense = categoryBreakdown.values.fold<int>(0, (a, b) => a + b);
    if (totalExpense == 0) return 50;

    // 各カテゴリの期待比率からの偏差を計算
    const targetDistribution = {
      '食費': 0.20,         // 20%
      '光熱費': 0.10,       // 10%
      '交通費': 0.10,       // 10%
      '生活費': 0.30,       // 30%
      '娯楽': 0.15,         // 15%
      'その他': 0.15,       // 15%
    };

    double deviationSum = 0;
    for (final entry in categoryBreakdown.entries) {
      final actual = entry.value / totalExpense;
      final target = targetDistribution[entry.key] ?? 0.0;
      deviationSum += (actual - target).abs();
    }

    // 偏差の合計から スコアを計算（偏差が小さいほど高スコア）
    final deviation = deviationSum / 2; // 最大値が2
    final score = ((1 - deviation) * 100).toInt();

    return score.clamp(20, 100);
  }

  /// 投資参加スコアを計算
  static int _calculateInvestmentEngagementScore(
    int investmentAmount,
    int totalIncome,
  ) {
    if (totalIncome == 0) return 0;

    final investmentRatio = investmentAmount / totalIncome;

    if (investmentRatio >= 0.20) return 100;   // 収入の20%以上: 満点
    if (investmentRatio >= 0.15) return 95;    // 15-20%
    if (investmentRatio >= 0.10) return 90;    // 10-15%
    if (investmentRatio >= 0.05) return 80;    // 5-10%
    if (investmentRatio >= 0.02) return 60;    // 2-5%
    if (investmentAmount > 0) return 40;       // 参加しているが少額
    return 20;                                  // 投資なし
  }

  /// 社会貢献スコアを計算
  static int _calculateSocialImpactScore(
    int socialContributionAmount,
    int totalIncome,
  ) {
    if (totalIncome == 0) return 0;

    final contributionRatio = socialContributionAmount / totalIncome;

    if (contributionRatio >= 0.10) return 100;   // 収入の10%以上: 満点
    if (contributionRatio >= 0.05) return 95;    // 5-10%
    if (contributionRatio >= 0.02) return 85;    // 2-5%
    if (contributionRatio >= 0.01) return 75;    // 1-2%
    if (socialContributionAmount > 0) return 60; // 参加しているが少額
    return 40;                                    // 社会貢献なし
  }

  /// 推奨事項リストを生成
  static List<HealthScoreRecommendation> generateRecommendations(
    FinancialHealthScore score,
  ) {
    final recommendations = <HealthScoreRecommendation>[];

    // 貯蓄率が低い場合
    if (score.savingsRatioScore < 70) {
      recommendations.add(
        HealthScoreRecommendation(
          id: 'rec_savings_001',
          title: '貯蓄率を高める',
          description: '毎月の収入の20%以上を貯蓄することを目標にしましょう。自動積立設定で無理なく実現できます。',
          category: 'Savings Ratio',
          potentialScoreGain: 15,
          priority: 'high',
          actionType: 'saving',
        ),
      );
    }

    // 予算遵守率が低い場合
    if (score.budgetAdherenceScore < 70) {
      recommendations.add(
        HealthScoreRecommendation(
          id: 'rec_budget_001',
          title: '予算を守る',
          description: '毎月の支出が予算を大きく超えています。支出カテゴリを見直し、不要な支出を削減しましょう。',
          category: 'Budget Adherence',
          potentialScoreGain: 20,
          priority: 'high',
          actionType: 'budget',
        ),
      );
    }

    // 支出管理が不安定な場合
    if (score.expenseControlScore < 70) {
      recommendations.add(
        HealthScoreRecommendation(
          id: 'rec_expense_001',
          title: '支出を安定させる',
          description: '月ごとの支出が大きく変動しています。予算計画を立てて、より安定した支出パターンを目指しましょう。',
          category: 'Expense Control',
          potentialScoreGain: 15,
          priority: 'medium',
          actionType: 'expense',
        ),
      );
    }

    // 投資が不足している場合
    if (score.investmentEngagementScore < 70) {
      recommendations.add(
        HealthScoreRecommendation(
          id: 'rec_invest_001',
          title: '投資を始める',
          description: '貯蓄の一部を投資に回すことで、資産を増やすスピードが加速します。少額からでも始めてみましょう。',
          category: 'Investment Engagement',
          potentialScoreGain: 15,
          priority: 'medium',
          actionType: 'investment',
        ),
      );
    }

    // 社会貢献が不足している場合
    if (score.socialImpactScore < 60) {
      recommendations.add(
        HealthScoreRecommendation(
          id: 'rec_social_001',
          title: '社会に貢献する',
          description: 'ふるさと納税やNPO寄付など、社会貢献活動に参加してみましょう。節税効果もあります。',
          category: 'Social Impact',
          potentialScoreGain: 10,
          priority: 'low',
          actionType: 'social',
        ),
      );
    }

    return recommendations;
  }
}
