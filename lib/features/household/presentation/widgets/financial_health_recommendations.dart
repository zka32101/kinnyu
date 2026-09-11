import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/financial_health_provider.dart';
import '../../domain/models/financial_health_score.dart';

/// 財務健全性改善推奨事項ウィジェット
class FinancialHealthRecommendations extends ConsumerWidget {
  final String groupId;

  const FinancialHealthRecommendations({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync =
        ref.watch(financialHealthRecommendationsProvider(groupId));

    return recommendationsAsync.when(
      data: (recommendations) {
        if (recommendations.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildRecommendationsList(context, recommendations);
      },
      loading: () => _buildSkeletonLoader(),
      error: (error, stack) => _buildErrorState(context, error),
    );
  }

  Widget _buildRecommendationsList(
    BuildContext context,
    List<HealthScoreRecommendation> recommendations,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  'スコア改善のヒント',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recommendations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final rec = recommendations[index];
                return _buildRecommendationItem(context, rec);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(
    BuildContext context,
    HealthScoreRecommendation recommendation,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: _getPriorityColor(recommendation.priority).withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
        color: _getPriorityColor(recommendation.priority).withOpacity(0.05),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getPriorityColor(recommendation.priority)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPriorityLabel(recommendation.priority),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getPriorityColor(recommendation.priority),
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
                onPressed: () => _handleAction(context, recommendation),
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
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
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

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
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
            Text(
              '改善の余地はありません。\n現在の財務健全性は最適な状態です。',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Container(
                    height: 16,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ],
              ),
            ),
          ),
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
        child: Center(
          child: Text(
            '推奨事項を読み込めません',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFF44336); // Red
      case 'medium':
        return const Color(0xFFFFC107); // Amber
      case 'low':
        return const Color(0xFF4CAF50); // Green
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

  void _handleAction(
    BuildContext context,
    HealthScoreRecommendation recommendation,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${recommendation.actionType}アクションを実行します'),
      ),
    );
    // TODO: Route to appropriate action page based on actionType
  }
}
