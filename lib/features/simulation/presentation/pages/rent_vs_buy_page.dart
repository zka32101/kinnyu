import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/rent_vs_buy_calculator.dart';

class RentVsBuyPage extends StatefulWidget {
  const RentVsBuyPage({Key? key}) : super(key: key);

  @override
  State<RentVsBuyPage> createState() => _RentVsBuyPageState();
}

class _RentVsBuyPageState extends State<RentVsBuyPage> {
  final _rentController = TextEditingController(text: '100000');
  final _priceController = TextEditingController(text: '40000000');
  final _downPaymentController = TextEditingController(text: '4000000');
  final _propertyTaxController = TextEditingController(text: '100000');
  final _maintenanceController = TextEditingController(text: '150000');
  double _loanRate = 1.5;
  double _loanYears = 35;
  double _comparisonYears = 35;

  @override
  void dispose() {
    _rentController.dispose();
    _priceController.dispose();
    _downPaymentController.dispose();
    _propertyTaxController.dispose();
    _maintenanceController.dispose();
    super.dispose();
  }

  RentVsBuyResult get _result {
    return RentVsBuyCalculator.calculate(
      RentVsBuyInput(
        monthlyRent: int.tryParse(_rentController.text) ?? 0,
        purchasePrice: int.tryParse(_priceController.text) ?? 0,
        downPayment: int.tryParse(_downPaymentController.text) ?? 0,
        loanInterestRatePercent: _loanRate,
        loanYears: _loanYears.round(),
        annualPropertyTax: int.tryParse(_propertyTaxController.text) ?? 0,
        annualMaintenanceCost: int.tryParse(_maintenanceController.text) ?? 0,
        comparisonYears: _comparisonYears.round(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final amountFormat = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(title: const Text('住宅購入 vs 賃貸シミュレーション')),
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
              '概算の支払い総額を比較する簡易シミュレーションです。購入した場合に手元に残る'
              '不動産という資産の価値（値上がり・値下がり）は考慮していません。',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _rentController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '現在の家賃（月額）',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '物件価格',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _downPaymentController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '頭金',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _propertyTaxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '固定資産税等（年額）',
                    prefixText: '¥',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maintenanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '管理費・修繕費（年額）',
                    prefixText: '¥',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('住宅ローン金利: ${_loanRate.toStringAsFixed(2)}%',
              style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _loanRate,
            min: 0,
            max: 5,
            divisions: 50,
            label: '${_loanRate.toStringAsFixed(2)}%',
            onChanged: (v) => setState(() => _loanRate = v),
          ),
          Text('住宅ローン返済期間: ${_loanYears.round()}年',
              style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _loanYears,
            min: 5,
            max: 40,
            divisions: 35,
            label: '${_loanYears.round()}年',
            onChanged: (v) => setState(() => _loanYears = v),
          ),
          Text('比較する期間: ${_comparisonYears.round()}年',
              style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _comparisonYears,
            min: 5,
            max: 40,
            divisions: 35,
            label: '${_comparisonYears.round()}年',
            onChanged: (v) => setState(() => _comparisonYears = v),
          ),
          const SizedBox(height: 20),
          _buildSummaryCard(result, amountFormat),
          const SizedBox(height: 16),
          _buildYearlyTable(result, amountFormat),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(RentVsBuyResult result, NumberFormat amountFormat) {
    final buyIsCheaper = result.finalBuyCost <= result.finalRentCost;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: buyIsCheaper
              ? [Colors.green.shade300, Colors.green.shade700]
              : [Colors.orange.shade300, Colors.orange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            buyIsCheaper ? '購入の方が支払い総額を抑えられる見込みです' : '賃貸の方が支払い総額を抑えられる見込みです',
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statColumn('賃貸の総支払額', '¥${amountFormat.format(result.finalRentCost)}'),
              _statColumn('購入の総支払額', '¥${amountFormat.format(result.finalBuyCost)}'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.breakEvenYear != null
                ? '購入コストが賃貸を下回るのは約${result.breakEvenYear}年目からの見込みです。'
                : '比較期間内では、購入コストが賃貸を下回らない見込みです。',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (result.remainingLoanBalance > 0) ...[
            const SizedBox(height: 4),
            Text(
              '比較期間終了時点のローン残高: ¥${amountFormat.format(result.remainingLoanBalance)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
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

  Widget _buildYearlyTable(RentVsBuyResult result, NumberFormat amountFormat) {
    // 表が長くなりすぎないよう、5年ごと・最終年のみ表示する
    final displayed = result.years
        .where((y) => y.year % 5 == 0 || y.year == result.years.length)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('累計支払額の推移', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final y in displayed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${y.year}年目'),
                    Text(
                      '賃貸 ¥${amountFormat.format(y.cumulativeRentCost)} / '
                      '購入 ¥${amountFormat.format(y.cumulativeBuyCost)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
