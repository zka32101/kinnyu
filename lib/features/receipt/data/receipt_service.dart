import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/receipt.dart';

class ReceiptService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _receiptsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('receipts');
  }

  Future<Receipt> saveReceipt({
    required String uid,
    required ReceiptCategory category,
    required int amount,
    String? imagePath,
  }) async {
    final now = DateTime.now();
    final docRef = _receiptsRef(uid).doc();
    final receipt = Receipt(
      id: docRef.id,
      uid: uid,
      imagePath: imagePath,
      date: now,
      category: category,
      amount: amount,
      createdAt: now,
    );

    try {
      await docRef.set(receipt.toJson());
      return receipt;
    } catch (e) {
      debugPrint('ReceiptService.saveReceipt failed for uid=$uid: $e');
      rethrow;
    }
  }

  // NOTE: This uses simple limit-based pagination. For full cursor-based
  // pagination (e.g. via startAfterDocument()), the method signature would
  // need to accept a document cursor / last-fetched document.
  Future<List<Receipt>> getRecentReceipts(String uid, {int limit = 10}) async {
    try {
      final snapshot = await _receiptsRef(uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Receipt.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch receipts: $e');
    }
  }

  /// 過去[days]日間のレシート記録から、月換算の平均支出額を返す。
  /// 記録が無い場合はnullを返す。
  Future<int?> getAverageMonthlyExpense(String uid, {int days = 30}) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final snapshot = await _receiptsRef(uid)
          .where('createdAt', isGreaterThanOrEqualTo: cutoff.toIso8601String())
          .get();

      if (snapshot.docs.isEmpty) return null;

      final total = snapshot.docs.fold<int>(
        0,
        (sum, doc) => sum + (doc.data()['amount'] as int? ?? 0),
      );

      // days日間の合計を30日換算の月額に正規化
      return (total / days * 30).round();
    } catch (e) {
      debugPrint('ReceiptService.getAverageMonthlyExpense failed for uid=$uid: $e');
      return null;
    }
  }
}
