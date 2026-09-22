import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/furusato_gift.dart';

class FurusatoGiftService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _giftsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('furusatoGifts');
  }

  /// 登録された返礼品をリアルタイムで購読する（寄付日の降順）
  Stream<List<FurusatoGift>> watchGifts(String uid) {
    return _giftsRef(uid)
        .orderBy('donatedDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FurusatoGift.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<FurusatoGift> addGift({
    required String uid,
    required String municipality,
    required String itemName,
    required int donationAmount,
    required int taxYear,
    required DateTime donatedDate,
  }) async {
    final docRef = _giftsRef(uid).doc();
    final gift = FurusatoGift(
      id: docRef.id,
      uid: uid,
      municipality: municipality,
      itemName: itemName,
      donationAmount: donationAmount,
      taxYear: taxYear,
      donatedDate: donatedDate,
      createdAt: DateTime.now(),
    );

    try {
      await docRef.set(gift.toJson());
      return gift;
    } catch (e) {
      debugPrint('FurusatoGiftService.addGift failed: $e');
      rethrow;
    }
  }

  Future<void> setReceiptSubmitted({
    required String uid,
    required String giftId,
    required bool isReceiptSubmitted,
  }) async {
    try {
      await _giftsRef(uid).doc(giftId).update({'isReceiptSubmitted': isReceiptSubmitted});
    } catch (e) {
      debugPrint('FurusatoGiftService.setReceiptSubmitted failed: $e');
      rethrow;
    }
  }

  Future<void> deleteGift(String uid, String giftId) async {
    try {
      await _giftsRef(uid).doc(giftId).delete();
    } catch (e) {
      debugPrint('FurusatoGiftService.deleteGift failed: $e');
      rethrow;
    }
  }
}
