enum BenchmarkCategory {
  food,
  utility,
  entertainment,
  transport,
  communication,
  housing,
  daily,
  insurance,
}

class Benchmark {
  final BenchmarkCategory category;
  final int userAmount;
  final int ageGroupAverage;
  final int ageGroupPercentile;
  final int incomeGroupAverage;

  Benchmark({
    required this.category,
    required this.userAmount,
    required this.ageGroupAverage,
    required this.ageGroupPercentile,
    required this.incomeGroupAverage,
  });

  bool get isBelowAverage => userAmount < ageGroupAverage;

  int get differenceFromAverage => ageGroupAverage - userAmount;
}

class BenchmarkCategoryInfo {
  static const Map<BenchmarkCategory, String> displayNames = {
    BenchmarkCategory.food: '食費',
    BenchmarkCategory.utility: '光熱費',
    BenchmarkCategory.entertainment: '娯楽費',
    BenchmarkCategory.transport: '交通費',
    BenchmarkCategory.communication: '通信費',
    BenchmarkCategory.housing: '住居費',
    BenchmarkCategory.daily: '日用品費',
    BenchmarkCategory.insurance: '保険料',
  };
}

/// 匿名化された統計データ。5人以上のグループでのみ集計する（プライバシー保護のため）。
/// 実データ連携前の仮の全国統計値。
class BenchmarkStatsProvider {
  static const Map<BenchmarkCategory, int> nationalAverages = {
    BenchmarkCategory.food: 52000,
    BenchmarkCategory.utility: 18000,
    BenchmarkCategory.entertainment: 15000,
    BenchmarkCategory.transport: 12000,
    BenchmarkCategory.communication: 10000,
    BenchmarkCategory.housing: 68000,
    BenchmarkCategory.daily: 11000,
    BenchmarkCategory.insurance: 18000,
  };

  static int getNationalAverage(BenchmarkCategory category) {
    return nationalAverages[category] ?? 0;
  }

  static int calculatePercentile(int userAmount, BenchmarkCategory category) {
    final average = getNationalAverage(category);
    if (average == 0) return 50;

    final ratio = userAmount / average;
    if (ratio <= 0.6) return 10;
    if (ratio <= 0.8) return 20;
    if (ratio <= 1.0) return 40;
    if (ratio <= 1.2) return 60;
    if (ratio <= 1.5) return 80;
    return 90;
  }
}
