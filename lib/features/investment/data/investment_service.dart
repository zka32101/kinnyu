import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/investment.dart';
import '../domain/services/market_simulator.dart';

class InvestmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _investmentsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('investments');
  }

  Future<Investment> createInvestment({
    required String uid,
    required int savingsAmount,
    required InvestmentType type,
  }) async {
    final now = DateTime.now();
    final purchaseIndexValue = MarketSimulator.getCurrentIndexValue(type, asOf: now);

    final docRef = _investmentsRef(uid).doc();
    final investment = Investment(
      id: docRef.id,
      uid: uid,
      savingsAmount: savingsAmount,
      investmentType: type,
      purchaseDate: now,
      purchaseIndexValue: purchaseIndexValue,
    );

    try {
      await docRef.set(investment.toJson());
      return investment;
    } catch (e) {
      debugPrint('createInvestment error: $e');
      rethrow;
    }
  }

  Future<List<Investment>> getActiveInvestments(String uid) async {
    try {
      final snapshot = await _investmentsRef(uid)
          .where('status', isEqualTo: InvestmentStatus.active.index)
          .get();

      return snapshot.docs
          .map((doc) => Investment.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch investments: $e');
    }
  }

  Stream<List<Investment>> watchActiveInvestments(String uid) {
    return _investmentsRef(uid)
        .where('status', isEqualTo: InvestmentStatus.active.index)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Investment.fromJson({...doc.data(), 'id': doc.id}))
            .toList())
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stack, sink) {
              debugPrint('watchActiveInvestments error: $error');
              sink.addError(error, stack);
            },
          ),
        );
  }

  Future<void> realizeInvestment(String uid, String investmentId) async {
    try {
      final docRef = _investmentsRef(uid).doc(investmentId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) {
          throw Exception('投資が見つかりません');
        }

        final data = doc.data()!;
        final currentStatus = data['status'] as int?;
        if (currentStatus == InvestmentStatus.realized.index) {
          throw Exception('既に実現済みです');
        }

        final investment = Investment.fromJson({...data, 'id': doc.id});
        final currentIndexValue =
            MarketSimulator.getCurrentIndexValue(investment.investmentType);

        transaction.update(docRef, {
          'status': InvestmentStatus.realized.index,
          'realizedAt': DateTime.now().toIso8601String(),
          'realizedIndexValue': currentIndexValue,
        });
      });
    } catch (e) {
      debugPrint('realizeInvestment error: $e');
      rethrow;
    }
  }
}
