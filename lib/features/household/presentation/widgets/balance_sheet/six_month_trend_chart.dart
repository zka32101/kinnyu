import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/models/spending_evaluation.dart';

/// 6ヶ月トレンドチャート - 収入・支出・貯蓄・貯蓄率を表示
class SixMonthTrendChart extends StatefulWidget {
  final HistoricalComparison comparison;

  const SixMonthTrendChart({
    Key? key,
    required this.comparison,
  }) : super(key: key);

  @override
  State<SixMonthTrendChart> createState() => _SixMonthTrendChartState();
}

class _SixMonthTrendChartState extends State<SixMonthTrendChart> {
  @override
  Widget build(BuildContext context) {
    if (widget.comparison.monthlySnapshots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('トレンドデータが利用可能ではありません'),
        ),
      );
    }

    final snapshots = widget.comparison.monthlySnapshots;
    final maxIncome = snapshots.fold<int>(
      0,
      (max, snap) => snap.income > max ? snap.income : max,
    );
    final maxExpense = snapshots.fold<int>(
      0,
      (max, snap) => snap.expense > max ? snap.expense : max,
    );
    final maxValue = (maxIncome > maxExpense ? maxIncome : maxExpense).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // チャート
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: (maxValue / 5).roundToDouble(),
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
                      if (index >= 0 && index < snapshots.length) {
                        final month = snapshots[index].month.split('-').last;
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
                    interval: (maxValue / 5).roundToDouble(),
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
                    reservedSize: 50,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              minX: 0,
              maxX: (snapshots.length - 1).toDouble(),
              minY: 0,
              maxY: maxValue,
              lineBarsData: [
                // 収入ライン (青)
                LineChartBarData(
                  spots: List.generate(
                    snapshots.length,
                    (index) => FlSpot(
                      index.toDouble(),
                      snapshots[index].income.toDouble(),
                    ),
                  ),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: Colors.blue,
                        strokeWidth: 1,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                ),

                // 支出ライン (赤)
                LineChartBarData(
                  spots: List.generate(
                    snapshots.length,
                    (index) => FlSpot(
                      index.toDouble(),
                      snapshots[index].expense.toDouble(),
                    ),
                  ),
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: Colors.red,
                        strokeWidth: 1,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                ),

                // 貯蓄ライン (緑)
                LineChartBarData(
                  spots: List.generate(
                    snapshots.length,
                    (index) => FlSpot(
                      index.toDouble(),
                      snapshots[index].savings.toDouble(),
                    ),
                  ),
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: Colors.green,
                        strokeWidth: 1,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  tooltipBgColor: Colors.black.withValues(alpha: 0.8),
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      final label = switch (barSpot.barIndex) {
                        0 => '収入: ¥${barSpot.y.toInt()}',
                        1 => '支出: ¥${barSpot.y.toInt()}',
                        2 => '貯蓄: ¥${barSpot.y.toInt()}',
                        _ => '',
                      };
                      return LineTooltipItem(
                        label,
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // レジェンド
        Row(
          children: [
            _LegendItem(color: Colors.blue, label: '収入'),
            const SizedBox(width: 24),
            _LegendItem(color: Colors.red, label: '支出'),
            const SizedBox(width: 24),
            _LegendItem(color: Colors.green, label: '貯蓄'),
          ],
        ),
        const SizedBox(height: 16),

        // 統計情報
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatBox(
              label: '平均貯蓄率',
              value: '${widget.comparison.avgSavingsRate.toStringAsFixed(1)}%',
            ),
            _StatBox(
              label: '6ヶ月貯蓄',
              value: '¥${widget.comparison.totalSavings6Months}',
            ),
            _StatBox(
              label: '月平均貯蓄',
              value: '¥${widget.comparison.avgMonthlySavings}',
            ),
          ],
        ),
      ],
    );
  }
}

/// レジェンド項目
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 2,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

/// 統計ボックス
class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
