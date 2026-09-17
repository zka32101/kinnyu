/// 金融インサイトと異常検知に関するドメインモデル

/// 支出の異常を表すモデル
class SpendingAnomaly {
  final String categoryName;
  final int previousMonthAmount;
  final int currentMonthAmount;
  final double variancePercent;
  final TrendDirection trendDirection;
  final AnomalySeverity severity;
  final String description;

  SpendingAnomaly({
    required this.categoryName,
    required this.previousMonthAmount,
    required this.currentMonthAmount,
    required this.variancePercent,
    required this.trendDirection,
    required this.severity,
    required this.description,
  });

  int get difference => currentMonthAmount - previousMonthAmount;
}

/// トレンドの方向を表す列挙型
enum TrendDirection {
  increasing,
  decreasing,
  stable,
}

/// 異常の深刻度を表す列挙型
enum AnomalySeverity {
  critical,  // >30% variance
  warning,   // 20-30% variance
  info,      // 10-20% variance
}

/// AI が生成する金融インサイト
class FinancialInsight {
  final String id;
  final InsightType type;
  final String title;
  final String description;
  final String category;
  final int priority; // 1 = highest, 3 = lowest
  final int scoreImpact;
  final List<String> actionableItems;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final Map<String, dynamic> contextIndicators;

  FinancialInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.scoreImpact,
    required this.actionableItems,
    required this.generatedAt,
    required this.expiresAt,
    required this.contextIndicators,
  });

  /// インサイトが有効期限内か判定
  bool get isValid => DateTime.now().isBefore(expiresAt);
}

/// インサイトの種類
enum InsightType {
  anomaly,        // 異常支出
  recommendation, // 改善提案
  milestone,      // マイルストーン達成
  trend,          // トレンド分析
}

/// 改善アクションを表すモデル
class ImprovedAction {
  final String targetCategory;
  final int currentScore;
  final int targetScore;
  final int requiredReduction;
  final Duration estimatedTimeToAchieve;
  final double confidenceScore;
  final List<String> relatedActions;

  ImprovedAction({
    required this.targetCategory,
    required this.currentScore,
    required this.targetScore,
    required this.requiredReduction,
    required this.estimatedTimeToAchieve,
    required this.confidenceScore,
    required this.relatedActions,
  });

  int get scoreGain => targetScore - currentScore;
}

/// ユーザーの財務状態コンテキスト
class InsightContext {
  final UserState userState;
  final ScoreTrajectory scoreTrajectory;
  final int monthsAtCurrentLevel;
  final int previousThreeMonthAverage;
  final double benchmarkPercentile;

  InsightContext({
    required this.userState,
    required this.scoreTrajectory,
    required this.monthsAtCurrentLevel,
    required this.previousThreeMonthAverage,
    required this.benchmarkPercentile,
  });
}

/// ユーザーの財務レベルを表す列挙型
enum UserState {
  starter,      // スコア < 60 または 初月
  improver,     // 3ヶ月以上継続的に改善中
  achiever,     // スコア > 80 かつ安定/改善
  plateau,      // 2ヶ月以上変化なし
  regressing,   // 3ヶ月平均で5点以上低下
}

/// スコアの軌跡を表す列挙型
enum ScoreTrajectory {
  improving,   // 上昇中
  stable,      // 横ばい
  declining,   // 低下中
}
