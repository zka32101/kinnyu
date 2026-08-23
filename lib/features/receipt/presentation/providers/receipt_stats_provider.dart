import 'package:riverpod/riverpod.dart';
import 'receipt_provider.dart';

/// 過去30日間のレシート記録から算出した、月換算の平均支出額を返す。
/// 記録が無い場合はnullを返す。
final averageMonthlyExpenseProvider =
    FutureProvider.family<int?, String>((ref, uid) async {
  final service = ref.watch(receiptServiceProvider);
  return service.getAverageMonthlyExpense(uid);
});
