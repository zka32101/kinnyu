import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/education_cost_planner.dart';

class EducationCostPage extends StatefulWidget {
  const EducationCostPage({Key? key}) : super(key: key);

  @override
  State<EducationCostPage> createState() => _EducationCostPageState();
}

class _EducationCostPageState extends State<EducationCostPage> {
  final _savingsController = TextEditingController(text: '0');
  double _childAge = 0;
  final Map<EducationStage, SchoolTrack> _tracks = {
    for (final stage in EducationStage.values) stage: SchoolTrack.public,
  };

  @override
  void dispose() {
    _savingsController.dispose();
    super.dispose();
  }

  EducationCostResult get _result {
    return EducationCostPlanner.calculate(
      EducationCostInput(
        childCurrentAge: _childAge.round(),
        tracks: _tracks,
        currentSavings: int.tryParse(_savingsController.text) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final amountFormat = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(title: const Text('教育費プランナー')),
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
              '文部科学省等の公表統計を参考にした概算値です。通学形態や学部により'
              '実際の金額は変動するため、あくまで目安としてご利用ください。',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
          ),
          const SizedBox(height: 16),
          Text('お子さまの現在の年齢: ${_childAge.round()}歳',
              style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _childAge,
            min: 0,
            max: 18,
            divisions: 18,
            label: '${_childAge.round()}歳',
            onChanged: (v) => setState(() => _childAge = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _savingsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '教育費として既に準備している金額',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          const Text('進路の選択', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          for (final stage in EducationStage.values) _buildStageSelector(stage),
          const SizedBox(height: 20),
          _buildSummaryCard(result, amountFormat),
          const SizedBox(height: 16),
          _buildStageBreakdown(result, amountFormat),
        ],
      ),
    );
  }

  Widget _buildStageSelector(EducationStage stage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 72, child: Text(stage.displayName)),
          const SizedBox(width: 8),
          Expanded(
            child: SegmentedButton<SchoolTrack>(
              segments: const [
                ButtonSegment(value: SchoolTrack.public, label: Text('公立')),
                ButtonSegment(value: SchoolTrack.private, label: Text('私立')),
              ],
              selected: {_tracks[stage]!},
              onSelectionChanged: (s) => setState(() => _tracks[stage] = s.first),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(EducationCostResult result, NumberFormat amountFormat) {
    return Container(
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
          const Text('教育費の総額（幼稚園〜大学）',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            '¥${amountFormat.format(result.totalCost)}',
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (result.yearsUntilUniversity > 0) ...[
            Text(
              '大学入学（あと約${result.yearsUntilUniversity}年）までに、'
              '残り¥${amountFormat.format(result.remainingCost)}の準備が必要です。',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              '毎月の積立目安: ¥${amountFormat.format(result.requiredMonthlySavings)}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ] else ...[
            Text(
              '既に大学入学の年齢に達しています。残りの教育費目安: '
              '¥${amountFormat.format(result.remainingCost)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStageBreakdown(EducationCostResult result, NumberFormat amountFormat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('段階別の内訳', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final stageCost in result.stageCosts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${stageCost.stage.displayName}（${stageCost.track.displayName}）'
                      '${stageCost.yearsUntilStart > 0 ? " ・あと${stageCost.yearsUntilStart}年" : ""}',
                    ),
                    Text('¥${amountFormat.format(stageCost.totalCost)}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
