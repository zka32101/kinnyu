import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../quiz/domain/models/question.dart';
import '../../domain/models/receipt.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/widgets/lottie_animations.dart';
import '../../../../core/theme/app_theme.dart';

class ReceiptQuizPage extends ConsumerStatefulWidget {
  final Question question;
  final Receipt receipt;

  const ReceiptQuizPage({Key? key, required this.question, required this.receipt})
      : super(key: key);

  @override
  ConsumerState<ReceiptQuizPage> createState() => _ReceiptQuizPageState();
}

class _ReceiptQuizPageState extends ConsumerState<ReceiptQuizPage> {
  int? selectedIndex;
  bool answered = false;

  @override
  Widget build(BuildContext context) {
    final isCorrect = selectedIndex == widget.question.correctAnswerIndex;

    return Scaffold(
      appBar: AppBar(title: const Text('実支出クイズ')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      Text(
                        '¥${widget.receipt.amount}の実支出から',
                        style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.question.question,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                ...List.generate(widget.question.options.length, (index) {
                  final isOptionCorrect = index == widget.question.correctAnswerIndex;
                  final isSelected = index == selectedIndex;
                  Color? bgColor;
                  if (answered) {
                    if (isOptionCorrect) {
                      bgColor = Colors.green.shade200;
                    } else if (isSelected) {
                      bgColor = Colors.red.shade200;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      onPressed: answered ? null : () => _selectAnswer(index),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: bgColor ?? Colors.blue.shade100,
                      ),
                      child: Text(
                        widget.question.options[index],
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  );
                }),
                if (answered) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(widget.question.explanation),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (!context.mounted) return;
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text('ホームに戻る'),
                  ),
                ],
              ],
            ),
          ),
          if (answered)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: 0,
              right: 0,
              child: isCorrect
                  ? LottieAnimations.correctAnswerAnimation()
                  : LottieAnimations.incorrectAnswerAnimation(),
            ),
        ],
      ),
    );
  }

  void _selectAnswer(int index) {
    setState(() {
      selectedIndex = index;
      answered = true;
    });

    final isCorrect = index == widget.question.correctAnswerIndex;
    final user = ref.read(userProvider);

    if (user != null) {
      ref.read(analyticsServiceProvider).logEvent(
        'quiz_from_receipt_completed',
        parameters: {
          'user_id': user.uid,
          'correct': isCorrect.toString(),
        },
      );
      if (isCorrect) {
        ref.read(userProvider.notifier).addXP(15);
      }
    }
  }
}
