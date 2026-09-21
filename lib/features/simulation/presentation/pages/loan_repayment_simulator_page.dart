import 'package:flutter/material.dart';
import '../../domain/models/loan_repayment_simulator.dart';

class LoanRepaymentSimulatorPage extends StatefulWidget {
  const LoanRepaymentSimulatorPage({Key? key}) : super(key: key);

  @override
  State<LoanRepaymentSimulatorPage> createState() =>
      _LoanRepaymentSimulatorPageState();
}

class _LoanRepaymentSimulatorPageState
    extends State<LoanRepaymentSimulatorPage> {
  final _principalController = TextEditingController(text: '30000000');
  double _rate = 1.5;
  double _years = 35;
  RepaymentType _repaymentType = RepaymentType.equalPayment;

  @override
  void dispose() {
    _principalController.dispose();
    super.dispose();
  }

  LoanRepaymentResult get _result {
    final principal = int.tryParse(_principalController.text) ?? 0;
    return LoanRepaymentSimulator.simulate(
      LoanRepaymentInput(
        principal: principal,
        annualInterestRatePercent: _rate,
        years: _years.round(),
        repaymentType: _repaymentType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('借入返済シミュレーション')),
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
              '住宅ローン・自動車ローン・奨学金などの返済計画を試算できます（教育目的）。',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _principalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '借入元金',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Text('年利: ${_rate.toStringAsFixed(2)}%',
              style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _rate,
            min: 0,
            max: 10,
            divisions: 100,
            label: '${_rate.toStringAsFixed(2)}%',
            onChanged: (v) => setState(() => _rate = v),
          ),
          const SizedBox(height: 12),
          Text('返済期間: ${_years.round()}年',
              style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _years,
            min: 1,
            max: 40,
            divisions: 39,
            label: '${_years.round()}年',
            onChanged: (v) => setState(() => _years = v),
          ),
          const SizedBox(height: 16),
          SegmentedButton<RepaymentType>(
            segments: const [
              ButtonSegment(
                value: RepaymentType.equalPayment,
                label: Text('元利均等'),
                icon: Icon(Icons.horizontal_rule),
              ),
              ButtonSegment(
                value: RepaymentType.equalPrincipal,
                label: Text('元金均等'),
                icon: Icon(Icons.trending_down),
              ),
            ],
            selected: {_repaymentType},
            onSelectionChanged: (s) => setState(() => _repaymentType = s.first),
          ),
          const SizedBox(height: 4),
          Text(
            _repaymentType == RepaymentType.equalPayment
                ? '毎月の返済額（元金+利息）が一定になる、最も一般的な方式です。'
                : '毎月の元金部分が一定で、返済額は徐々に減っていく方式です（総利息は少なくなります）。',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _buildSummaryCard(result),
          const SizedBox(height: 16),
          if (result.years.length > 1) _buildYearlyTable(result),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(LoanRepaymentResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepOrange.shade300, Colors.deepOrange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _repaymentType == RepaymentType.equalPayment ? '毎月の返済額' : '初回の返済額',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            '¥${result.firstMonthPayment}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_repaymentType == RepaymentType.equalPrincipal) ...[
            const SizedBox(height: 4),
            Text(
              '最終回: ¥${result.lastMonthPayment}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statColumn('返済総額', '¥${result.totalPayment}'),
              _statColumn('うち利息総額', '¥${result.totalInterest}'),
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

  Widget _buildYearlyTable(LoanRepaymentResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('年ごとの返済残高の推移', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...result.years.map((y) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${y.year}年目'),
                      Text('残高 ¥${y.remainingBalance}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
