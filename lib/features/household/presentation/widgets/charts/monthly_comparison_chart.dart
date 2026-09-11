import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/models/financial_health_score.dart';

/// 先月・今月・目標スコアを比較するグループバーチャート
class MonthlyComparisonChart extends StatelessWidget {
  final FinancialHealthScore currentScore;
  final FinancialHealthScoreTrend? previousMonthTrend;
  final int targetScore;

  const MonthlyComparisonChart({
    Key? key,
    required this.currentScore,
    this.previousMonthTrend,
    this.targetScore = 85,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get scores
    final prevOverall = previousMonthTrend?.overallScore ?? currentScore.overallScore;
    final currOverall = currentScore.overallScore;

    // Group bar chart data
    final groupData = [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: prevOverall.toDouble(),
            color: Colors.blue.withValues(alpha: 0.6),
            width: 12,
          ),
          BarChartRodData(
            toY: currOverall.toDouble(),
            color: Colors.blue,
            width: 12,
          ),
          BarChartRodData(
            toY: targetScore.toDouble(),
            color: Colors.green,
            width: 12,
          ),
        ],
        showingTooltipIndicators: [0, 1, 2],
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 280,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.center,
              maxY: 100,
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  backgroundColor: Colors.grey.shade800,
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    String label;
                    switch (rodIndex) {
                      case 0:
                        label = '先月';
                        break;
                      case 1:
                        label = '今月';
                        break;
                      case 2:
                        label = '目標';
                        break;
                      default:
                        label = '';
                    }
                    return BarTooltipItem(
                      '$label\n${rod.toY.toStringAsFixed(0)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'スコア',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 20,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.right,
                      );
                    },
                    reservedSize: 42,
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
              barGroups: groupData,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(
              color: Colors.blue.withValues(alpha: 0.6),
              label: '先月スコア',
              value: prevOverall.toString(),
            ),
            const SizedBox(width: 24),
            _LegendItem(
              color: Colors.blue,
              label: '今月スコア',
              value: currOverall.toString(),
            ),
            const SizedBox(width: 24),
            _LegendItem(
              color: Colors.green,
              label: '目標スコア',
              value: targetScore.toString(),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Improvement Summary
        _ImprovementSummary(
          previousScore: prevOverall,
          currentScore: currOverall,
          targetScore: targetScore,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _ImprovementSummary extends StatelessWidget {
  final int previousScore;
  final int currentScore;
  final int targetScore;

  const _ImprovementSummary({
    required this.previousScore,
    required this.currentScore,
    required this.targetScore,
  });

  @override
  Widget build(BuildContext context) {
    final improvement = currentScore - previousScore;
    final remainingToTarget = targetScore - currentScore;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (improvement > 0)
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  '先月比 +$improvement ポイント改善',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            )
          else if (improvement < 0)
            Row(
              children: [
                Icon(Icons.trending_down, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Text(
                  '先月比 ${improvement.abs()} ポイント減少',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            )
          else
            const Text(
              '先月と同じスコア',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.flag, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Text(
                '目標まであと $remainingToTarget ポイント',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
