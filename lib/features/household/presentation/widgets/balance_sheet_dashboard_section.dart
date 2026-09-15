import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/household_balance_sheet_provider.dart';
import 'balance_sheet/simple_balance_card.dart';
import 'balance_sheet/detailed_balance_sheet_card.dart';
import 'balance_sheet/category_evaluation_card.dart';
import 'balance_sheet/spending_recommendations_section.dart';
import 'balance_sheet/six_month_trend_chart.dart';
import 'balance_sheet/monthly_comparison_table.dart';

/// バランスシートダッシュボードセクション - タブ付きインターフェース
class BalanceSheetDashboardSection extends ConsumerWidget {
  final String groupId;

  const BalanceSheetDashboardSection({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Card(
        elevation: 0,
        child: Column(
          children: [
            // タブバー
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[300]!,
                  ),
                ),
              ),
              child: const TabBar(
                tabs: [
                  Tab(text: '簡易'),
                  Tab(text: '詳細'),
                  Tab(text: 'トレンド'),
                  Tab(text: 'レコメ'),
                ],
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
              ),
            ),

            // タブコンテンツ
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: 簡易バランス
                  _SimpleBalanceTab(groupId: groupId),

                  // Tab 2: 詳細バランスシート
                  _DetailedBalanceTab(groupId: groupId),

                  // Tab 3: トレンド
                  _TrendTab(groupId: groupId),

                  // Tab 4: レコメンデーション
                  _RecommendationTab(groupId: groupId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab 1: 簡易バランス
class _SimpleBalanceTab extends ConsumerWidget {
  final String groupId;

  const _SimpleBalanceTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(simpleBalanceSummaryProvider(groupId));

    return balanceAsync.when(
      data: (balance) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SimpleBalanceCard(summary: balance),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, st) => Center(
        child: Text('エラー: ${error.toString()}'),
      ),
    );
  }
}

/// Tab 2: 詳細バランスシート
class _DetailedBalanceTab extends ConsumerWidget {
  final String groupId;

  const _DetailedBalanceTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheetAsync = ref.watch(householdBalanceSheetProvider(groupId));

    return sheetAsync.when(
      data: (sheet) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: DetailedBalanceSheetCard(sheet: sheet),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, st) => Center(
        child: Text('エラー: ${error.toString()}'),
      ),
    );
  }
}

/// Tab 3: トレンド
class _TrendTab extends ConsumerWidget {
  final String groupId;

  const _TrendTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisonAsync = ref.watch(historicalComparisonProvider(groupId));

    return comparisonAsync.when(
      data: (comparison) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📊 6ヶ月トレンド',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SixMonthTrendChart(comparison: comparison),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '📋 月別比較',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: MonthlyComparisonTable(comparison: comparison),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, st) => Center(
        child: Text('エラー: ${error.toString()}'),
      ),
    );
  }
}

/// Tab 4: レコメンデーション
class _RecommendationTab extends ConsumerWidget {
  final String groupId;

  const _RecommendationTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = _getCurrentMonth();
    final evaluationAsync =
        ref.watch(spendingEvaluationProvider((groupId, month)));

    return evaluationAsync.when(
      data: (evaluation) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpendingRecommendationsSection(evaluation: evaluation),
              const SizedBox(height: 24),
              const Text(
                '📊 カテゴリ別評価',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ...evaluation.categoryEvaluations
                  .map((cat) => CategoryEvaluationCard(evaluation: cat))
                  .toList(),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, st) => Center(
        child: Text('エラー: ${error.toString()}'),
      ),
    );
  }
}

String _getCurrentMonth() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}
