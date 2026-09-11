import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../domain/models/financial_health_score.dart';

/// 財務健全性スコアの5つのカテゴリを表示するレーダーチャート
/// 各カテゴリのバランスを可視化する
class CategoryRadarChart extends StatelessWidget {
  final List<HealthScoreCategory> categories;

  const CategoryRadarChart({
    Key? key,
    required this.categories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('カテゴリデータが利用可能ではありません'),
        ),
      );
    }

    // 5つのカテゴリを想定（Savings, Budget, Expense, Investment, Social）
    final scores = categories.map((c) => c.score.toDouble()).toList();

    // スコアを0-100スケールに正規化
    final maxScore = 100.0;
    final scaledScores = scores.map((score) => score / maxScore).toList();

    return Column(
      children: [
        SizedBox(
          height: 300,
          width: 300,
          child: RadarChart(
            RadarChartData(
              dataSets: [
                RadarDataSet(
                  fillColor: Colors.green.withValues(alpha: 0.25),
                  borderColor: Colors.green,
                  pointColor: Colors.green,
                  dataEntries: scaledScores.map((score) => RadarEntry(value: score)).toList(),
                  borderWidth: 2,
                  pointSize: 6,
                )
              ],
              radarBackgroundColor: Colors.transparent,
              borderData: RadarBorderData(show: true),
              gridBorderData: RadarGridBorderData(
                show: true,
                color: Colors.grey.withValues(alpha: 0.2),
              ),
              ticksTextStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
              radarTouchData: RadarTouchData(enabled: true),
              getTitle: (index, angle) {
                if (index >= categories.length) return RadarChartTitle(text: '');
                return RadarChartTitle(
                  text: categories[index].displayName,
                  angle: angle,
                );
              },
              tickCount: 5,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Category Details Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _CategoryTile(category: category);
          },
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final HealthScoreCategory category;

  const _CategoryTile({required this.category});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.amber;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'excellent':
        return '優秀';
      case 'good':
        return '良好';
      case 'fair':
        return '中程度';
      case 'poor':
        return '要改善';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(category.status);
    final statusLabel = _getStatusLabel(category.status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.displayName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            category.score.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 11,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: category.score / 100,
              minHeight: 6,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
