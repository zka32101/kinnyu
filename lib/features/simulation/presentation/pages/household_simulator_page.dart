import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/models/household_simulator.dart';
import '../../domain/services/excel_exporter.dart';
import '../../../../core/subscription/subscription_provider.dart';
import '../../../premium/presentation/pages/paywall_page.dart';

enum _Mode { simple, detailed }

class HouseholdSimulatorPage extends ConsumerStatefulWidget {
  const HouseholdSimulatorPage({Key? key}) : super(key: key);

  @override
  ConsumerState<HouseholdSimulatorPage> createState() =>
      _HouseholdSimulatorPageState();
}

class _HouseholdSimulatorPageState
    extends ConsumerState<HouseholdSimulatorPage> {
  _Mode _mode = _Mode.simple;

  // 簡易モード用
  final _incomeController = TextEditingController(text: '300000');
  final _expenseController = TextEditingController(text: '220000');

  // 共通
  double _returnRate = 0; // 0 = 貯金のみ
  double _years = 10;

  // 詳細モード用：年度ごとの入力コントローラー
  final List<TextEditingController> _yearIncomeControllers = [];
  final List<TextEditingController> _yearExpenseControllers = [];

  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _syncDetailedControllers();
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _expenseController.dispose();
    for (final c in _yearIncomeControllers) {
      c.dispose();
    }
    for (final c in _yearExpenseControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncDetailedControllers() {
    final targetCount = _years.round();

    while (_yearIncomeControllers.length < targetCount) {
      final baseIncome = _yearIncomeControllers.isEmpty
          ? (int.tryParse(_incomeController.text) ?? 300000)
          : (int.tryParse(_yearIncomeControllers.last.text) ?? 300000);
      final baseExpense = _yearExpenseControllers.isEmpty
          ? (int.tryParse(_expenseController.text) ?? 220000)
          : (int.tryParse(_yearExpenseControllers.last.text) ?? 220000);
      _yearIncomeControllers.add(TextEditingController(text: '$baseIncome'));
      _yearExpenseControllers.add(TextEditingController(text: '$baseExpense'));
    }
    while (_yearIncomeControllers.length > targetCount) {
      _yearIncomeControllers.removeLast().dispose();
      _yearExpenseControllers.removeLast().dispose();
    }
  }

  // --- 簡易モードの計算 ---
  HouseholdSimulationResult get _simpleResult {
    final income = int.tryParse(_incomeController.text) ?? 0;
    final expense = int.tryParse(_expenseController.text) ?? 0;
    return HouseholdSimulator.simulate(
      HouseholdSimulationInput(
        monthlyIncome: income,
        monthlyExpense: expense,
        investmentReturnPercent: _returnRate,
        years: _years.round(),
      ),
    );
  }

  // --- 詳細モードの計算 ---
  List<YearlyPlan> get _detailedPlans {
    return List.generate(_yearIncomeControllers.length, (i) {
      return YearlyPlan(
        year: i + 1,
        monthlyIncome: int.tryParse(_yearIncomeControllers[i].text) ?? 0,
        monthlyExpense: int.tryParse(_yearExpenseControllers[i].text) ?? 0,
      );
    });
  }

  List<DetailedYearResult> get _detailedResults {
    if (_detailedPlans.isEmpty) return [];
    return HouseholdSimulator.simulateDetailed(
      plans: _detailedPlans,
      investmentReturnPercent: _returnRate,
    );
  }

  Future<void> _exportToExcel() async {
    if (!ref.read(isPremiumProvider)) {
      final unlocked = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const PaywallPage()),
      );
      if (unlocked != true) return;
    }

    setState(() => _isExporting = true);
    try {
      List<DetailedYearResult> results;
      if (_mode == _Mode.simple) {
        final income = int.tryParse(_incomeController.text) ?? 0;
        final expense = int.tryParse(_expenseController.text) ?? 0;
        final plans = HouseholdSimulator.expandToYearlyPlans(
          HouseholdSimulationInput(
            monthlyIncome: income,
            monthlyExpense: expense,
            years: _years.round(),
          ),
        );
        results = HouseholdSimulator.simulateDetailed(
          plans: plans,
          investmentReturnPercent: _returnRate,
        );
      } else {
        results = _detailedResults;
      }

      final file = await HouseholdExcelExporter.export(results);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'お金コレ！ 家計シミュレーション結果',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel出力に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('家計シミュレーション'),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.ios_share),
                      if (!isPremium)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Icon(Icons.lock,
                              size: 12, color: Colors.amber.shade700),
                        ),
                    ],
                  ),
            tooltip: 'Excelに出力（プレミアム）',
            onPressed: _isExporting ? null : _exportToExcel,
          ),
        ],
      ),
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
              '教育目的のシミュレーションです。実際の家計改善は専門家にご相談ください。',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<_Mode>(
            segments: const [
              ButtonSegment(
                  value: _Mode.simple, label: Text('簡易'), icon: Icon(Icons.flash_on)),
              ButtonSegment(
                  value: _Mode.detailed,
                  label: Text('詳細（年度別）'),
                  icon: Icon(Icons.table_chart)),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 16),
          if (_mode == _Mode.simple) ..._buildSimpleMode() else ..._buildDetailedMode(),
        ],
      ),
    );
  }

  // ============ 簡易モード ============
  List<Widget> _buildSimpleMode() {
    final result = _simpleResult;
    final last = result.projection.isNotEmpty ? result.projection.last : null;

    return [
      TextField(
        controller: _incomeController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: '毎月の手取り収入',
          prefixText: '¥',
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _expenseController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: '毎月の支出合計',
          prefixText: '¥',
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 20),
      ..._buildSharedControls(),
      const SizedBox(height: 16),
      _buildSummaryCard(
        isDeficit: result.isDeficit,
        monthlySavings: result.monthlySavings,
        savingsRate: result.savingsRate,
      ),
      if (last != null && !result.isDeficit) ...[
        const SizedBox(height: 16),
        _buildProjectionCard(
          principal: last.principal,
          balance: last.balance,
          profit: last.profit,
        ),
      ],
    ];
  }

  // ============ 詳細モード ============
  List<Widget> _buildDetailedMode() {
    final results = _detailedResults;
    final last = results.isNotEmpty ? results.last : null;
    final anyDeficit = results.any((r) => r.isDeficit);

    return [
      ..._buildSharedControls(),
      const SizedBox(height: 16),
      const Text('年度ごとの収入・支出', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...List.generate(_yearIncomeControllers.length, (i) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${i + 1}年目', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _yearIncomeControllers[i],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '月収',
                          prefixText: '¥',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _yearExpenseControllers[i],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '支出',
                          prefixText: '¥',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
      const SizedBox(height: 8),
      if (anyDeficit)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '赤字の年があります。その年は積立額0として計算されます。',
            style: TextStyle(fontSize: 12, color: Colors.red),
          ),
        ),
      const SizedBox(height: 16),
      if (last != null)
        _buildProjectionCard(
          principal: last.principal,
          balance: last.balance,
          profit: last.profit,
        ),
      if (results.length > 1) ...[
        const SizedBox(height: 16),
        _buildYearlyResultTable(results),
      ],
    ];
  }

  List<Widget> _buildSharedControls() {
    return [
      Text('貯蓄の運用利回り: ${_returnRate.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.titleMedium),
      Slider(
        value: _returnRate,
        min: 0,
        max: 7,
        divisions: 14,
        label: '${_returnRate.toStringAsFixed(1)}%',
        onChanged: (v) => setState(() => _returnRate = v),
      ),
      const Text(
        '0%は「貯金のみ」を意味します。投資に回す場合の利回りを想定して調整できます。',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      const SizedBox(height: 16),
      Text('シミュレーション期間: ${_years.round()}年',
          style: Theme.of(context).textTheme.titleMedium),
      Slider(
        value: _years,
        min: 1,
        max: 30,
        divisions: 29,
        label: '${_years.round()}年',
        onChanged: (v) => setState(() {
          _years = v;
          _syncDetailedControllers();
        }),
      ),
    ];
  }

  Widget _buildYearlyResultTable(List<DetailedYearResult> results) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('年ごとの推移', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...results.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${r.year}年目${r.isDeficit ? "（赤字）" : ""}'),
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

  Widget _buildSummaryCard({
    required bool isDeficit,
    required int monthlySavings,
    required double savingsRate,
  }) {
    final color = isDeficit ? Colors.red : Colors.indigo;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        border: Border.all(color: color.withAlpha(100)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDeficit ? '毎月の赤字額' : '毎月の貯蓄額',
            style: TextStyle(color: color, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            '¥${monthlySavings.abs()}',
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (isDeficit)
            const Text(
              '支出が収入を上回っています。固定費の見直しから始めましょう。',
              style: TextStyle(fontSize: 13, color: Colors.red),
            )
          else
            Text(
              '貯蓄率: ${(savingsRate * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectionCard({
    required int principal,
    required double balance,
    required double profit,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade300, Colors.indigo.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_years.round()}年後の資産見込み',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            '¥${balance.round()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statColumn('積立元本', '¥$principal'),
              _statColumn('運用益', '¥${profit.round()}'),
            ],
          ),
        ],
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
