import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../domain/models/financial_health_score.dart';
import '../../../../core/theme/app_colors.dart';

/// 財務健全性スコアの6ヶ月トレンドを表示するラインチャート
/// Overall scoreの推移と個別カテゴリーのオーバーレイを表示
class ScoreTrendChart extends StatefulWidget {
  final List<FinancialHealthScoreTrend> trends;
  final String? selectedCategory; // null = overall score only

  const ScoreTrendChart({
    Key? key,
    required this.trends,
    this.selectedCategory,
  }) : super(key: key);

  @override
  State<ScoreTrendChart> createState() => _ScoreTrendChartState();
}

class _ScoreTrendChartState extends State<ScoreTrendChart> {
  late List<Color> gradientColors;

  @override
  void initState() {
    super.initState();
    gradientColors = [
      const Color(0xFF4CAF50).withValues(alpha: 0.3),
      const Color(0xFF4CAF50).withValues(alpha: 0.0),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trends.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('トレンドデータが利用可能ではありません'),
        ),
      );
    }

    // Sort trends by month to ensure correct ordering
    final sortedTrends = List<FinancialHealthScoreTrend>.from(widget.trends)
      ..sort((a, b) => a.month.compareTo(b.month));

    // Calculate projected score (simple linear projection)
    final currentScore = sortedTrends.last.overallScore.toDouble();
    final scoreThreeMonthsAgo =
        sortedTrends.length >= 3 ? sortedTrends[sortedTrends.length - 3].overallScore.toDouble() : currentScore;
    final projectedScore =
        currentScore + ((currentScore - scoreThreeMonthsAgo) / 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 20,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < sortedTrends.length) {
                        final month = sortedTrends[index].month.split('-').last;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            month,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }
                      return const Text('');
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
              borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
              minX: 0,
              maxX: (sortedTrends.length - 1).toDouble(),
              minY: 0,
              maxY: 100,
              lineBarsData: [
                // Overall Score Line
                LineChartBarData(
                  spots: List.generate(
                    sortedTrends.length,
                    (index) => FlSpot(index.toDouble(), sortedTrends[index].overallScore.toDouble()),
                  ),
                  isCurved: true,
                  gradient: LinearGradient(
                    colors: gradientColors,
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.green,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

                // Projected Score Line (dashed)
                if (projectedScore != currentScore)
                  LineChartBarData(
                    spots: [
                      FlSpot((sortedTrends.length - 1).toDouble(), currentScore),
                      FlSpot(sortedTrends.length.toDouble(), projectedScore),
                    ],
                    isCurved: false,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFFF9800)],
                    ),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  backgroundColor: Colors.grey.shade800,
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map(
                      (LineBarSpot touchedBarSpot) {
                        final flSpot = touchedBarSpot.spot;
                        final month = sortedTrends[flSpot.x.toInt()].month;
                        return LineTooltipItem(
                          '${month}\nスコア: ${flSpot.y.toStringAsFixed(0)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Legend & Projected Score Info
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '実績スコア',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 24),
            Container(
              width: 12,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '予測スコア',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Projected Score Annotation
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.orange,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '予測スコア',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${projectedScore.toStringAsFixed(0)} (今月から ${(projectedScore - currentScore).toStringAsFixed(0)}ポイント)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
