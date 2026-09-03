import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/first_month_guide.dart';
import '../providers/tutorial_provider.dart';

/// 最初の1ヶ月ガイドのカード
class FirstMonthGuideCard extends ConsumerWidget {
  final FirstMonthGuideStep step;
  final int stepNumber;
  final VoidCallback? onTap;

  const FirstMonthGuideCard({
    Key? key,
    required this.step,
    required this.stepNumber,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCompleted = step.isCompleted;
    final tutorialWatched = ref.watch(tutorialWatchedProvider(step.type));
    final hasTutorial = step.tutorialVideoUrl != null;

    return Card(
      elevation: isCompleted ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCompleted
            ? BorderSide(color: Colors.green.withOpacity(0.3), width: 2)
            : BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      color: isCompleted ? Colors.green[50] : Colors.white,
      child: InkWell(
        onTap: isCompleted ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ステップ番号とWeekラベル
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : Text(
                              '$stepNumber',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              step.week,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (hasTutorial)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tutorialWatched
                                        ? Colors.green[50]
                                        : Colors.orange[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        tutorialWatched
                                            ? Icons.check_circle
                                            : Icons.play_circle_outline,
                                        size: 12,
                                        color: tutorialWatched
                                            ? Colors.green[700]
                                            : Colors.orange[700],
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        tutorialWatched ? '視聴済' : '動画',
                                        style: theme.textTheme.caption?.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: tutorialWatched
                                              ? Colors.green[700]
                                              : Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          step.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? Colors.green[700]
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    step.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 説明文
              Text(
                step.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // アクションボタン
              if (!isCompleted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      step.actionLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '完了',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
