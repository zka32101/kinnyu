import 'package:flutter/material.dart';
import '../../domain/models/furusato_nozei_calculator.dart';

class FurusatoNozeiPage extends StatefulWidget {
  const FurusatoNozeiPage({Key? key}) : super(key: key);

  @override
  State<FurusatoNozeiPage> createState() => _FurusatoNozeiPageState();
}

class _FurusatoNozeiPageState extends State<FurusatoNozeiPage> {
  final _incomeController = TextEditingController(text: '4000000');
  bool _isOver40 = false;
  int _dependents = 0;

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  FurusatoNozeiResult get _result {
    final gross = int.tryParse(_incomeController.text) ?? 0;
    return FurusatoNozeiCalculator.calculate(
      FurusatoNozeiInput(
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
      appBar: AppBar(title: const Text('ふるさと納税 控除上限額')),
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
              '概算計算です。医療費控除など他の控除がある場合は上限額が変わります。'
              '正確な金額はふるさと納税ポータルサイトの詳細シミュレーターでご確認ください。',
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
          const SizedBox(height: 20),
          _buildSummaryCard(result),
          const SizedBox(height: 16),
          _buildDetailCard(result),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(FurusatoNozeiResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade300, Colors.red.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('控除上限額（実質2,000円になる目安）',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            '¥${result.donationLimit}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'この金額までふるさと納税を行うと、自己負担が実質2,000円に収まる見込みです。',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(FurusatoNozeiResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('計算の内訳', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _row('住民税所得割額（概算）', '¥${result.residentTaxIncomeLevy}'),
            _row('所得税の限界税率',
                '${(result.marginalIncomeTaxRate * 100).toStringAsFixed(0)}%'),
          ],
        ),
      ),
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
