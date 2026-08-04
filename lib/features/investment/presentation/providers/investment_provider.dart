import 'package:riverpod/riverpod.dart';
import '../../data/investment_service.dart';
import '../../domain/models/investment.dart';

final investmentServiceProvider = Provider((ref) {
  return InvestmentService();
});

final activeInvestmentsProvider =
    StreamProvider.family<List<Investment>, String>((ref, uid) {
  final service = ref.watch(investmentServiceProvider);
  return service.watchActiveInvestments(uid);
});
