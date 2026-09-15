import 'package:flutter/material.dart';
import '../../../domain/models/spending_evaluation.dart';

/// 支出レコメンデーションセクション
class SpendingRecommendationsSection extends StatelessWidget {
  final SpendingEvaluation evaluation;

  const SpendingRecommendationsSection({
    Key? key,
    required this.evaluation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            const Text(
              '💡 レコメンデーション',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),

            // 全体アセスメント
            _AssessmentBox(
              assessment: evaluation.overallAssessment,
            ),
            const SizedBox(height: 16),

            // レコメンデーションリスト
            if (evaluation.actionableRecommendations.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    '✅ 支出が良好に管理されています',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: evaluation.actionableRecommendations
                    .asMap()
                    .entries
                    .map(
                      (entry) => _RecommendationItem(
                        index: entry.key + 1,
                        recommendation: entry.value,
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 16),

            // アクションボタン
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: 予算設定画面へ遷移
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('予算を編集'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: 詳細分析画面へ遷移
                    },
                    icon: const Icon(Icons.analytics),
                    label: const Text('詳細分析'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// アセスメントボックス
class _AssessmentBox extends StatelessWidget {
  final String assessment;

  const _AssessmentBox({
    required this.assessment,
  });

  @override
  Widget build(BuildContext context) {
    // アセスメントテキストから肯定的か否定的かを判定
    final isPositive = assessment.contains('良好') ||
        assessment.contains('優秀') ||
        assessment.contains('管理');
    final color = isPositive ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.check_circle : Icons.warning,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              assessment,
              style: TextStyle(
                fontSize: 12,
                color: color,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// レコメンデーション項目
class _RecommendationItem extends StatelessWidget {
  final int index;
  final String recommendation;

  const _RecommendationItem({
    required this.index,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      // TODO: アクション実行
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    child: const Text(
                      '対応する',
                      style: TextStyle(fontSize: 12),
                    ),
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
