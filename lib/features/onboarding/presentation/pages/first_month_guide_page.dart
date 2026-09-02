import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/first_month_guide_provider.dart';
import '../widgets/first_month_guide_card.dart';
import '../../domain/models/first_month_guide.dart';

/// 最初の1ヶ月ガイドページ
class FirstMonthGuidePage extends ConsumerWidget {
  const FirstMonthGuidePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepsAsync = ref.watch(firstMonthGuideProvider);
    final progressAsync = ref.watch(firstMonthGuideProgressProvider);
    final allCompletedAsync = ref.watch(firstMonthGuideCompletedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('最初の1ヶ月ガイド 📚'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // プログレスセクション
              progressAsync.when(
                data: (progress) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'あなたの進捗',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: Colors.grey[300],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ガイドを完了して、okane_koreを使いこなそう！',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (error, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 32),

              // ステップリスト
              Text(
                'ステップ',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              stepsAsync.when(
                data: (steps) {
                  return Column(
                    children: List.generate(steps.length, (index) {
                      final step = steps[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FirstMonthGuideCard(
                          step: step,
                          stepNumber: index + 1,
                          onTap: () {
                            _handleStepAction(context, ref, step);
                          },
                        ),
                      );
                    }),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Text('エラーが発生しました: $error'),
                ),
              ),

              const SizedBox(height: 32),

              // 完了時のメッセージ
              allCompletedAsync.when(
                data: (isCompleted) {
                  if (isCompleted) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '🎉',
                            style: const TextStyle(fontSize: 48),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'おめでとうございます！',
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'すべてのステップを完了しました。これからokane_koreで家計管理を楽しんでください！',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (error, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// ステップのアクションを処理
  void _handleStepAction(
    BuildContext context,
    WidgetRef ref,
    FirstMonthGuideStep step,
  ) {
    switch (step.type) {
      case FirstMonthGuideStepType.quiz:
        _showQuizDialog(context, ref, step);
        break;
      case FirstMonthGuideStepType.householdMembers:
        // 世帯メンバー登録ページへナビゲート
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('世帯メンバー登録機能へ移動します...')),
        );
        break;
      case FirstMonthGuideStepType.budgetSetup:
        // 予算設定ページへナビゲート
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('予算設定ページへ移動します...')),
        );
        break;
      case FirstMonthGuideStepType.receiptCapture:
        // レシート撮影機能へナビゲート
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レシートスキャン機能へ移動します...')),
        );
        break;
      case FirstMonthGuideStepType.challengeStart:
        // チャレンジページへナビゲート
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('チャレンジページへ移動します...')),
        );
        break;
    }
  }

  /// クイズダイアログを表示
  void _showQuizDialog(
    BuildContext context,
    WidgetRef ref,
    FirstMonthGuideStep step,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) => _QuizSheet(step: step),
    );
  }
}

/// クイズシート
class _QuizSheet extends ConsumerStatefulWidget {
  final FirstMonthGuideStep step;

  const _QuizSheet({required this.step});

  @override
  ConsumerState<_QuizSheet> createState() => _QuizSheetState();
}

class _QuizSheetState extends ConsumerState<_QuizSheet> {
  int _currentQuizIndex = 0;
  int _score = 0;
  bool _showResult = false;

  final List<QuizQuestion> _quizzes = [
    QuizQuestion(
      question: '家計管理の第一歩は何でしょう？',
      options: [
        '給料を全て貯金する',
        '現状の支出を把握する',
        '株を買う',
        'クレジットカードを増やす',
      ],
      correctIndex: 1,
      explanation: '支出を把握することが、家計管理の第一歩です！',
    ),
    QuizQuestion(
      question: '効果的な家計予算の配分は？',
      options: [
        '給料全て自由に使う',
        '50:30:20ルール（生活費:娯楽:貯蓄）',
        '生活費だけを最小化',
        'クレジットカードで全て支払う',
      ],
      correctIndex: 1,
      explanation:
          'バランスの取れた予算配分が家計管理の鍵です！',
    ),
    QuizQuestion(
      question: 'okane_koreの最大の特徴は何でしょう？',
      options: [
        '自動支出分析と家族連携',
        '株価情報の提供',
        '銀行口座管理のみ',
        'ATM検索機能',
      ],
      correctIndex: 0,
      explanation:
          'okane_koreは自動分析と家族連携で家計管理を楽しくします！',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_showResult) {
      return _buildResultScreen();
    }

    final currentQuiz = _quizzes[_currentQuizIndex];

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'クイズ ${_currentQuizIndex + 1}/${_quizzes.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (_currentQuizIndex + 1) / _quizzes.length,
                  minHeight: 6,
                  backgroundColor: Colors.grey[300],
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            currentQuiz.question,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(
            currentQuiz.options.length,
            (index) => _buildQuizOption(currentQuiz, index),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizOption(QuizQuestion quiz, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () async {
          if (index == quiz.correctIndex) {
            _score++;
          }

          if (_currentQuizIndex < _quizzes.length - 1) {
            setState(() {
              _currentQuizIndex++;
            });
          } else {
            setState(() {
              _showResult = true;
            });

            // ステップを完了にマーク
            try {
              final mutator = await ref.read(firstMonthGuideMutatorProvider.future);
              await mutator.completeStep(FirstMonthGuideStepType.quiz);
            } catch (e) {
              // エラーハンドリング
              print('Error completing quiz step: $e');
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[50],
          foregroundColor: Colors.blue[700],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.blue[300]!),
          ),
        ),
        child: Text(
          quiz.options[index],
          textAlign: TextAlign.left,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final percentage = ((_score / _quizzes.length) * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🎉',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          Text(
            'クイズ完了！',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '正解: $_score / ${_quizzes.length} ($percentage%)',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '金融知識の基礎が身についています！',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ガイドに戻る'),
            ),
          ),
        ],
      ),
    );
  }
}

/// クイズ問題
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}
