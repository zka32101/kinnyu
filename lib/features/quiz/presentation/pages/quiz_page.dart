import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/question.dart';
import '../providers/question_provider.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';
import '../../../user_profile/presentation/providers/streak_provider.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/widgets/lottie_animations.dart';
import '../../../../core/theme/app_theme.dart';

class QuizPage extends ConsumerWidget {
  final QuizCategory category;

  const QuizPage({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizSession = ref.watch(quizSessionProvider);

    if (quizSession == null) {
      return _buildLoadingQuiz(context, ref, category);
    }

    if (quizSession.isComplete) {
      return _buildResultsScreen(context, ref, quizSession);
    }

    return _buildQuizScreen(context, ref, quizSession);
  }

  Widget _buildLoadingQuiz(
      BuildContext context, WidgetRef ref, QuizCategory category) {
    return Scaffold(
      appBar: AppBar(title: const Text('クイズを開始中...')),
      body: Center(
        child: ref
            .watch(questionsByCategoryProvider(category))
            .when(
              data: (questions) {
                if (questions.isEmpty) {
                  return const Text('問題がありません');
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  try {
                    ref
                        .read(quizSessionProvider.notifier)
                        .startQuiz(category, questions);
                  } catch (e, stack) {
                    debugPrint('Failed to start quiz: $e\n$stack');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'クイズの開始に失敗しました。もう一度お試しください。'),
                          action: SnackBarAction(
                            label: '再試行',
                            onPressed: () {
                              ref.invalidate(
                                  questionsByCategoryProvider(category));
                            },
                          ),
                        ),
                      );
                    }
                  }
                });
                return const CircularProgressIndicator();
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('エラー: $error'),
            ),
      ),
    );
  }

  Widget _buildQuizScreen(
      BuildContext context, WidgetRef ref, QuizSessionState session) {
    final question = session.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    final alreadyAnswered =
        session.userAnswers[session.currentQuestionIndex] != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${session.currentQuestionIndex + 1}/${session.questions.length}',
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (session.currentQuestionIndex + 1) /
                  session.questions.length,
            ),
            const SizedBox(height: 24),
            Text(
              question.question,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            ...List.generate(
              question.options.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: alreadyAnswered
                      ? null
                      : () {
                          ref.read(quizSessionProvider.notifier)
                              .answerQuestion(index);
                          if (session.currentQuestionIndex <
                              session.questions.length - 1) {
                            Future.delayed(
                                const Duration(milliseconds: 500), () {
                              if (!context.mounted) return;
                              ref
                                  .read(quizSessionProvider.notifier)
                                  .nextQuestion();
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.shade200,
                  ),
                  child: Text(
                    question.options[index],
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'スコア: ${session.score}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen(
      BuildContext context, WidgetRef ref, QuizSessionState session) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      // 端末回転やテキストサイズ変更などによる再ビルドで、この結果画面の
      // XP付与・連続記録更新・アナリティクスが重複して実行されるのを防ぐ。
      if (session.rewarded) return;
      try {
        final user = ref.read(userProvider);
        final analytics = ref.read(analyticsServiceProvider);
        final streakService = ref.read(streakServiceProvider);

        if (user != null) {
          final categoryName = _getCategoryName(session.category);
          analytics.logQuizComplete(user.uid, categoryName, session.score);

          ref.read(userProvider.notifier).addXP(session.score);

          streakService.updateStreak(user.uid);

          if (!user.ahaAchieved && session.score >= 20) {
            analytics.logAhaMomentReached(
                user.uid, '${session.category.index}');
            ref.read(userProvider.notifier).setAhaAchieved();
          }

          ref.read(quizSessionProvider.notifier).markRewarded();
        }
      } catch (e, stack) {
        debugPrint('Failed to record quiz completion: $e\n$stack');
      }
    });

    final maxScore = session.questions.length * 10;
    final isGoodScore = maxScore > 0 && session.score / maxScore >= 0.6;

    return Scaffold(
      appBar: AppBar(title: const Text('クイズ終了')),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    isGoodScore
                        ? 'assets/images/mascot/mascot_correct.png'
                        : 'assets/images/mascot/mascot_incorrect.png',
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) =>
                        LottieAnimations.correctAnswerAnimation(
                      onComplete: () {},
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'スコア',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${session.score} XP',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(quizSessionProvider.notifier).endQuiz();
                      Navigator.pop(context);
                    },
                    child: const Text('ホームに戻る'),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LottieAnimations.successParticles(
              duration: const Duration(seconds: 2),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(QuizCategory category) {
    switch (category) {
      case QuizCategory.savings:
        return 'savings';
      case QuizCategory.tax:
        return 'tax';
      case QuizCategory.invest:
        return 'invest';
      case QuizCategory.insurance:
        return 'insurance';
    }
  }
}
