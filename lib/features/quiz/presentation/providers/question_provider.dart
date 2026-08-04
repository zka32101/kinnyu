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

  void startQuiz(QuizCategory category, List<Question> questions) {
    state = QuizSessionState(
      category: category,
      questions: questions,
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
    state = null;
  }
}
