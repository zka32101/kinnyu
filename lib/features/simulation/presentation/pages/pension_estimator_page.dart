import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/pension_estimator.dart';

class PensionEstimatorPage extends StatefulWidget {
  const PensionEstimatorPage({Key? key}) : super(key: key);

  @override
  State<PensionEstimatorPage> createState() => _PensionEstimatorPageState();
}

class _PensionEstimatorPageState extends State<PensionEstimatorPage> {
  final _incomeController = TextEditingController(text: '4500000');
  final _savingsController = TextEditingController(text: '0');
  double _currentAge = 35;
  double _retirementAge = 65;
  double _pensionEnrollmentYears = 38;
  double _yearsOfService = 20;
  CompanySize _companySize = CompanySize.medium;

  @override
  void dispose() {
    _incomeController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  PensionEstimatorResult get _result {
    return PensionEstimator.calculate(
      PensionEstimatorInput(
        currentAge: _currentAge.round(),
        retirementAge: _retirementAge.round(),
        averageAnnualIncome: int.tryParse(_incomeController.text) ?? 0,
        pensionEnrollmentYears: _pensionEnrollmentYears.round(),
        companySize: _companySize,
        yearsOfService: _yearsOfService.round(),
        currentRetirementSavings: int.tryParse(_savingsController.text) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final amountFormat = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(title: const Text('年金・退職金シミュレーション')),
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
              '公表されている年金制度の簡易乗率を用いた概算です。実際の受給額は'
              '納付実績・標準報酬月額の推移等により異なります。',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _incomeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '平均額面年収',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _savingsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '老後資金として既に準備している金額',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Text('現在の年齢: ${_currentAge.round()}歳',
              style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _currentAge,
            min: 18,
            max: 64,
            divisions: 46,
            label: '${_currentAge.round()}歳',
            onChanged: (v) => setState(() => _currentAge = v),
          ),
          Text('年金の受給開始年齢: ${_retirementAge.round()}歳',
              style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _retirementAge,
            min: 60,
            max: 75,
            divisions: 15,
            label: '${_retirementAge.round()}歳',
            onChanged: (v) => setState(() => _retirementAge = v),
          ),
          Text(
            _retirementAge < 65
                ? '65歳より前に受け取り始める「繰り上げ受給」（1ヶ月あたり0.4%減額）'
                : _retirementAge > 65
                    ? '65歳より後に受け取り始める「繰り下げ受給」（1ヶ月あたり0.7%増額）'
                    : '標準的な受給開始年齢です',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Text('厚生年金の加入見込み年数（通算）: ${_pensionEnrollmentYears.round()}年',
              style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _pensionEnrollmentYears,
            min: 0,
            max: 45,
            divisions: 45,
            label: '${_pensionEnrollmentYears.round()}年',
            onChanged: (v) => setState(() => _pensionEnrollmentYears = v),
          ),
          Text('勤続年数（退職金算定用）: ${_yearsOfService.round()}年',
              style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _yearsOfService,
            min: 0,
            max: 45,
            divisions: 45,
            label: '${_yearsOfService.round()}年',
            onChanged: (v) => setState(() => _yearsOfService = v),
          ),
          const SizedBox(height: 12),
          const Text('勤務先の規模', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: CompanySize.values.map((c) {
              final selected = c == _companySize;
              return ChoiceChip(
                label: Text(c.displayName),
                selected: selected,
                onSelected: (_) => setState(() => _companySize = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _buildPensionCard(result, amountFormat),
          const SizedBox(height: 16),
          _buildRetirementFundsCard(result, amountFormat),
        ],
      ),
    );
  }

  Widget _buildPensionCard(PensionEstimatorResult result, NumberFormat amountFormat) {
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
          const Text('年金受給見込み額（月額）',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            '¥${amountFormat.format(result.monthlyTotalPension)}',
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statColumn('老齢基礎年金（年額）', '¥${amountFormat.format(result.annualBasicPension)}'),
              _statColumn('老齢厚生年金（年額）', '¥${amountFormat.format(result.annualEmployeePension)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetirementFundsCard(
      PensionEstimatorResult result, NumberFormat amountFormat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('退職金・老後資金の概算', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _row('退職金の目安', '¥${amountFormat.format(result.estimatedRetirementLumpSum)}'),
            _row('退職金 + 既存の老後資金',
                '¥${amountFormat.format(result.totalRetirementFunds)}'),
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

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
