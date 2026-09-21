import 'package:flutter/material.dart';
import '../../domain/models/emergency_fund_planner.dart';

class EmergencyFundPage extends StatefulWidget {
  const EmergencyFundPage({Key? key}) : super(key: key);

  @override
  State<EmergencyFundPage> createState() => _EmergencyFundPageState();
}

class _EmergencyFundPageState extends State<EmergencyFundPage> {
  final _expenseController = TextEditingController(text: '200000');
  final _savingsController = TextEditingController(text: '300000');
  final _contributionController = TextEditingController(text: '20000');
  double _coverageMonths = 6;

  @override
  void dispose() {
    _expenseController.dispose();
    _savingsController.dispose();
    _contributionController.dispose();
    super.dispose();
  }

  EmergencyFundResult get _result {
    return EmergencyFundPlanner.calculate(
      EmergencyFundInput(
        monthlyEssentialExpense: int.tryParse(_expenseController.text) ?? 0,
        coverageMonths: _coverageMonths.round(),
        currentSavings: int.tryParse(_savingsController.text) ?? 0,
        monthlyContribution: int.tryParse(_contributionController.text) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('生活防衛資金プランナー')),
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
              '失業や病気などで収入が途絶えた場合に備える資金です。'
              '会社員は3〜6ヶ月分、自営業は6〜12ヶ月分が目安とされます。',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _expenseController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '毎月の生活必需支出',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text('目標カバー月数: ${_coverageMonths.round()}ヶ月分',
              style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _coverageMonths,
            min: 3,
            max: 12,
            divisions: 9,
            label: '${_coverageMonths.round()}ヶ月',
            onChanged: (v) => setState(() => _coverageMonths = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _savingsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '現在の生活防衛資金の貯蓄額',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contributionController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '毎月積み立てられる額',
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

  Widget _buildSummaryCard(EmergencyFundResult result) {
    final color = result.isGoalReached ? Colors.green : Colors.indigo;
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
          Text('目標金額', style: TextStyle(color: color, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            '¥${result.targetAmount}',
            style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: result.progressPercent / 100,
              minHeight: 10,
              backgroundColor: color.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text('達成率: ${result.progressPercent.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          if (result.isGoalReached)
            const Text(
              '🎉 目標金額に到達しています！このまま維持しましょう。',
              style: TextStyle(fontSize: 13, color: Colors.green),
            )
          else ...[
            Text('不足額: ¥${result.remainingAmount}', style: const TextStyle(fontSize: 13)),
            if (result.monthsToGoal != null)
              Text(
                'このペースで積み立てると、約${result.monthsToGoal}ヶ月で目標達成の見込みです。',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              )
            else
              const Text(
                '毎月の積立額を入力すると、達成までの期間が分かります。',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
          ],
        ],
      ),
    );
  }
}
