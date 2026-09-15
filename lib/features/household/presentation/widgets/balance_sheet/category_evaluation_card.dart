import 'package:flutter/material.dart';
import '../../../domain/models/spending_evaluation.dart';

/// カテゴリ別評価カード
class CategoryEvaluationCard extends StatelessWidget {
  final CategoryEvaluation evaluation;

  const CategoryEvaluationCard({
    Key? key,
    required this.evaluation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor(evaluation.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    evaluation.category,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.2),
                    border: Border.all(
                      color: severityColor.withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getSeverityLabel(evaluation.severity),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 予算と実績
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '予算',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      '¥${evaluation.budgetAmount}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '実績',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      '¥${evaluation.actualSpent}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: evaluation.utilization > 100
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '差額',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      '¥${evaluation.difference}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: evaluation.difference < 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 利用率プログレスバー
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '利用率',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '${evaluation.utilization.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: severityColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: (evaluation.utilization / 150).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(severityColor),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // レコメンデーション
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.1),
                border: Border.all(
                  color: severityColor.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                evaluation.recommendation,
                style: TextStyle(
                  fontSize: 12,
                  color: severityColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(EvaluationSeverity severity) {
    switch (severity) {
      case EvaluationSeverity.excellent:
        return Colors.green;
      case EvaluationSeverity.good:
        return Colors.blue;
      case EvaluationSeverity.caution:
        return Colors.orange;
      case EvaluationSeverity.warning:
        return Colors.deepOrange;
      case EvaluationSeverity.critical:
        return Colors.red;
    }
  }

  String _getSeverityLabel(EvaluationSeverity severity) {
    switch (severity) {
      case EvaluationSeverity.excellent:
        return '優秀';
      case EvaluationSeverity.good:
        return '良好';
      case EvaluationSeverity.caution:
        return '注意';
      case EvaluationSeverity.warning:
        return '警告';
      case EvaluationSeverity.critical:
        return '重大';
    }
  }
}
