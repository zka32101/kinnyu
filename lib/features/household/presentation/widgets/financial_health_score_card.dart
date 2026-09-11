import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/financial_health_provider.dart';
import '../../domain/models/financial_health_score.dart';

/// 財務健全性スコアメインカード
class FinancialHealthScoreCard extends ConsumerWidget {
  final String groupId;

  const FinancialHealthScoreCard({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(financialHealthScoreProvider(groupId));

    return scoreAsync.when(
      data: (score) {
        if (score == null) {
          return _buildSkeletonLoader();
        }
        return _buildScoreCard(context, score);
      },
      loading: () => _buildSkeletonLoader(),
      error: (error, stack) => _buildErrorState(context, error),
    );
  }

  Widget _buildScoreCard(BuildContext context, FinancialHealthScore score) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '財務健全性スコア',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _showInfoDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Score Circle
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background circle
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getScoreColor(score.overallScore)
                                .withOpacity(0.1),
                            border: Border.all(
                              color: _getScoreColor(score.overallScore),
                              width: 3,
                            ),
                          ),
                        ),
                        // Score content
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              score.overallScore.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    color:
                                        _getScoreColor(score.overallScore),
                                    fontWeight: FontWeight.bold,
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
                  // Grade
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getScoreColor(score.overallScore)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'グレード: ${score.grade}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: _getScoreColor(score.overallScore),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Category scores
            Text(
              'カテゴリ別スコア',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildCategoryScores(context, score),

            const SizedBox(height: 24),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToDetail(context),
                icon: const Icon(Icons.trending_up),
                label: const Text('詳細を見る'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryScores(
    BuildContext context,
    FinancialHealthScore score,
  ) {
    final categories = [
      ('貯蓄率', score.savingsRatioScore),
      ('予算遵守率', score.budgetAdherenceScore),
      ('支出管理', score.expenseControlScore),
      ('投資参加度', score.investmentEngagementScore),
      ('社会貢献度', score.socialImpactScore),
    ];

    return Column(
      children: categories.map((category) {
        final label = category.$1;
        final value = category.$2;
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(value),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 8,
                backgroundColor:
                    Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getScoreColor(value),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSkeletonLoader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 200),
            Container(
              height: 16,
              color: Colors.grey.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Container(
              height: 16,
              color: Colors.grey.withOpacity(0.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'スコアを読み込めません',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return const Color(0xFF4CAF50); // Green - A
    if (score >= 80) return const Color(0xFF8BC34A); // Light Green - B
    if (score >= 70) return const Color(0xFFFFC107); // Amber - C
    if (score >= 60) return const Color(0xFFFF9800); // Orange - D
    return const Color(0xFFF44336); // Red - F
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('財務健全性スコアについて'),
        content: const Text(
          '財務健全性スコアは、以下5つの要素から総合的に評価されます：\n\n'
          '• 貯蓋率（25%）: 毎月の貯蓄額の割合\n'
          '• 予算遵守率（25%）: 予算に対する支出の比率\n'
          '• 支出管理（20%）: 支出パターンの安定性\n'
          '• 投資参加度（15%）: 収入に対する投資額\n'
          '• 社会貢献度（15%）: 寄付などの社会貢献\n\n'
          'スコアが高いほど、健全な財務状況です。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    // TODO: Navigate to financial health detail page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('詳細ページに移動します')),
    );
  }
}
