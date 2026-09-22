import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/furusato_gift_service.dart';
import '../../domain/models/furusato_gift.dart';

final furusatoGiftServiceProvider = Provider((ref) {
  return FurusatoGiftService();
});

// autoDispose: このプロバイダーが監視されなくなったら Firestore の
// ストリーム購読を確実に解除し、リークを防ぐ。
final furusatoGiftsStreamProvider =
    StreamProvider.autoDispose.family<List<FurusatoGift>, String>((ref, uid) {
  final service = ref.watch(furusatoGiftServiceProvider);
  return service.watchGifts(uid);
});
