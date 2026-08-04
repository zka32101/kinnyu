enum QuizCategory { savings, tax, invest, insurance }

enum QuizDifficulty { easy, medium, hard }

class Question {
  final String id;
  final QuizCategory category;
  final QuizDifficulty difficulty;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  Question({
    required this.id,
    required this.category,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      category: QuizCategory.values[json['category'] as int],
      difficulty: QuizDifficulty.values[json['difficulty'] as int],
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswerIndex: json['correctAnswerIndex'] as int,
      explanation: json['explanation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.index,
      'difficulty': difficulty.index,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }
}
