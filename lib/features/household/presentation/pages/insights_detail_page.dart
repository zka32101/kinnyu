import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/financial_insight.dart';
import '../providers/financial_insights_provider.dart';
import '../providers/financial_health_provider.dart';

/// AI インサイトの詳細ページ（複数タブ）
class InsightsDetailPage extends ConsumerStatefulWidget {
  final String groupId;
  final String locale;

  const InsightsDetailPage({
    Key? key,
    required this.groupId,
    this.locale = 'ja',
  }) : super(key: key);

  @override
  ConsumerState<InsightsDetailPage> createState() => _InsightsDetailPageState();
}

class _InsightsDetailPageState extends ConsumerState<InsightsDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('詳細インサイト'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '異常検知', icon: Icon(Icons.warning_rounded)),
            Tab(text: '改善提案', icon: Icon(Icons.lightbulb_rounded)),
            Tab(text: 'コンテキスト', icon: Icon(Icons.info_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnomaliesTab(),
          _buildRecommendationsTab(),
          _buildContextTab(),
        ],
      ),
    );
  }

  Widget _buildAnomaliesTab() {
    final anomaliesAsync = ref.watch(spendingAnomaliesProvider(widget.groupId));

    return anomaliesAsync.when(
      data: (anomalies) {
        if (anomalies.isEmpty) {
          return _buildEmptyTabState(
            icon: Icons.check_circle_outline,
            title: '異常な支出がありません',
            message: 'すべてのカテゴリが通常の範囲内です。',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: anomalies.length,
          itemBuilder: (context, index) {
            final anomaly = anomalies[index];
            return _buildAnomalyCard(context, anomaly);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorTabState(error),
    );
  }

  Widget _buildRecommendationsTab() {
    final insightsAsync = ref.watch(financialInsightsProvider(widget.groupId));
    final messagesAsync =
        ref.watch(insightContextualMessagesProvider((widget.groupId, widget.locale)));

    return insightsAsync.when(
      data: (insights) {
        final recommendations =
            insights.where((i) => i.type == InsightType.recommendation).toList();

        if (recommendations.isEmpty) {
          return _buildEmptyTabState(
            icon: Icons.celebration,
            title: '目標達成中!',
            message: '現在の改善提案はありません。素晴らしい結果です!',
          );
        }

        return messagesAsync.when(
          data: (messages) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final rec = recommendations[index];
                final message = messages[rec.id] ?? rec.description;
                return _buildRecommendationCard(context, rec, message);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final rec = recommendations[index];
              return _buildRecommendationCard(context, rec, rec.description);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorTabState(error),
    );
  }

  Widget _buildContextTab() {
    final contextAsync = ref.watch(userContextProvider(widget.groupId));
    final scoreAsync = ref.watch(financialHealthScoreProvider(widget.groupId));
    final trendsAsync = ref.watch(financialHealthScoreTrendProvider(widget.groupId));

    return contextAsync.when(
      data: (_) {
        return scoreAsync.when(
          data: (score) {
            return trendsAsync.when(
              data: (trends) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserStateCard(context, score),
                      const SizedBox(height: 16),
                      _buildScoreTrendCard(trends),
                      const SizedBox(height: 16),
                      _buildPersonalizedMessageCard(context),
                    ],
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildErrorTabState('Error loading trends'),
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildErrorTabState('Error loading score'),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorTabState(error),
    );
  }

  Widget _buildAnomalyCard(BuildContext context, SpendingAnomaly anomaly) {
    final severityColor = _getSeverityColor(anomaly.severity);
    final severityLabel = _getSeverityLabel(anomaly.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.trending_up, color: severityColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anomaly.description,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        severityLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: severityColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '前月',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      Text(
                        '¥${anomaly.previousMonthAmount}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Icon(
                    anomaly.trendDirection == TrendDirection.increasing
                        ? Icons.arrow_forward
                        : Icons.arrow_downward,
                    color: anomaly.trendDirection == TrendDirection.increasing
                        ? Colors.red
                        : Colors.green,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '今月',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      Text(
                        '¥${anomaly.currentMonthAmount}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: anomaly.trendDirection ==
                                      TrendDirection.increasing
                                  ? Colors.red
                                  : Colors.green,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '変化率: ${anomaly.variancePercent.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    FinancialInsight recommendation,
    String message,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lightbulb_rounded, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+${recommendation.scoreImpact} points',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.5,
                  ),
            ),
            if (recommendation.actionableItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'アクションステップ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ...recommendation.actionableItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                height: 1.4,
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserStateCard(BuildContext context, dynamic score) {
    final stateIcon = _getUserStateIcon(UserState.improver);
    const stateLabel = '改善中';
    const stateDescription = 'あなたのスコアは3ヶ月連続で改善しています。このペースを保ちましょう!';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'あなたの状態',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue[100],
                  ),
                  child: Icon(stateIcon, color: Colors.blue, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stateLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stateDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              height: 1.3,
                            ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreTrendCard(List<dynamic> trends) {
    if (trends.isEmpty) {
      return const SizedBox.shrink();
    }

    final recent = trends.sublist((trends.length - 3).clamp(0, trends.length));
    final first = recent.first.overallScore;
    final last = recent.last.overallScore;
    final diff = last - first;
    final trendLabel =
        diff > 2 ? '📈 改善中' : (diff < -2 ? '📉 低下中' : '➡️ 安定');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最近のトレンド',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3ヶ月前',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    Text(
                      '$first',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Icon(
                  diff > 2
                      ? Icons.trending_up
                      : (diff < -2 ? Icons.trending_down : Icons.trending_flat),
                  color: diff > 2
                      ? Colors.green
                      : (diff < -2 ? Colors.red : Colors.grey),
                  size: 28,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '現在',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    Text(
                      '$last',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: diff > 0 ? Colors.green : Colors.grey,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                trendLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizedMessageCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'パーソナライズされたメッセージ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Text(
                'あなたの金融スキルは着実に上がっています。このまま3ヶ月継続できれば、'
                '次のレベル(Achiever)に到達します。毎日のコツコツとした管理が成功の鍵です。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.5,
                      color: Colors.blue[900],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTabState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorTabState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'エラーが発生しました',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ===== Helper Methods =====

  Color _getSeverityColor(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.critical:
        return Colors.red;
      case AnomalySeverity.warning:
        return Colors.orange;
      case AnomalySeverity.info:
        return Colors.amber;
    }
  }

  String _getSeverityLabel(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.critical:
        return '危機的 (>30%)';
      case AnomalySeverity.warning:
        return '警告 (20-30%)';
      case AnomalySeverity.info:
        return '情報 (10-20%)';
    }
  }

  IconData _getUserStateIcon(UserState state) {
    switch (state) {
      case UserState.starter:
        return Icons.emoji_events_outlined;
      case UserState.improver:
        return Icons.trending_up;
      case UserState.achiever:
        return Icons.star;
      case UserState.plateau:
        return Icons.trending_flat;
      case UserState.regressing:
        return Icons.trending_down;
    }
  }
}
