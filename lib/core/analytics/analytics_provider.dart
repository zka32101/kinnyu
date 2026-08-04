import 'package:riverpod/riverpod.dart';
import 'analytics_service.dart';

final analyticsServiceProvider = Provider((ref) {
  return AnalyticsService();
});
