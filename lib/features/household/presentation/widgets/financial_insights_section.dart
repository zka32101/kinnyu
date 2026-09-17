import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/financial_insights_provider.dart';
import 'insight_card.dart';

/// ダッシュボード上の金融インサイトセクション
class FinancialInsightsSection extends ConsumerWidget {
  final String groupId;
  final VoidCallback? onViewAll;
  final String locale;

  const FinancialInsightsSection({
    Key? key,
    required this.groupId,
    this.onViewAll,
    this.locale = 'ja',
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topInsightsAsync = ref.watch(topInsightsProvider(groupId));
    final messagesAsync = ref.watch(insightContextualMessagesProvider((groupId, locale)));

    return topInsightsAsync.when(
      data: (insights) {
        if (insights.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildInsightsSection(context, insights, messagesAsync);
      },
      loading: () => _buildSkeletonLoader(context),
      error: (error, stack) => _buildErrorState(context, error),
    );
  }

  Widget _buildInsightsSection(
    BuildContext context,
    List<dynamic> insights,
    AsyncValue<Map<String, String>> messagesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: Colors.blue[700], size: 24),
              const SizedBox(width: 8),
              Text(
                'AI-Powered Insights',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              if (insights.length > 3)
                TextButton.icon(
                  onPressed: onViewAll,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View All'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),
        // Insight Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            spacing: 12,
            children: insights.asMap().entries.map((entry) {
              final insight = entry.value;
              final message = messagesAsync.when(
                data: (messages) => messages[insight.id] ?? insight.description,
                loading: () => insight.description,
                error: (_, __) => insight.description,
              );

              return InsightCard(
                insight: insight,
                contextMessage: message,
                onDismiss: () {
                  // TODO: Implement dismiss functionality
                },
                onViewDetails: onViewAll,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Colors.green[300],
              ),
              const SizedBox(height: 16),
              Text(
                'All Categories Within Budget!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You\'re doing a great job maintaining your budget.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 150,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Insight card skeletons
          ...List.generate(
            2,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: index < 1 ? 12 : 0),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Insights Temporarily Unavailable',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'We couldn\'t load your insights. Please try again later.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
