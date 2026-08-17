import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/question.dart';

class QuestionDataSource {
  final FirebaseFirestore firestore;

  QuestionDataSource({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  /// カテゴリの全問題を取得し、シャッフルして出題数（既定5問）を返す。
  /// 毎回異なる問題が出題されるため、リプレイ性が高まる。
  Future<List<Question>> getQuestionsByCategory(
    QuizCategory category, {
    int count = 5,
  }) async {
    try {
      final query = await firestore
          .collection('questions')
          .where('category', isEqualTo: category.index)
          .get();

      final all = query.docs
          .map((doc) => Question.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      all.shuffle(Random());
      return all.take(count).toList();
    } catch (e) {
      throw Exception('Failed to fetch questions: $e');
    }
  }

  Future<Question?> getRandomQuestion(QuizCategory category) async {
    try {
      final query = await firestore
          .collection('questions')
          .where('category', isEqualTo: category.index)
          .get();

      if (query.docs.isEmpty) return null;
      final docs = query.docs..shuffle(Random());
      return Question.fromJson({...docs.first.data(), 'id': docs.first.id});
    } catch (e) {
      throw Exception('Failed to fetch random question: $e');
    }
  }

  Future<void> addQuestion(Question question) async {
    try {
      await firestore
          .collection('questions')
          .doc(question.id)
          .set(question.toJson());
    } catch (e) {
      throw Exception('Failed to add question: $e');
    }
  }

  Stream<List<Question>> getQuestionsStream(QuizCategory category) {
    return firestore
        .collection('questions')
        .where('category', isEqualTo: category.index)
        .snapshots()
        .map((query) {
          final questions = <Question>[];
          for (final doc in query.docs) {
            try {
              questions.add(
                  Question.fromJson({...doc.data(), 'id': doc.id}));
            } catch (e, stack) {
              // 1件のドキュメントの解析失敗でストリーム全体を落とさないよう、
              // 不正なドキュメントはログに残してスキップする。
              debugPrint(
                  'getQuestionsStream: failed to parse question ${doc.id}: $e\n$stack');
            }
          }
          return questions;
        })
        .transform(
          StreamTransformer<List<Question>, List<Question>>.fromHandlers(
            handleError: (error, stack, sink) {
              // Firestore側のエラー（権限エラー・接続断など）をログに残しつつ、
              // UI側のAsyncValue.errorハンドリングに伝播させる。
              debugPrint('getQuestionsStream error: $error\n$stack');
              sink.addError(error, stack);
            },
          ),
        );
  }
}
