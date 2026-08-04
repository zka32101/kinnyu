import 'package:riverpod/riverpod.dart';
import '../../data/receipt_service.dart';
import '../../domain/models/receipt.dart';

final receiptServiceProvider = Provider((ref) {
  return ReceiptService();
});

final recentReceiptsProvider =
    FutureProvider.family<List<Receipt>, String>((ref, uid) async {
  final service = ref.watch(receiptServiceProvider);
  return service.getRecentReceipts(uid);
});
