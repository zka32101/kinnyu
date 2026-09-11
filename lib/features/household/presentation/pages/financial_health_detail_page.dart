import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/financial_health_provider.dart';
import '../widgets/charts/score_trend_chart.dart';
import '../widgets/charts/category_radar_chart.dart';
import '../widgets/charts/monthly_comparison_chart.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:flutter/foundation.dart';

/// 財務健全性スコアの詳細分析ページ
/// 4つのタブで総合的な分析を提供：Overview, Categories, Trends, Recommendations
class FinancialHealthDetailPage extends ConsumerWidget {
  final String groupId;

  const FinancialHealthDetailPage({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreDetailAsync = ref.watch(financialHealthScoreDetailProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('財務健全性分析'),
        elevation: 0,
      ),
      body: scoreDetailAsync.when(
        data: (detail) {
          if (detail == null) {
            return const Center(
              child: Text('データを読み込めません'),
            );
          }
          return _DetailPageContent(detail: detail, groupId: groupId);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }
}

class _DetailPageContent extends ConsumerWidget {
  final FinancialHealthScoreDetail detail;
  final String groupId;

  const _DetailPageContent({
    required this.detail,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(financialHealthScoreTrendProvider(groupId));
    final improvementGuideAsync = ref.watch(scoreImprovementGuideProvider(groupId));
    final savingsGoalAsync = ref.watch(savingsGoalProgressProvider(groupId));
    final budgetOptAsync = ref.watch(budgetOptimizationProvider(groupId));

    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          // Tab Bar
          Material(
            color: Colors.white,
            elevation: 1,
            child: TabBar(
              indicatorColor: Theme.of(context).primaryColor,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: '概要'),
                Tab(text: 'カテゴリ'),
                Tab(text: 'トレンド'),
                Tab(text: '改善提案'),
                Tab(text: '最適化'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: Overview
                _OverviewTab(detail: detail, groupId: groupId),

                // Tab 2: Categories
                _CategoriesTab(detail: detail),

                // Tab 3: Trends
                trendAsync.when(
                  data: (trends) => _TrendsTab(trends: trends, currentScore: detail.score),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('トレンド読み込みエラー: $error')),
                ),

                // Tab 4: Recommendations
                _RecommendationsTab(recommendations: detail.recommendations),

                // Tab 5: Optimization (Improvement Guide + Budget Optimization)
                _OptimizationTab(
                  improvementGuideAsync: improvementGuideAsync,
                  budgetOptAsync: budgetOptAsync,
                  savingsGoalAsync: savingsGoalAsync,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================= Tab 1: Overview =================
class _OverviewTab extends ConsumerWidget {
  final FinancialHealthScoreDetail detail;
  final String groupId;

  const _OverviewTab({required this.detail, required this.groupId});

  Color _getScoreColor(int score) {
    if (score >= 90) return const Color(0xFF4CAF50); // Green - A
    if (score >= 80) return const Color(0xFF8BC34A); // Light Green - B
    if (score >= 70) return const Color(0xFFFFC107); // Amber - C
    if (score >= 60) return const Color(0xFFFF9800); // Orange - D
    return const Color(0xFFF44336); // Red - F
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsGoalAsync = ref.watch(savingsGoalProgressProvider(groupId));
    final score = detail.score;
    final scoreColor = _getScoreColor(score.overallScore);

    return SingleChildScrollView(
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Score Circle
          Center(
            child: Column(
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scoreColor.withValues(alpha: 0.1),
                          border: Border.all(
                            color: scoreColor,
                            width: 3,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            score.overallScore.toString(),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          ),
                          Text(
                            'スコア',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'グレード: ${score.grade}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Monthly Comparison
          Text(
            '月間比較',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          MonthlyComparisonChart(
            currentScore: score,
            targetScore: 85,
          ),
          const SizedBox(height: 32),

          // Savings Goal Progress
          Text(
            '今月の貯蓄目標進捗',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          savingsGoalAsync.when(
            data: (goal) => _SavingsGoalProgressCard(
              currentSavings: goal.currentSavings,
              monthlyGoal: goal.monthlyGoal,
              progressPercent: goal.progressPercent,
              remainingToGoal: goal.remainingToGoal,
            ),
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Text('読み込みエラー: $error'),
          ),
          const SizedBox(height: 32),

          // Top Recommendations
          Text(
            'トップ改善提案',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (detail.recommendations.isNotEmpty)
            ...detail.recommendations.take(2).map(
                  (rec) => _RecommendationCard(recommendation: rec),
                )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '改善提案がありません。素晴らしい！',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ================= Tab 2: Categories =================
class _CategoriesTab extends StatelessWidget {
  final FinancialHealthScoreDetail detail;

  const _CategoriesTab({required this.detail});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'カテゴリバランス',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          CategoryRadarChart(categories: detail.categories),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ================= Tab 3: Trends =================
class _TrendsTab extends StatelessWidget {
  final List<FinancialHealthScoreTrend> trends;
  final FinancialHealthScore currentScore;

  const _TrendsTab({
    required this.trends,
    required this.currentScore,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '6ヶ月トレンド',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'スコアの推移と予測を表示します',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 16),
          ScoreTrendChart(trends: trends),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ================= Tab 4: Recommendations =================
class _RecommendationsTab extends StatelessWidget {
  final List<HealthScoreRecommendation> recommendations;

  const _RecommendationsTab({required this.recommendations});

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFF44336);
      case 'medium':
        return const Color(0xFFFFC107);
      case 'low':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return '高い優先度';
      case 'medium':
        return '中程度';
      case 'low':
        return '低い優先度';
      default:
        return priority;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.done_all,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                '素晴らしい!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                '改善の余地はありません。\n現在の財務健全性は最適な状態です。',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '改善提案',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recommendations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _RecommendationCard(
                recommendation: recommendations[index],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ================= Shared Components =================
class _RecommendationCard extends StatelessWidget {
  final HealthScoreRecommendation recommendation;

  const _RecommendationCard({required this.recommendation});

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFF44336);
      case 'medium':
        return const Color(0xFFFFC107);
      case 'low':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return '高い優先度';
      case 'medium':
        return '中程度';
      case 'low':
        return '低い優先度';
      default:
        return priority;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(recommendation.priority);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: priorityColor.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
        color: priorityColor.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  recommendation.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPriorityLabel(recommendation.priority),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  _buildTag(
                    label: recommendation.category,
                    color: Theme.of(context).primaryColor,
                  ),
                  _buildTag(
                    label: '+${recommendation.potentialScoreGain}pt',
                    color: const Color(0xFF4CAF50),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${recommendation.actionType}アクションを実行します',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('実行'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ================= Widgets =================

/// 貯蓄目標進捗カード
class _SavingsGoalProgressCard extends StatelessWidget {
  final int currentSavings;
  final int monthlyGoal;
  final double progressPercent;
  final int remainingToGoal;

  const _SavingsGoalProgressCard({
    required this.currentSavings,
    required this.monthlyGoal,
    required this.progressPercent,
    required this.remainingToGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '¥${currentSavings.toString()}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
              Text(
                '目標: ¥${monthlyGoal.toString()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (progressPercent / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation(Color(0xFF4CAF50)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '進捗: ${progressPercent.toStringAsFixed(1)}% (残り: ¥${remainingToGoal.toString()})',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: remainingToGoal <= 0 ? const Color(0xFF4CAF50) : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab 5: 最適化（改善提案 + 予算最適化）
class _OptimizationTab extends ConsumerWidget {
  final AsyncValue<List<ScoreImprovementAction>> improvementGuideAsync;
  final AsyncValue<List<BudgetOptimization>> budgetOptAsync;
  final AsyncValue<({int currentSavings, int monthlyGoal, double progressPercent, int remainingToGoal})> savingsGoalAsync;

  const _OptimizationTab({
    required this.improvementGuideAsync,
    required this.budgetOptAsync,
    required this.savingsGoalAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Savings Goal Progress Section
          Text(
            '貯蓄進捗',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          savingsGoalAsync.when(
            data: (goal) => _SavingsGoalProgressCard(
              currentSavings: goal.currentSavings,
              monthlyGoal: goal.monthlyGoal,
              progressPercent: goal.progressPercent,
              remainingToGoal: goal.remainingToGoal,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('エラー: $error'),
          ),
          const SizedBox(height: 32),

          // Improvement Guide Section
          Text(
            'スコア改善ガイド',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          improvementGuideAsync.when(
            data: (actions) {
              if (actions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('すべてのカテゴリで優秀な成績です！'),
                );
              }
              return Column(
                children: actions.map((action) {
                  return _ImprovementActionCard(action: action);
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('エラー: $error'),
          ),
          const SizedBox(height: 32),

          // Budget Optimization Section
          Text(
            '予算最適化提案',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          budgetOptAsync.when(
            data: (optimizations) {
              if (optimizations.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('予算配分は最適化されています'),
                );
              }
              return Column(
                children: optimizations.map((opt) {
                  return _BudgetOptimizationCard(optimization: opt);
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('エラー: $error'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// スコア改善アクションカード
class _ImprovementActionCard extends StatelessWidget {
  final ScoreImprovementAction action;

  const _ImprovementActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    action.displayName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${action.currentScore} → ${action.targetScore}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'アクション:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            ...action.actionItems.map((item) {
              return Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  '• $item',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// 予算最適化カード
class _BudgetOptimizationCard extends StatelessWidget {
  final BudgetOptimization optimization;

  const _BudgetOptimizationCard({required this.optimization});

  @override
  Widget build(BuildContext context) {
    final isOverspent = optimization.actualSpent > optimization.currentBudget * 1.3;
    final cardColor = isOverspent
      ? const Color(0xFFF44336)
      : const Color(0xFF4CAF50);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  optimization.displayName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${optimization.utilizationRate.toStringAsFixed(1)}x',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: cardColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '予算: ¥${optimization.currentBudget}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '実績: ¥${optimization.actualSpent}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isOverspent ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '推奨予算: ¥${optimization.recommendedBudget}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              optimization.recommendation,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
