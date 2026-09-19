import '../models/financial_insight.dart';
import '../models/household_expense_summary.dart';
import '../models/financial_health_score.dart';

/// 財務インサイトと異常検知を処理するサービス
class FinancialInsightsService {
  /// カテゴリの重み付け（予算における相対的な重要度）
  static const Map<String, double> categoryWeights = {
    'food': 0.25,
    'transportation': 0.15,
    'utilities': 0.10,
    'entertainment': 0.10,
    'healthcare': 0.10,
    'education': 0.10,
    'savings': 0.15,
    'other': 0.05,
  };

  /// スコアカテゴリの感度（支出削減の影響の大きさ）
  static const Map<String, double> scoreCategorySensitivity = {
    'budgetAdherence': 1.5,     // 直接的な影響
    'expenseControl': 1.3,      // 安定性の影響
    'savingsRatio': 1.2,        // 限界的な影響
  };

  /// 支出の異常を分析
  static List<SpendingAnomaly> analyzeAnomalies(
    HouseholdExpenseSummary currentMonth,
    HouseholdExpenseSummary previousMonth,
    Map<String, int> budgetTargets,
  ) {
    final anomalies = <SpendingAnomaly>[];

    for (final category in currentMonth.categoryBreakdown.keys) {
      final current = currentMonth.categoryBreakdown[category] ?? 0;
      final previous = previousMonth.categoryBreakdown[category] ?? 0;

      // 前月がゼロの場合、スキップ（比較不可）
      if (previous == 0) continue;

      final variance = ((current - previous) / previous * 100).abs();

      // 20% 以上の変動を異常として検出
      if (variance >= 20) {
        final isIncreasing = current > previous;
        final severity = _calculateSeverity(variance);
        final trendDirection = isIncreasing ? TrendDirection.increasing : TrendDirection.decreasing;

        final description = _generateAnomalyDescription(
          category,
          current,
          previous,
          variance,
          isIncreasing,
        );

        anomalies.add(SpendingAnomaly(
          categoryName: category,
          previousMonthAmount: previous,
          currentMonthAmount: current,
          variancePercent: variance,
          trendDirection: trendDirection,
          severity: severity,
          description: description,
        ));
      }
    }

    return anomalies..sort((a, b) => b.severity.index.compareTo(a.severity.index));
  }

  /// 改善に向けた推奨事項を生成
  static List<FinancialInsight> generateRecommendations(
    FinancialHealthScore score,
    List<FinancialHealthScoreTrend> trends,
    List<SpendingAnomaly> anomalies,
  ) {
    final recommendations = <FinancialInsight>[];
    final now = DateTime.now();

    // 最低スコアのカテゴリを特定
    final categoryScores = <String, int>{
      'savingsRatio': score.savingsRatioScore,
      'budgetAdherence': score.budgetAdherenceScore,
      'expenseControl': score.expenseControlScore,
      'investmentEngagement': score.investmentEngagementScore,
      'socialImpact': score.socialImpactScore,
    };

    // スコアが低いカテゴリから優先度順にソート
    final sortedCategories = categoryScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // 最低スコアの3つのカテゴリに対して推奨事項を生成
    for (var i = 0; i < (sortedCategories.length < 3 ? sortedCategories.length : 3); i++) {
      final entry = sortedCategories[i];
      final category = entry.key;
      final currentCategoryScore = entry.value;

      // 目標スコアを設定（現在のスコア + 5-10ポイント）
      final targetScore = (currentCategoryScore + 8).clamp(0, 100);
      final scoreGain = targetScore - currentCategoryScore;

      // カテゴリに応じた削減額を計算
      final recommendedReduction = _calculateRecommendedReduction(
        category,
        scoreGain,
      );

      final insight = FinancialInsight(
        id: 'rec_${category}_${now.millisecondsSinceEpoch}',
        type: InsightType.recommendation,
        title: _generateRecommendationTitle(category, scoreGain),
        description: _generateRecommendationDescription(
          category,
          recommendedReduction,
          scoreGain,
        ),
        category: category,
        priority: i + 1, // 1, 2, 3
        scoreImpact: scoreGain,
        actionableItems: _generateActionItems(category),
        generatedAt: now,
        expiresAt: now.add(const Duration(days: 7)),
        contextIndicators: {
          'currentScore': currentCategoryScore,
          'targetScore': targetScore,
          'recommendedReduction': recommendedReduction,
        },
      );

      recommendations.add(insight);
    }

    // 異常に基づいて追加の推奨事項を生成
    for (final anomaly in anomalies.where((a) => a.severity == AnomalySeverity.critical)) {
      final insight = FinancialInsight(
        id: 'anom_${anomaly.categoryName}_${now.millisecondsSinceEpoch}',
        type: InsightType.anomaly,
        title: 'Alert: ${_formatCategoryName(anomaly.categoryName)} spending surge',
        description: anomaly.description,
        category: anomaly.categoryName,
        priority: 1, // 異常は高優先度
        scoreImpact: -5, // 潜在的なネガティブ影響
        actionableItems: [
          'Review ${anomaly.categoryName} expenses from this month',
          'Identify one-time vs recurring costs',
          'Plan to return to normal spending next month',
        ],
        generatedAt: now,
        expiresAt: now.add(const Duration(days: 30)),
        contextIndicators: {
          'variancePercent': anomaly.variancePercent,
          'difference': anomaly.difference,
        },
      );

      recommendations.add(insight);
    }

    return recommendations;
  }

  /// ユーザーのコンテキストを評価
  static InsightContext assessUserContext(
    List<FinancialHealthScoreTrend> trends,
    int currentScore,
  ) {
    if (trends.isEmpty) {
      return InsightContext(
        userState: UserState.starter,
        scoreTrajectory: ScoreTrajectory.stable,
        monthsAtCurrentLevel: 0,
        previousThreeMonthAverage: currentScore,
        benchmarkPercentile: 50.0,
      );
    }

    // ユーザーの状態を判定
    final userState = _determineUserState(currentScore, trends.length);

    // スコア軌跡を判定
    final scoreTrajectory = _determineScoreTrajectory(trends);

    // 3ヶ月平均を計算
    final lastThree = trends.length >= 3 ? trends.sublist(trends.length - 3) : trends;
    final avgScore = lastThree.fold(0, (sum, t) => sum + t.overallScore) ~/ lastThree.length;

    // 同一レベルの月数を計算（±5ポイント範囲）
    var monthsAtLevel = 0;
    for (final trend in trends.reversed) {
      if ((trend.overallScore - currentScore).abs() <= 5) {
        monthsAtLevel++;
      } else {
        break;
      }
    }

    return InsightContext(
      userState: userState,
      scoreTrajectory: scoreTrajectory,
      monthsAtCurrentLevel: monthsAtLevel,
      previousThreeMonthAverage: avgScore,
      benchmarkPercentile: 50.0, // プレースホルダー（実装時にはFirestoreデータと比較）
    );
  }

  /// コンテキストに応じたメッセージを生成
  static String composeContextualMessage(
    FinancialInsight insight,
    InsightContext context,
    String locale,
  ) {
    final strings = locale == 'ja' ? _japaneseStrings : _englishStrings;

    switch (insight.type) {
      case InsightType.recommendation:
        return _composeRecommendationMessage(insight, context, strings);
      case InsightType.anomaly:
        return _composeAnomalyMessage(insight, context, strings);
      case InsightType.milestone:
        return _composeMilestoneMessage(insight, context, strings);
      case InsightType.trend:
        return _composeTrendMessage(insight, context, strings);
    }
  }

  /// インサイトを優先度でソートしてフィルタ
  static List<FinancialInsight> prioritizeInsights(
    List<FinancialInsight> insights,
    int maxCount,
  ) {
    // 優先度でソート（1が最高）
    insights.sort((a, b) => a.priority.compareTo(b.priority));

    // 最初の maxCount 件を返す
    return insights.take(maxCount).toList();
  }

  // ===== Private Helper Methods =====

  /// 異常の深刻度を計算
  static AnomalySeverity _calculateSeverity(double variance) {
    if (variance >= 30) return AnomalySeverity.critical;
    if (variance >= 20) return AnomalySeverity.warning;
    return AnomalySeverity.info;
  }

  /// 異常の説明テキストを生成
  static String _generateAnomalyDescription(
    String category,
    int current,
    int previous,
    double variance,
    bool isIncreasing,
  ) {
    final direction = isIncreasing ? '増加' : '減少';
    final categoryName = _formatCategoryName(category);
    return '$categoryName の支出が前月比${variance.toStringAsFixed(0)}%$direction しました（¥$previous → ¥$current）';
  }

  /// 推奨される削減額を計算
  static int _calculateRecommendedReduction(String category, int scoreGain) {
    // 簡易的な計算：スコアゲイン × 1000円
    // 実装ではカテゴリごとの支出データに基づいて調整
    return scoreGain * 1000;
  }

  /// 推奨事項のタイトルを生成
  static String _generateRecommendationTitle(String category, int scoreGain) {
    final categoryName = _formatCategoryName(category);
    return '$categoryName を改善して +$scoreGain ポイント';
  }

  /// 推奨事項の説明を生成
  static String _generateRecommendationDescription(
    String category,
    int reduction,
    int scoreGain,
  ) {
    final categoryName = _formatCategoryName(category);
    return '$categoryName の支出を ¥$reduction 削減することで、スコアを +$scoreGain ポイント改善できます。';
  }

  /// アクション項目を生成
  static List<String> _generateActionItems(String category) {
    final categoryName = _formatCategoryName(category);
    return [
      'Review $categoryName expenses from past 3 months',
      'Identify opportunities to reduce $categoryName spending',
      'Set a monthly $categoryName budget and track it',
      'Celebrate your progress!',
    ];
  }

  /// カテゴリ名をフォーマット
  static String _formatCategoryName(String category) {
    const Map<String, String> names = {
      'food': '食費',
      'transportation': '交通',
      'utilities': '光熱費',
      'entertainment': '娯楽',
      'healthcare': '医療',
      'education': '教育',
      'savings': '貯蓄',
      'other': 'その他',
    };
    return names[category] ?? category;
  }

  /// ユーザーの状態を判定
  static UserState _determineUserState(int currentScore, int monthsOfData) {
    if (monthsOfData < 2 || currentScore < 60) return UserState.starter;
    if (currentScore > 80) return UserState.achiever;
    return UserState.improver;
  }

  /// スコア軌跡を判定
  static ScoreTrajectory _determineScoreTrajectory(List<FinancialHealthScoreTrend> trends) {
    if (trends.length < 2) return ScoreTrajectory.stable;

    final recent = trends.sublist((trends.length - 3).clamp(0, trends.length));
    final first = recent.first.overallScore;
    final last = recent.last.overallScore;
    final diff = last - first;

    if (diff > 2) return ScoreTrajectory.improving;
    if (diff < -2) return ScoreTrajectory.declining;
    return ScoreTrajectory.stable;
  }

  // ===== Message Composition Methods =====

  static String _composeRecommendationMessage(
    FinancialInsight insight,
    InsightContext context,
    Map<String, String> strings,
  ) {
    final state = context.userState.toString().split('.').last;
    final message = strings['recommendation_$state'] ?? strings['recommendation_improver'] ?? '';
    return message.replaceAll('{category}', insight.category).replaceAll('{gain}', '${insight.scoreImpact}');
  }

  static String _composeAnomalyMessage(
    FinancialInsight insight,
    InsightContext context,
    Map<String, String> strings,
  ) {
    return insight.description;
  }

  static String _composeMilestoneMessage(
    FinancialInsight insight,
    InsightContext context,
    Map<String, String> strings,
  ) {
    return strings['milestone_congratulations'] ?? '素晴らしい!目標達成おめでとうございます!';
  }

  static String _composeTrendMessage(
    FinancialInsight insight,
    InsightContext context,
    Map<String, String> strings,
  ) {
    return insight.description;
  }

  // ===== Localization Strings =====

  static const Map<String, String> _japaneseStrings = {
    'recommendation_starter': '{category} スコアを改善するチャンスです。月 ¥{amount} 削減で +{gain} ポイント達成可能!',
    'recommendation_improver': '調子がいいですね!{category} をさらに改善して +{gain} ポイント狙いましょう。',
    'recommendation_achiever': 'トップクラスの成績です!新たな挑戦として {category} を極めてみませんか?',
    'milestone_congratulations': '素晴らしい!目標達成おめでとうございます!',
    'trend_improving': '3ヶ月連続で改善中です。このペースを保ちましょう!',
    'trend_stable': '安定した状態をキープしています。次のレベルへの挑戦はいかがですか?',
    'trend_declining': '最近少し下がっているようです。一緒に改善策を探しましょう。',
  };

  static const Map<String, String> _englishStrings = {
    'recommendation_starter': 'Great opportunity to improve {category}. Cut ¥{amount}/month to gain +{gain} points!',
    'recommendation_improver': 'You\'re doing well! Push {category} further to reach +{gain} points.',
    'recommendation_achiever': 'Excellent progress! Ready for a new challenge in {category}?',
    'milestone_congratulations': 'Congratulations on reaching your goal!',
    'trend_improving': 'You\'ve improved for 3 months straight. Keep it up!',
    'trend_stable': 'You\'re maintaining steady progress. Ready to level up?',
    'trend_declining': 'Your score has dipped recently. Let\'s find ways to improve together.',
  };
}
