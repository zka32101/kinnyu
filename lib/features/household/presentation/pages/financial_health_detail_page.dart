import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/financial_health_score.dart';
import '../providers/financial_health_provider.dart';
import '../widgets/charts/score_trend_chart.dart';
import '../widgets/charts/category_radar_chart.dart';
import '../widgets/charts/monthly_comparison_chart.dart';
import '../../../../core/theme/app_colors.dart';

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

    return DefaultTabController(
      length: 4,
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
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: Overview
                _OverviewTab(detail: detail),

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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================= Tab 1: Overview =================
class _OverviewTab extends StatelessWidget {
  final FinancialHealthScoreDetail detail;

  const _OverviewTab({required this.detail});

  Color _getScoreColor(int score) {
    if (score >= 90) return const Color(0xFF4CAF50); // Green - A
    if (score >= 80) return const Color(0xFF8BC34A); // Light Green - B
    if (score >= 70) return const Color(0xFFFFC107); // Amber - C
    if (score >= 60) return const Color(0xFFFF9800); // Orange - D
    return const Color(0xFFF44336); // Red - F
  }

  @override
  Widget build(BuildContext context) {
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
