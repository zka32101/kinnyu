import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/life_plan_timeline.dart';

/// 教育費・退職・年金など、既存の各シミュレーターの結果を年齢軸で1つに
/// つなげて表示するライフプランタイムライン。
class LifePlanTimelinePage extends StatefulWidget {
  const LifePlanTimelinePage({Key? key}) : super(key: key);

  @override
  State<LifePlanTimelinePage> createState() => _LifePlanTimelinePageState();
}

class _LifePlanTimelinePageState extends State<LifePlanTimelinePage> {
  final _incomeController = TextEditingController(text: '4500000');
  double _currentAge = 35;
  double _retirementAge = 65;
  bool _hasChild = false;
  double _childAge = 0;

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  List<LifePlanEvent> get _events {
    return LifePlanTimelineBuilder.build(
      LifePlanTimelineInput(
        currentAge: _currentAge.round(),
        childCurrentAge: _hasChild ? _childAge.round() : null,
        retirementAge: _retirementAge.round(),
        averageAnnualIncome: int.tryParse(_incomeController.text) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = _events;

    return Scaffold(
      appBar: AppBar(title: const Text('ライフプランタイムライン')),
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
              '教育費プランナー・年金シミュレーターの試算結果を年齢順につなげた概算です。'
              '詳細な条件を変えたい場合は、各シミュレーターページで個別に調整してください。',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
          ),
          const SizedBox(height: 16),
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
          Text('退職予定年齢: ${_retirementAge.round()}歳',
              style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _retirementAge,
            min: 55,
            max: 75,
            divisions: 20,
            label: '${_retirementAge.round()}歳',
            onChanged: (v) => setState(() => _retirementAge = v),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('子どもの教育費を含める'),
            value: _hasChild,
            onChanged: (v) => setState(() => _hasChild = v),
          ),
          if (_hasChild) ...[
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
          ],
          const SizedBox(height: 20),
          const Text('タイムライン', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          for (final event in events) _buildEventTile(event),
        ],
      ),
    );
  }

  Widget _buildEventTile(LifePlanEvent event) {
    final amountFormat = NumberFormat('#,###');
    final color = event.isIncome ? Colors.green : Colors.deepOrange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Text('${event.age}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
                ),
                const Expanded(child: VerticalDivider(width: 1)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(event.emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(event.title,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Text(
                            '${event.isIncome ? '+' : '-'}¥${amountFormat.format(event.amount)}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: color),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(event.description,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
