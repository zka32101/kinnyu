import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Performance metrics for Riverpod providers
class ProviderMetrics {
  final String providerName;
  final DateTime requestTime;
  final Duration? duration;
  final bool isCache;
  final Object? error;

  ProviderMetrics({
    required this.providerName,
    required this.requestTime,
    this.duration,
    this.isCache = false,
    this.error,
  });

  @override
  String toString() =>
    'ProviderMetrics($providerName, duration: ${duration?.inMilliseconds}ms, cache: $isCache, error: $error)';
}

/// Provider metrics logger - tracks performance of async providers
class ProviderMetricsCollector {
  static final instance = ProviderMetricsCollector._();

  final List<ProviderMetrics> _metrics = [];

  ProviderMetricsCollector._();

  void record(ProviderMetrics metric) {
    _metrics.add(metric);
    // Keep only last 100 metrics to avoid memory bloat
    if (_metrics.length > 100) {
      _metrics.removeAt(0);
    }
  }

  List<ProviderMetrics> getMetrics({
    String? providerName,
    Duration? minDuration,
  }) {
    return _metrics.where((m) {
      if (providerName != null && m.providerName != providerName) return false;
      if (minDuration != null && m.duration != null && m.duration! < minDuration) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Get average fetch time for a provider
  Duration? getAverageDuration(String providerName) {
    final matching = _metrics
        .where((m) => m.providerName == providerName && m.duration != null)
        .toList();
    if (matching.isEmpty) return null;

    final total = matching.fold<int>(0, (sum, m) => sum + m.duration!.inMilliseconds);
    return Duration(milliseconds: total ~/ matching.length);
  }

  /// Get cache hit rate for a provider
  double getCacheHitRate(String providerName) {
    final matching = _metrics.where((m) => m.providerName == providerName).toList();
    if (matching.isEmpty) return 0;

    final cacheHits = matching.where((m) => m.isCache).length;
    return cacheHits / matching.length;
  }

  void clear() => _metrics.clear();
}

/// Helper to wrap async operations with metrics collection
Future<T> measurePerformance<T>({
  required String providerName,
  required Future<T> Function() operation,
  bool recordMetrics = true,
}) async {
  final startTime = DateTime.now();

  try {
    final result = await operation();

    if (recordMetrics) {
      final duration = DateTime.now().difference(startTime);
      ProviderMetricsCollector.instance.record(
        ProviderMetrics(
          providerName: providerName,
          requestTime: startTime,
          duration: duration,
          isCache: false,
        ),
      );
    }

    return result;
  } catch (e) {
    if (recordMetrics) {
      ProviderMetricsCollector.instance.record(
        ProviderMetrics(
          providerName: providerName,
          requestTime: startTime,
          duration: DateTime.now().difference(startTime),
          error: e,
        ),
      );
    }
    rethrow;
  }
}
