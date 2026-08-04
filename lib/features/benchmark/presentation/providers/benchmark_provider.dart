import 'package:riverpod/riverpod.dart';
import '../../data/benchmark_service.dart';
import '../../domain/models/benchmark.dart';

final benchmarkServiceProvider = Provider((ref) {
  return BenchmarkService();
});

final allBenchmarksProvider =
    FutureProvider.family<List<Benchmark>, String>((ref, uid) async {
  final service = ref.watch(benchmarkServiceProvider);
  return service.getAllBenchmarks(uid);
});
