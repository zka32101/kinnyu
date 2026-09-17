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

  /// 指定年月の支出一覧を日付降順で取得
  Future<List<Receipt>> getMonthlyReceipts(
    String uid, {
    required int year,
    required int month,
  }) async {
    try {
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

      final snapshot = await _receiptsRef(uid)
          .where('date', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
          .where('date', isLessThanOrEqualTo: endOfMonth.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Receipt.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('ReceiptService.getMonthlyReceipts failed: $e');
      throw Exception('Failed to fetch monthly receipts: $e');
    }
  }

  /// 支出を更新
  Future<void> updateReceipt({
    required String uid,
    required String receiptId,
    ReceiptCategory? category,
    int? amount,
    DateTime? date,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (category != null) updates['category'] = category.toString();
      if (amount != null) updates['amount'] = amount;
      if (date != null) updates['date'] = date.toIso8601String();

      if (updates.isEmpty) return;

      await _receiptsRef(uid).doc(receiptId).update(updates);
    } catch (e) {
      debugPrint('ReceiptService.updateReceipt failed: $e');
      rethrow;
    }
  }

  /// 支出を削除
  Future<void> deleteReceipt(String uid, String receiptId) async {
    try {
      await _receiptsRef(uid).doc(receiptId).delete();
    } catch (e) {
      debugPrint('ReceiptService.deleteReceipt failed: $e');
      rethrow;
    }
  }

  /// 指定カテゴリの支出一覧を取得
  Future<List<Receipt>> getReceiptsByCategory(
    String uid, {
    required ReceiptCategory category,
    int limit = 100,
  }) async {
    try {
      final snapshot = await _receiptsRef(uid)
          .where('category', isEqualTo: category.toString())
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Receipt.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('ReceiptService.getReceiptsByCategory failed: $e');
      throw Exception('Failed to fetch receipts by category: $e');
    }
  }
}
