import 'package:flutter/material.dart';
import '../../domain/models/insurance_coverage_calculator.dart';

class InsuranceCoveragePage extends StatefulWidget {
  const InsuranceCoveragePage({Key? key}) : super(key: key);

  @override
  State<InsuranceCoveragePage> createState() => _InsuranceCoveragePageState();
}

class _InsuranceCoveragePageState extends State<InsuranceCoveragePage> {
  final _expenseController = TextEditingController(text: '250000');
  final _oneTimeCostsController = TextEditingController(text: '2000000');
  final _savingsController = TextEditingController(text: '3000000');
  final _pensionController = TextEditingController(text: '100000');
  final _spouseIncomeController = TextEditingController(text: '150000');
  double _yearsNeeded = 20;

  @override
  void dispose() {
    _expenseController.dispose();
    _oneTimeCostsController.dispose();
    _savingsController.dispose();
    _pensionController.dispose();
    _spouseIncomeController.dispose();
    super.dispose();
  }

  InsuranceCoverageResult get _result {
    return InsuranceCoverageCalculator.calculate(
      InsuranceCoverageInput(
        monthlyLivingExpenseForFamily:
            int.tryParse(_expenseController.text) ?? 0,
        yearsNeeded: _yearsNeeded.round(),
        oneTimeCosts: int.tryParse(_oneTimeCostsController.text) ?? 0,
        currentSavings: int.tryParse(_savingsController.text) ?? 0,
        monthlySurvivorPension: int.tryParse(_pensionController.text) ?? 0,
        spouseMonthlyIncome: int.tryParse(_spouseIncomeController.text) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('必要保障額シミュレーション')),
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
              '万一の場合に遺族の生活を支えるために必要な生命保険の保障額を試算します（教育目的）。'
              '実際の加入検討は専門家（保険会社・FP）にご相談ください。',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _expenseController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '遺族の毎月の生活費',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text('保障が必要な期間: ${_yearsNeeded.round()}年（末子独立までの年数など）',
              style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _yearsNeeded,
            min: 1,
            max: 30,
            divisions: 29,
            label: '${_yearsNeeded.round()}年',
            onChanged: (v) => setState(() => _yearsNeeded = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _oneTimeCostsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '葬儀費用など一時的な費用',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _savingsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '現在の金融資産（貯蓄・投資等）',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pensionController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '遺族年金等の見込み月額',
              prefixText: '¥',
              border: OutlineInputBorder(),
              helperText: '日本年金機構の見込額試算等でご確認ください',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _spouseIncomeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '配偶者の収入見込み月額',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          _buildSummaryCard(result),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(InsuranceCoverageResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade300, Colors.indigo.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('必要保障額（目安）',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            '¥${result.requiredCoverage}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statColumn('必要な生活費等の総額', '¥${result.totalLivingExpenseNeeded}'),
              _statColumn('収入・資産の見込み総額', '¥${result.totalIncomeExpected}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
