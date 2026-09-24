import 'package:flutter/material.dart';
import '../../domain/models/take_home_pay_calculator.dart';

class TakeHomePayPage extends StatefulWidget {
  /// 給与明細OCR等から額面年収の目安を事前入力する場合に渡す。
  final int? initialGrossAnnualIncome;

  const TakeHomePayPage({Key? key, this.initialGrossAnnualIncome}) : super(key: key);

  @override
  State<TakeHomePayPage> createState() => _TakeHomePayPageState();
}

class _TakeHomePayPageState extends State<TakeHomePayPage> {
  late final _incomeController = TextEditingController(
    text: '${widget.initialGrossAnnualIncome ?? 4000000}',
  );
  bool _isOver40 = false;
  int _dependents = 0;

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  TakeHomePayResult get _result {
    final gross = int.tryParse(_incomeController.text) ?? 0;
    return TakeHomePayCalculator.calculate(
      TakeHomePayInput(
        grossAnnualIncome: gross,
        isOver40: _isOver40,
        dependents: _dependents,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('手取り額シミュレーション')),
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
              '概算計算です。社会保険料率・税率は自治体や健康保険組合により異なります。'
              '正確な金額は給与明細や源泉徴収票でご確認ください。',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _incomeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '額面年収',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('40歳以上（介護保険料あり）'),
            value: _isOver40,
            onChanged: (v) => setState(() => _isOver40 = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('扶養親族の人数'),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _dependents > 0
                        ? () => setState(() => _dependents--)
                        : null,
                  ),
                  Text('$_dependents人', style: const TextStyle(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _dependents++),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(result),
          const SizedBox(height: 16),
          _buildBreakdownCard(result),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(TakeHomePayResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade300, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('手取り年収（概算）',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            '¥${result.takeHomeAnnual}',
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
              _statColumn('手取り月収目安', '¥${result.takeHomeMonthly}'),
              _statColumn(
                  '手取り率', '${(result.takeHomeRate * 100).toStringAsFixed(1)}%'),
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

  Widget _buildBreakdownCard(TakeHomePayResult result) {
    final rows = <(String, int)>[
      ('健康保険料', result.socialInsurance.healthInsurance),
      if (result.socialInsurance.longTermCareInsurance > 0)
        ('介護保険料', result.socialInsurance.longTermCareInsurance),
      ('厚生年金保険料', result.socialInsurance.pensionInsurance),
      ('雇用保険料', result.socialInsurance.employmentInsurance),
      ('所得税', result.incomeTax),
      ('住民税（概算）', result.residentTax),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('額面からの控除内訳', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.$1),
                      Text('¥${r.$2}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('控除合計', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '¥${result.totalDeductions}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
