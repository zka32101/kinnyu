import '../../domain/models/question.dart';
import '../datasources/question_datasource.dart';

class QuestionRepository {
  final QuestionDataSource dataSource;

  QuestionRepository({required this.dataSource});

  Future<List<Question>> getQuestionsByCategory(QuizCategory category) {
    return dataSource.getQuestionsByCategory(category);
  }

  Future<Question?> getRandomQuestion(QuizCategory category) {
    return dataSource.getRandomQuestion(category);
  }

  Future<void> addQuestion(Question question) {
    return dataSource.addQuestion(question);
  }

  Stream<List<Question>> watchQuestionsByCategory(QuizCategory category) {
    return dataSource.getQuestionsStream(category);
  }
}
