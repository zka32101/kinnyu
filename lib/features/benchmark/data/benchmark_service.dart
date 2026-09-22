import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/benchmark.dart';

class BenchmarkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitUserSpending({
    required String uid,
    required BenchmarkCategory category,
    required int amount,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('spending')
          .doc(category.name)
          .set({
        'category': category.index,
        'amount': amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to submit spending: $e');
    }
  }

  Future<Benchmark> getBenchmark({
    required String uid,
    required BenchmarkCategory category,
    required AgeGroup ageGroup,
    required IncomeGroup incomeGroup,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('spending')
          .doc(category.name)
          .get();

      final userAmount = doc.exists ? (doc.data()?['amount'] as int? ?? 0) : 0;
      final ageGroupAverage =
          BenchmarkStatsProvider.getAgeGroupAverage(category, ageGroup);
      final incomeGroupAverage =
          BenchmarkStatsProvider.getIncomeGroupAverage(category, incomeGroup);
      final percentile = BenchmarkStatsProvider.calculatePercentileForLowerIsBetter(
          userAmount, ageGroupAverage);

      return Benchmark(
        category: category,
        userAmount: userAmount,
        ageGroupAverage: ageGroupAverage,
        ageGroupPercentile: percentile,
        incomeGroupAverage: incomeGroupAverage,
      );
    } catch (e) {
      throw Exception('Failed to fetch benchmark: $e');
    }
  }

  Future<List<Benchmark>> getAllBenchmarks(
    String uid, {
    required AgeGroup ageGroup,
    required IncomeGroup incomeGroup,
  }) async {
    final results = await Future.wait(
      BenchmarkCategory.values.map((category) => getBenchmark(
            uid: uid,
            category: category,
            ageGroup: ageGroup,
            incomeGroup: incomeGroup,
          )),
    );
    return results;
  }
}
