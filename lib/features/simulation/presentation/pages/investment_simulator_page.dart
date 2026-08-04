import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/compound_simulator.dart';
import '../../domain/models/investment_simulation_pattern.dart';
import '../../../investment/domain/models/investment.dart';
import '../../../../core/subscription/subscription_provider.dart';
import '../../../premium/presentation/pages/paywall_page.dart';

enum _SimMode { ideal, real }

/// パターン選択のうち、無料で試せる件数（1件目のみ無料、残りはプレミアム限定）
const int freePatternCount = 1;

class InvestmentSimulatorPage extends ConsumerStatefulWidget {
  const InvestmentSimulatorPage({Key? key}) : super(key: key);

  @override
  ConsumerState<InvestmentSimulatorPage> createState() =>
      _InvestmentSimulatorPageState();
}

class _InvestmentSimulatorPageState
    extends ConsumerState<InvestmentSimulatorPage> {
  final _amountController = TextEditingController(text: '10000');
  double _years = 20;
  InvestmentType _type = InvestmentType.allCountry;
  _SimMode _mode = _SimMode.ideal;
  String? _selectedPatternId;
  int _randomSeed = 1;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _applyPattern(InvestmentSimulationPattern p) {
    setState(() {
      _amountController.text = '${p.monthlyAmount}';
      _type = p.investmentType;
      _years = p.years.toDouble();
      _selectedPatternId = p.id;
    });
  }

  Future<void> _onPatternTap(InvestmentSimulationPattern p, bool isLocked) async {
    if (!isLocked) {
      _applyPattern(p);
      return;
    }
    final unlocked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PaywallPage()),
    );
    if (unlocked == true) {
      _applyPattern(p);
    }
  }

  // --- 理論値モード（一定成長） ---
  List<CompoundYearResult> get _idealResults {
    final amount = int.tryParse(_amountController.text) ?? 0;
    final rate = (InvestmentTypeInfo.annualGrowthRate[_type] ?? 0.05) * 100;
    return CompoundSimulator.simulate(
      monthlyContribution: amount,
      annualRatePercent: rate,
      years: _years.round(),
    );
  }

  // --- リアル変動モード（好況・不況の波あり） ---
  List<RandomYearResult> get _realResults {
    final amount = int.tryParse(_amountController.text) ?? 0;
    final rate = (InvestmentTypeInfo.annualGrowthRate[_type] ?? 0.05) * 100;
    final volatility = InvestmentTypeInfo.volatilityPercent[_type] ?? 15;
    return CompoundSimulator.simulateRandom(
      monthlyContribution: amount,
      meanAnnualRatePercent: rate,
      volatilityPercent: volatility,
      years: _years.round(),
      seed: _randomSeed,
    );
  }

  void _reroll() {
    setState(() => _randomSeed = DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Widget build(BuildContext context) {
    final rate = (InvestmentTypeInfo.annualGrowthRate[_type] ?? 0.05) * 100;

    return Scaffold(
      appBar: AppBar(title: const Text('積立投資シミュレーション')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '教育目的のシミュレーションです。実際の運用成績を保証するものではありません。',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
          ),
          const SizedBox(height: 16),
          _buildPatternSelector(),
          const SizedBox(height: 20),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '毎月の積立額',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() => _selectedPatternId = null),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<InvestmentType>(
            value: _type,
            decoration: const InputDecoration(
              labelText: '投資先',
              border: OutlineInputBorder(),
            ),
            items: InvestmentType.values.map((t) {
              return DropdownMenuItem(
                value: t,
                child: Text(InvestmentTypeInfo.displayNames[t]!),
              );
            }).toList(),
            onChanged: (v) => setState(() {
              _type = v!;
              _selectedPatternId = null;
            }),
          ),
          const SizedBox(height: 4),
          Text(
            '${InvestmentTypeInfo.descriptions[_type] ?? ''}（想定年利 ${rate.toStringAsFixed(1)}%）',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Text('積立期間: ${_years.round()}年',
              style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _years,
            min: 1,
            max: 40,
            divisions: 39,
            label: '${_years.round()}年',
            onChanged: (v) => setState(() {
              _years = v;
              _selectedPatternId = null;
            }),
          ),
          const SizedBox(height: 16),
          SegmentedButton<_SimMode>(
            segments: const [
              ButtonSegment(
                  value: _SimMode.ideal,
                  label: Text('理論値'),
                  icon: Icon(Icons.show_chart)),
              ButtonSegment(
                  value: _SimMode.real,
                  label: Text('リアル変動'),
                  icon: Icon(Icons.ssid_chart)),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 8),
          if (_mode == _SimMode.real)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '毎年の利回りをランダムに変動させ、好況・不況の波がある現実に近い値動きを再現します。',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
                TextButton.icon(
                  onPressed: _reroll,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('再抽選'),
                ),
              ],
            ),
          const SizedBox(height: 16),
          if (_mode == _SimMode.ideal)
            ..._buildIdealSection()
          else
            ..._buildRealSection(),
        ],
      ),
    );
  }

  Widget _buildPatternSelector() {
    final isPremium = ref.watch(isPremiumProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('パターンから選ぶ', style: TextStyle(fontWeight: FontWeight.bold)),
            if (!isPremium) ...[
              const SizedBox(width: 8),
              Icon(Icons.workspace_premium, size: 16, color: Colors.amber.shade700),
              const SizedBox(width: 2),
              Text('1件無料・残りはプレミアム',
                  style: TextStyle(fontSize: 11, color: Colors.amber.shade800)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: InvestmentSimulationPatterns.patterns.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final p = InvestmentSimulationPatterns.patterns[index];
              final selected = _selectedPatternId == p.id;
              final isLocked = !isPremium && index >= freePatternCount;
              return GestureDetector(
                onTap: () => _onPatternTap(p, isLocked),
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected ? Colors.teal.shade50 : Colors.grey.shade100,
                    border: Border.all(
                      color: selected ? Colors.teal : Colors.grey.shade300,
                      width: selected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(p.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          if (isLocked)
                            Icon(Icons.lock,
                                size: 14, color: Colors.amber.shade800),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          p.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============ 理論値モード ============
  List<Widget> _buildIdealSection() {
    final results = _idealResults;
    final last = results.isNotEmpty ? results.last : null;
    return [
      if (last != null) _buildIdealResultCard(last),
      const SizedBox(height: 16),
      if (results.length > 1) _buildIdealYearlyList(results),
    ];
  }

  Widget _buildIdealResultCard(CompoundYearResult last) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade300, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('シミュレーション結果（理論値）',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            '¥${last.balance.round()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statColumn('積立元本', '¥${last.principal}'),
              _statColumn('運用益', '¥${last.profit.round()}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdealYearlyList(List<CompoundYearResult> results) {
    final milestones = results
        .where((r) => r.year % 5 == 0 || r.year == results.length)
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('年ごとの推移', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...milestones.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${r.year}年目'),
                      Text('¥${r.balance.round()}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ============ リアル変動モード ============
  List<Widget> _buildRealSection() {
    final results = _realResults;
    final last = results.isNotEmpty ? results.last : null;
    return [
      if (last != null) _buildRealResultCard(last),
      const SizedBox(height: 16),
      if (results.isNotEmpty) _buildRealYearlyList(results),
    ];
  }

  Widget _buildRealResultCard(RandomYearResult last) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('シミュレーション結果（リアル変動・1パターン）',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            '¥${last.balance.round()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statColumn('積立元本', '¥${last.principal}'),
              _statColumn('運用益', '¥${last.profit.round()}'),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '※ 相場は毎回変わります。「再抽選」で別の値動きパターンも試してみましょう。',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildRealYearlyList(List<RandomYearResult> results) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('年ごとの利回りと評価額', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...results.map((r) {
              final isUp = r.annualReturnPercent >= 0;
              final color = isUp ? Colors.green.shade700 : Colors.red.shade700;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${r.year}年目'),
                    Row(
                      children: [
                        Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 14, color: color),
                        Text(
                          '${r.annualReturnPercent.toStringAsFixed(1)}%',
                          style: TextStyle(color: color, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        Text('¥${r.balance.round()}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
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
