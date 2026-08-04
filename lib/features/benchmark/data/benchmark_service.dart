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
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('spending')
          .doc(category.name)
          .get();

      final userAmount = doc.exists ? (doc.data()?['amount'] as int? ?? 0) : 0;
      final nationalAverage = BenchmarkStatsProvider.getNationalAverage(category);
      final percentile =
          BenchmarkStatsProvider.calculatePercentile(userAmount, category);

      return Benchmark(
        category: category,
        userAmount: userAmount,
        ageGroupAverage: nationalAverage,
        ageGroupPercentile: percentile,
        incomeGroupAverage: nationalAverage,
      );
    } catch (e) {
      throw Exception('Failed to fetch benchmark: $e');
    }
  }

  Future<List<Benchmark>> getAllBenchmarks(String uid) async {
    final benchmarks = <Benchmark>[];
    for (final category in BenchmarkCategory.values) {
      benchmarks.add(await getBenchmark(uid: uid, category: category));
    }
    return benchmarks;
  }
}
