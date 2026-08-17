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
}
