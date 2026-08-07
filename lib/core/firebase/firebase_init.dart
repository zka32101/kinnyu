import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/quiz/domain/models/question.dart';
import 'question_seed_savings.dart';
import 'question_seed_tax.dart';
import 'question_seed_invest.dart';
import 'question_seed_insurance.dart';

class FirebaseInitializer {
  static final FirebaseInitializer _instance = FirebaseInitializer._internal();

  factory FirebaseInitializer() {
    return _instance;
  }

  FirebaseInitializer._internal();

  /// 全カテゴリの問題（48問）
  static List<Question> allQuestions() => [
        ...savingsQuestions(),
        ...taxQuestions(),
        ...investQuestions(),
        ...insuranceQuestions(),
      ];

  Future<void> initializeTestData({bool forceReseed = false}) async {
    final firestore = FirebaseFirestore.instance;

    try {
      print('FirebaseInitializer: Starting test data initialization...');
      final questionsRef = firestore.collection('questions');

      // Firestore へのアクセステスト
      final snapshot = await questionsRef.limit(1).get();
      print('FirebaseInitializer: Firestore connection successful');

      final questions = allQuestions();

      // 既存データが最新の問題数と一致していれば何もしない
      if (!forceReseed && snapshot.docs.length >= questions.length) {
        print('FirebaseInitializer: Test data already up to date (${snapshot.docs.length} docs)');
        return;
      }

      print('FirebaseInitializer: Writing ${questions.length} questions to Firestore...');

      // バッチ書き込みで全問題を投入（upsert）
      final batch = firestore.batch();
      for (final question in questions) {
        batch.set(questionsRef.doc(question.id), question.toJson());
      }
      await batch.commit();

      print('FirebaseInitializer: Test data initialization completed successfully');
    } catch (e) {
      // ネットワーク接続なし、Firebase未初期化などの場合もアプリは起動できるように
      print('FirebaseInitializer: Warning - Failed to initialize test data: $e');
      print('FirebaseInitializer: App will continue to run without test data');
    }
  }
}
