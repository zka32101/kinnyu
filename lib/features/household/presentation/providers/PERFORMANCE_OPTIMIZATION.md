# Financial Health Provider Performance Optimization Guide

## Current State
All providers use `FutureProvider.autoDispose.family` which provides:
- ✅ Automatic disposal when no longer watched (memory efficiency)
- ✅ Per-family-parameter caching (same groupId reuses cached value)
- ❌ No TTL/expiration control for Firestore queries (will refetch on app resume)
- ❌ No lazy loading for large datasets (6-month trends)
- ❌ Potential redundant calculations across dependent providers

## Optimization Opportunities

### 1. Provider Composition & Dependency Chain
**Current Issue**: Providers that depend on others re-watch and trigger cascading rebuilds

**Solution**: Use select/watch patterns to minimize rebuilds
```dart
// BEFORE: Redundant watches
final compositeProvider = FutureProvider.autoDispose.family<Data, String>((ref, id) async {
  final score = await ref.watch(financialHealthScoreProvider(id).future);
  final trend = await ref.watch(financialHealthScoreTrendProvider(id).future);
  // Both trigger independent fetches
});

// AFTER: Efficient dependency
final compositeProvider = FutureProvider.autoDispose.family<Data, String>((ref, id) async {
  final trend = await ref.watch(financialHealthScoreTrendProvider(id).future);
  // Compute score from trend if needed, avoiding double-fetch
  final score = _deriveScoreFromTrend(trend);
});
```

### 2. Firestore Query Optimization (When Real Data Connected)

#### Index Strategy
For efficient queries when replacing mock data:
```firestore
// Recommended index: /groups/{groupId}/financialHealthScores
Index: groupId + calculatedAt DESC (for recent-first queries)

// Recommended index: /groups/{groupId}/expenses/{month}
Index: groupId + month (for monthly aggregations)
```

#### Pagination Strategy
```dart
// Load current month immediately, then background-load trends
final currentMonthProvider = FutureProvider.autoDispose.family<Data, String>((ref, id) async {
  // Fast: returns current month only (< 100ms)
  return await _fetchCurrentMonth(id);
});

final historicalTrendsProvider = FutureProvider.autoDispose.family<Data, String>((ref, id) async {
  // Background: loads previous 5 months (can be deferred)
  // Implement with startAfter() for pagination
  return await _fetchHistoricalData(id);
});
```

#### Query Batching
```dart
// Instead of 6 separate queries for 6 months:
// Batch into single collection group query:
final monthlySummariesProvider = FutureProvider.autoDispose.family<List<MonthlySummary>, String>(
  (ref, groupId) async {
    // Single query: where('groupId') orderBy('month')
    return await firestore
        .collection('groups/$groupId/financialSummaries')
        .where('year', isEqualTo: DateTime.now().year)
        .orderBy('month', descending: true)
        .limit(12) // Get 12 months efficiently
        .get();
  },
);
```

### 3. Category Score Caching

**Pattern**: TTL-based cache for expensive calculations
```dart
// Cache scores for 1 hour (category scores rarely change intraday)
final financialHealthScoreProvider = FutureProvider.autoDispose
    .family<FinancialHealthScore, String>((ref, groupId) async {
  // When connected to Firestore:
  // Check last calculation timestamp
  // If within 1 hour, return cached version
  // Otherwise: recalculate from expense data
  
  final lastCalculated = await _getLastCalculationTime(groupId);
  if (lastCalculated != null && 
      DateTime.now().difference(lastCalculated) < Duration(hours: 1)) {
    return _getCachedScore(groupId);
  }
  
  // Calculate fresh
  return _calculateScoreFromExpenses(groupId);
});
```

### 4. Lazy Loading for Detail Pages

**Current**: Load entire 6-month trend immediately
**Optimized**: Load current month, then trends

```dart
// Fast load: overview tab
final simpleBalanceSummaryProvider = FutureProvider.autoDispose
    .family<SimpleBalanceSummary, String>((ref, groupId) async {
  // Returns in <100ms from cache or single Firestore query
});

// Deferred load: trends tab (only fetched when tab opened)
final historicalComparisonProvider = FutureProvider.autoDispose
    .family<HistoricalComparison, String>((ref, groupId) async {
  // Loads on demand when user navigates to Trends tab
  // Shows loading state while fetching
});
```

### 5. Watch/Select Optimization in Widgets

**Pattern**: Reduce widget rebuild scope
```dart
// BEFORE: Rebuilds on any provider change
final data = ref.watch(complexProvider(groupId));

// AFTER: Only rebuild on specific fields
final score = ref.watch(
  complexProvider(groupId)
      .select((async) => async.whenData((data) => data.overallScore))
);
```

### 6. Request Deduplication

**Pattern**: Combine multiple identical requests
```dart
// When Detail Page loads both dashboard & detail widgets:
// Both watch financialHealthScoreProvider(groupId)
// Only one Firestore query happens (Riverpod automatic dedup)
```

## Implementation Checklist

### Phase 1: Provider Efficiency (No Firestore changes needed)
- [ ] Add select() optimizations to FinancialHealthScoreCard
- [ ] Document current caching behavior with comments
- [ ] Profile provider watch counts in detail page

### Phase 2: Lazy Loading (When real data replaces mocks)
- [ ] Implement separate currentMonth vs historical providers
- [ ] Add loading states to Trends tab
- [ ] Consider pagination for month selection

### Phase 3: Firestore Integration (Future work)
- [ ] Create Firestore indexes per above
- [ ] Replace mock data with collection queries
- [ ] Implement TTL caching for category calculations
- [ ] Add batch queries for multi-month data

### Phase 4: Analytics & Monitoring
- [ ] Log provider fetch times
- [ ] Monitor Firestore query counts
- [ ] Track cache hit rates

## Key Metrics to Monitor (When Live)

1. **Provider Load Times**:
   - Current month: < 200ms
   - Trends (6 month): < 500ms
   - Recommendations: < 300ms

2. **Firestore Usage**:
   - Avg queries per screen load: < 3
   - Read ops per user session: < 50/day

3. **Memory**:
   - Provider memory footprint: < 5MB
   - Cache size: < 2MB

## Notes

- All providers are `.autoDispose` ✅ (good for memory)
- No custom caching layer needed (Riverpod handles dedup) ✅
- Mock data sufficient until Firestore integration ✅
- Main optimization gains will come from query batching & pagination 📈
