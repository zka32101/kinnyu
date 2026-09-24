import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../domain/models/nisa_ideco_calculator.dart';

class NisaIdecoPage extends StatefulWidget {
  const NisaIdecoPage({Key? key}) : super(key: key);

  @override
  State<NisaIdecoPage> createState() => _NisaIdecoPageState();
}

class _NisaIdecoPageState extends State<NisaIdecoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tsumitateController = TextEditingController(text: '0');
  final _growthController = TextEditingController(text: '0');
  final _lifetimeController = TextEditingController(text: '0');

  IdecoOccupationType _occupation = IdecoOccupationType.employeeNoPension;
  final _idecoContributionController = TextEditingController(text: '10000');
  double _assumedTaxRate = 20.0;

  double _nisaGrowthYears = 20;
  double _nisaGrowthRate = 5.0;
  double _idecoGrowthYears = 20;
  double _idecoGrowthRate = 3.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tsumitateController.dispose();
    _growthController.dispose();
    _lifetimeController.dispose();
    _idecoContributionController.dispose();
    super.dispose();
  }

  NisaResult get _nisaResult {
    return NisaIdecoCalculator.calculateNisa(
      NisaInput(
        tsumitateInvestedThisYear:
            int.tryParse(_tsumitateController.text) ?? 0,
        growthInvestedThisYear: int.tryParse(_growthController.text) ?? 0,
        lifetimeInvestedTotal: int.tryParse(_lifetimeController.text) ?? 0,
      ),
    );
  }

  IdecoResult get _idecoResult {
    return NisaIdecoCalculator.calculateIdeco(
      IdecoInput(
        occupationType: _occupation,
        monthlyContribution:
            int.tryParse(_idecoContributionController.text) ?? 0,
        assumedTaxRatePercent: _assumedTaxRate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NISA・iDeCo枠管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'NISA'),
            Tab(text: 'iDeCo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildNisaTab(), _buildIdecoTab()],
      ),
    );
  }

  Widget _buildNisaTab() {
    final result = _nisaResult;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '新NISA（2024年〜）は、つみたて投資枠 年120万円・成長投資枠 年240万円、'
            '生涯投資枠 合計1,800万円が非課税で投資できます。',
            style: TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _tsumitateController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '今年のつみたて投資枠 投資済み額',
            prefixText: '¥',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _growthController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '今年の成長投資枠 投資済み額',
            prefixText: '¥',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _lifetimeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '生涯投資枠 累計投資済み額',
            prefixText: '¥',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade300, Colors.green.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('今年の残り投資可能額',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Text(
                '¥${result.annualRemaining}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statColumn('つみたて枠 残り', '¥${result.tsumitateRemaining}'),
                  _statColumn('成長投資枠 残り', '¥${result.growthRemaining}'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '生涯投資枠 残り: ¥${result.lifetimeRemaining}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildGrowthSection(
          annualContribution: (int.tryParse(_tsumitateController.text) ?? 0) +
              (int.tryParse(_growthController.text) ?? 0),
          years: _nisaGrowthYears,
          rate: _nisaGrowthRate,
          color: Colors.green,
          onYearsChanged: (v) => setState(() => _nisaGrowthYears = v),
          onRateChanged: (v) => setState(() => _nisaGrowthRate = v),
        ),
      ],
    );
  }

  Widget _buildIdecoTab() {
    final result = _idecoResult;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'iDeCoの掛金は全額が所得控除の対象になります。加入区分により月額上限が異なります。',
            style: TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<IdecoOccupationType>(
          value: _occupation,
          decoration: const InputDecoration(
            labelText: '加入区分',
            border: OutlineInputBorder(),
          ),
          items: IdecoOccupationType.values.map((type) {
            return DropdownMenuItem(value: type, child: Text(type.displayName));
          }).toList(),
          onChanged: (v) => setState(() => _occupation = v!),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _idecoContributionController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '毎月の掛金',
            prefixText: '¥',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Text(
          '想定の合計税率（所得税+住民税）: ${_assumedTaxRate.toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: _assumedTaxRate,
          min: 15,
          max: 55,
          divisions: 40,
          label: '${_assumedTaxRate.toStringAsFixed(0)}%',
          onChanged: (v) => setState(() => _assumedTaxRate = v),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade300, Colors.purple.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('年間の概算節税額',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Text(
                '¥${result.estimatedAnnualTaxSaving}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statColumn('月額上限', '¥${result.monthlyLimit}'),
                  _statColumn('月額の残り枠', '¥${result.monthlyRemaining}'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '年間拠出額: ¥${result.annualContribution}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildGrowthSection(
          annualContribution: result.annualContribution,
          years: _idecoGrowthYears,
          rate: _idecoGrowthRate,
          color: Colors.purple,
          onYearsChanged: (v) => setState(() => _idecoGrowthYears = v),
          onRateChanged: (v) => setState(() => _idecoGrowthRate = v),
        ),
      ],
    );
  }

  Widget _buildGrowthSection({
    required int annualContribution,
    required double years,
    required double rate,
    required Color color,
    required ValueChanged<double> onYearsChanged,
    required ValueChanged<double> onRateChanged,
  }) {
    final amountFormat = NumberFormat('#,###');
    final points = CompoundGrowthSimulator.simulate(
      annualContribution: annualContribution,
      annualReturnRatePercent: rate,
      years: years.round(),
    );
    final finalPoint = points.isNotEmpty ? points.last : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('将来の資産成長シミュレーション（複利概算）',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              '上記の年間投資額を毎年積み立て続けたと仮定した概算です。実際の運用成績を保証するものではありません。',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text('積立年数: ${years.round()}年'),
            Slider(
              value: years,
              min: 1,
              max: 40,
              divisions: 39,
              label: '${years.round()}年',
              onChanged: onYearsChanged,
            ),
            Text('想定利回り: ${rate.toStringAsFixed(1)}%'),
            Slider(
              value: rate,
              min: 0,
              max: 10,
              divisions: 100,
              label: '${rate.toStringAsFixed(1)}%',
              onChanged: onRateChanged,
            ),
            if (finalPoint != null && annualContribution > 0) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: const FlTitlesData(
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: points
                            .map((p) => FlSpot(
                                p.year.toDouble(), p.cumulativePrincipal.toDouble()))
                            .toList(),
                        isCurved: false,
                        color: Colors.grey,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: points
                            .map((p) =>
                                FlSpot(p.year.toDouble(), p.estimatedValue.toDouble()))
                            .toList(),
                        isCurved: true,
                        color: color,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.15)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _legendDot('元本累計', Colors.grey),
                  _legendDot('評価額（概算）', color),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('元本累計', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('¥${amountFormat.format(finalPoint.cumulativePrincipal)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('評価額（概算）', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('¥${amountFormat.format(finalPoint.estimatedValue)}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                    ],
                  ),
                ],
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '年間投資額を入力すると、将来の資産成長の見込みが表示されます。',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
