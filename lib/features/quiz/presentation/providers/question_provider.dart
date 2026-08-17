import 'package:riverpod/riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/question_datasource.dart';
import '../../data/repositories/question_repository.dart';
import '../../domain/models/question.dart';

final questionDataSourceProvider = Provider((ref) {
  return QuestionDataSource();
});

final questionRepositoryProvider = Provider((ref) {
  final dataSource = ref.watch(questionDataSourceProvider);
  return QuestionRepository(dataSource: dataSource);
});

final questionsByCategoryProvider = FutureProvider.family<
    List<Question>,
    QuizCategory>((ref, category) async {
  final repository = ref.watch(questionRepositoryProvider);
  return repository.getQuestionsByCategory(category);
});

final randomQuestionProvider =
    FutureProvider.family<Question?, QuizCategory>((ref, category) async {
  final repository = ref.watch(questionRepositoryProvider);
  return repository.getRandomQuestion(category);
});

final questionsStreamProvider = StreamProvider.family<
    List<Question>,
    QuizCategory>((ref, category) {
  final repository = ref.watch(questionRepositoryProvider);
  return repository.watchQuestionsByCategory(category);
});

class QuizSessionState {
  final QuizCategory category;
  final List<Question> questions;
  final int currentQuestionIndex;
  final List<int?> userAnswers;
  final int score;

  QuizSessionState({
    required this.category,
    required this.questions,
    this.currentQuestionIndex = 0,
    List<int?>? userAnswers,
    this.score = 0,
  }) : userAnswers = userAnswers ?? List.filled(questions.length, null);

  QuizSessionState copyWith({
    QuizCategory? category,
    List<Question>? questions,
    int? currentQuestionIndex,
    List<int?>? userAnswers,
    int? score,
  }) {
    return QuizSessionState(
      category: category ?? this.category,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      score: score ?? this.score,
    );
  }

  bool get isComplete => currentQuestionIndex >= questions.length;

  Question? get currentQuestion =>
      currentQuestionIndex < questions.length
          ? questions[currentQuestionIndex]
          : null;
}

final quizSessionProvider =
    NotifierProvider<QuizSessionNotifier, QuizSessionState?>(() {
  return QuizSessionNotifier();
});

class QuizSessionNotifier extends Notifier<QuizSessionState?> {
  @override
  QuizSessionState? build() {
    return null;
  }

  /// クイズを開始する。以前のセッションがどのような状態で残っていても
  /// （例: 結果画面に到達せずにユーザーが画面を離脱した場合）、
  /// 常に完全にクリーンな初期状態から新しいセッションを開始することを保証する。
  void startQuiz(QuizCategory category, List<Question> questions) {
    // 古いセッションの影響を受けないよう、一度明示的にクリアしてから
    // 新規セッションを構築する。
    reset();
    state = QuizSessionState(
      category: category,
      questions: questions,
      currentQuestionIndex: 0,
      userAnswers: List<int?>.filled(questions.length, null),
      score: 0,
    );
  }

  void answerQuestion(int answerIndex) {
    if (state == null) return;

    final currentQuestion = state!.currentQuestion;
    if (currentQuestion == null) return;

    final isCorrect = answerIndex == currentQuestion.correctAnswerIndex;
    final newScore = state!.score + (isCorrect ? 10 : 0);
    final newAnswers = List<int?>.from(state!.userAnswers);
    newAnswers[state!.currentQuestionIndex] = answerIndex;

    state = state!.copyWith(
      userAnswers: newAnswers,
      score: newScore,
    );
  }

  void nextQuestion() {
    if (state == null) return;
    state = state!.copyWith(
      currentQuestionIndex: state!.currentQuestionIndex + 1,
    );
  }

  void endQuiz() {
    reset();
  }

  /// セッション状態を完全にクリアする。結果画面に到達する前にユーザーが
  /// クイズを離脱した場合などに、次回このプロバイダが利用されるときへ
  /// 古いセッションの状態が持ち越されないようにするために使用する。
  void reset() {
    state = null;
  }
}
