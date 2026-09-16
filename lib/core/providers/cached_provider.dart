import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cached value wrapper with TTL support
class CachedValue<T> {
  final T value;
  final DateTime cachedAt;
  final Duration ttl;

  CachedValue({
    required this.value,
    required this.ttl,
  }) : cachedAt = DateTime.now();

  /// Check if cache is still valid
  bool get isValid => DateTime.now().difference(cachedAt) < ttl;

  /// Time remaining until cache expires
  Duration get timeRemaining {
    final diff = Duration(
      milliseconds: ttl.inMilliseconds -
        DateTime.now().difference(cachedAt).inMilliseconds
    );
    return diff.isNegative ? Duration.zero : diff;
  }
}

/// Provider extension to add TTL-based caching
///
/// Usage:
/// ```dart
/// final myProvider = FutureProvider.autoDispose
///     .family<Data, String>((ref, id) async {
///   return ref.cachedFetch(
///     key: 'expensive-operation-$id',
///     ttl: Duration(hours: 1),
///     fetch: () => _expensiveOperation(id),
///   );
/// });
/// ```
extension CachedProviderRef on Ref {
  static final _cache = <String, CachedValue<dynamic>>{};

  /// Fetch with TTL caching
  ///
  /// If a cached value exists and is still valid, returns it immediately.
  /// Otherwise, calls [fetch] and caches the result.
  Future<T> cachedFetch<T>({
    required String key,
    required Duration ttl,
    required Future<T> Function() fetch,
  }) async {
    final cached = _cache[key];

    // Return cached value if valid
    if (cached != null && cached.isValid) {
      return cached.value as T;
    }

    // Fetch new value
    final result = await fetch();
    _cache[key] = CachedValue<T>(value: result, ttl: ttl);

    return result;
  }

  /// Clear cache for a specific key
  void clearCache(String key) {
    _cache.remove(key);
  }

  /// Clear all cache
  static void clearAllCache() {
    _cache.clear();
  }

  /// Get cache hit rate (for monitoring)
  static Map<String, dynamic> getCacheStats() {
    final validCount = _cache.values.where((v) => v.isValid).length;
    final expiredCount = _cache.values.where((v) => !v.isValid).length;

    return {
      'total_entries': _cache.length,
      'valid_entries': validCount,
      'expired_entries': expiredCount,
      'hit_rate': _cache.isEmpty ? 0.0 : validCount / _cache.length,
    };
  }
}
