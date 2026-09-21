import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../domain/models/household_balance_sheet.dart';

/// 純資産の長期推移チャート
class NetWorthTrendChart extends StatelessWidget {
  final NetWorthHistory history;

  const NetWorthTrendChart({
    Key? key,
    required this.history,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final snapshots = history.snapshots;
    if (snapshots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('純資産の推移データが利用可能ではありません'),
        ),
      );
    }

    final maxNetWorth = snapshots.fold<int>(
      0,
      (max, snap) => snap.netWorth > max ? snap.netWorth : max,
    );
    final minNetWorth = snapshots.fold<int>(
      snapshots.first.netWorth,
      (min, snap) => snap.netWorth < min ? snap.netWorth : min,
    );
    final maxY = maxNetWorth.toDouble();
    final minY = (minNetWorth < 0 ? minNetWorth : 0).toDouble();
    final range = (maxY - minY).clamp(1, double.infinity);

    final isPositiveTrend = history.netWorthChange >= 0;
    final lineColor = isPositiveTrend ? Colors.blue : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (range / 5).roundToDouble().clamp(1, double.infinity),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.1),
                  strokeWidth: 1,
                ),
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
                      if (index >= 0 && index < snapshots.length) {
                        final month = snapshots[index].month.split('-').last;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            month,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
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
                    interval: (range / 5).roundToDouble().clamp(1, double.infinity),
                    reservedSize: 55,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '¥${(value / 10000).toInt()}万',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.right,
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              minX: 0,
              maxX: (snapshots.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    snapshots.length,
                    (index) => FlSpot(
                      index.toDouble(),
                      snapshots[index].netWorth.toDouble(),
                    ),
                  ),
                  isCurved: true,
                  color: lineColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: lineColor.withValues(alpha: 0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (spots) => spots.map((spot) {
                    return LineTooltipItem(
                      '純資産: ¥${spot.y.toInt()}',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatBox(
              label: '現在の純資産',
              value: '¥${snapshots.last.netWorth}',
              color: Colors.indigo,
            ),
            _StatBox(
              label: '${snapshots.length}ヶ月間の増減',
              value:
                  '${isPositiveTrend ? '+' : ''}¥${history.netWorthChange}',
              color: isPositiveTrend ? Colors.green : Colors.red,
            ),
            _StatBox(
              label: '増減率',
              value:
                  '${isPositiveTrend ? '+' : ''}${history.netWorthChangePercent.toStringAsFixed(1)}%',
              color: isPositiveTrend ? Colors.green : Colors.red,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}
