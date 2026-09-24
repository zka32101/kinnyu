import 'dart:math' as math;

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

/// 年代区分（ベンチマーク比較の対象グループ選択に使用）
enum AgeGroup { twenties, thirties, forties, fifties, sixtiesPlus }

extension AgeGroupInfo on AgeGroup {
  String get displayName {
    switch (this) {
      case AgeGroup.twenties:
        return '20代';
      case AgeGroup.thirties:
        return '30代';
      case AgeGroup.forties:
        return '40代';
      case AgeGroup.fifties:
        return '50代';
      case AgeGroup.sixtiesPlus:
        return '60代以上';
    }
  }
}

/// 世帯年収区分（ベンチマーク比較の対象グループ選択に使用）
enum IncomeGroup { under3m, m3to5, m5to7, m7to10, over10m }

extension IncomeGroupInfo on IncomeGroup {
  String get displayName {
    switch (this) {
      case IncomeGroup.under3m:
        return '〜300万円';
      case IncomeGroup.m3to5:
        return '300万〜500万円';
      case IncomeGroup.m5to7:
        return '500万〜700万円';
      case IncomeGroup.m7to10:
        return '700万〜1,000万円';
      case IncomeGroup.over10m:
        return '1,000万円〜';
    }
  }
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

/// 貯蓄率・純資産など、支出カテゴリ以外の財務指標のベンチマーク
class FinancialIndicatorBenchmark {
  final String indicatorName; // 表示名（例: 貯蓄率、純資産）
  final double userValue;
  final double ageGroupAverage;
  final int ageGroupPercentile; // 上位何%かではなく「同世代内での順位」を0-100で表す
  final String unit; // %, 円 など

  const FinancialIndicatorBenchmark({
    required this.indicatorName,
    required this.userValue,
    required this.ageGroupAverage,
    required this.ageGroupPercentile,
    required this.unit,
  });

  bool get isAboveAverage => userValue > ageGroupAverage;
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

/// 匿名化された統計データ（教育目的の概算値）。
/// 総務省家計調査等で公表されている年代別の傾向を参考にした近似値であり、
/// リアルタイムの実データ集計ではない点に注意。
/// 実データ連携時は、5人以上のグループでのみ集計するなどプライバシーに配慮すること。
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

  /// 年代による支出傾向の補正係数（全国平均に対する倍率の目安）。
  /// 例: 住居費は30〜40代（子育て・住宅ローン期）でやや高め、
  /// 保険料は年齢とともに上昇する傾向、娯楽費は20代でやや高めなど。
  static const Map<AgeGroup, Map<BenchmarkCategory, double>> _ageGroupFactors = {
    AgeGroup.twenties: {
      BenchmarkCategory.food: 0.8,
      BenchmarkCategory.utility: 0.7,
      BenchmarkCategory.entertainment: 1.2,
      BenchmarkCategory.transport: 0.9,
      BenchmarkCategory.communication: 1.0,
      BenchmarkCategory.housing: 0.9,
      BenchmarkCategory.daily: 0.8,
      BenchmarkCategory.insurance: 0.5,
    },
    AgeGroup.thirties: {
      BenchmarkCategory.food: 1.0,
      BenchmarkCategory.utility: 0.9,
      BenchmarkCategory.entertainment: 1.0,
      BenchmarkCategory.transport: 1.0,
      BenchmarkCategory.communication: 1.0,
      BenchmarkCategory.housing: 1.2,
      BenchmarkCategory.daily: 1.0,
      BenchmarkCategory.insurance: 0.8,
    },
    AgeGroup.forties: {
      BenchmarkCategory.food: 1.15,
      BenchmarkCategory.utility: 1.05,
      BenchmarkCategory.entertainment: 0.95,
      BenchmarkCategory.transport: 1.1,
      BenchmarkCategory.communication: 1.0,
      BenchmarkCategory.housing: 1.15,
      BenchmarkCategory.daily: 1.1,
      BenchmarkCategory.insurance: 1.1,
    },
    AgeGroup.fifties: {
      BenchmarkCategory.food: 1.1,
      BenchmarkCategory.utility: 1.1,
      BenchmarkCategory.entertainment: 0.9,
      BenchmarkCategory.transport: 1.0,
      BenchmarkCategory.communication: 0.9,
      BenchmarkCategory.housing: 0.9,
      BenchmarkCategory.daily: 1.05,
      BenchmarkCategory.insurance: 1.3,
    },
    AgeGroup.sixtiesPlus: {
      BenchmarkCategory.food: 0.95,
      BenchmarkCategory.utility: 1.1,
      BenchmarkCategory.entertainment: 0.8,
      BenchmarkCategory.transport: 0.8,
      BenchmarkCategory.communication: 0.8,
      BenchmarkCategory.housing: 0.6,
      BenchmarkCategory.daily: 1.0,
      BenchmarkCategory.insurance: 1.2,
    },
  };

  /// 世帯年収による支出傾向の補正係数（全国平均に対する倍率の目安）。
  /// 年収が高いほど住居費・娯楽費・保険料が増える一方、
  /// 食費・光熱費・日用品費など生活必需的な支出の伸びは緩やかになる傾向を反映。
  static const Map<IncomeGroup, Map<BenchmarkCategory, double>> _incomeGroupFactors = {
    IncomeGroup.under3m: {
      BenchmarkCategory.food: 0.75,
      BenchmarkCategory.utility: 0.8,
      BenchmarkCategory.entertainment: 0.6,
      BenchmarkCategory.transport: 0.8,
      BenchmarkCategory.communication: 0.9,
      BenchmarkCategory.housing: 0.7,
      BenchmarkCategory.daily: 0.8,
      BenchmarkCategory.insurance: 0.6,
    },
    IncomeGroup.m3to5: {
      BenchmarkCategory.food: 0.9,
      BenchmarkCategory.utility: 0.9,
      BenchmarkCategory.entertainment: 0.85,
      BenchmarkCategory.transport: 0.9,
      BenchmarkCategory.communication: 0.95,
      BenchmarkCategory.housing: 0.9,
      BenchmarkCategory.daily: 0.9,
      BenchmarkCategory.insurance: 0.85,
    },
    IncomeGroup.m5to7: {
      BenchmarkCategory.food: 1.0,
      BenchmarkCategory.utility: 1.0,
      BenchmarkCategory.entertainment: 1.0,
      BenchmarkCategory.transport: 1.0,
      BenchmarkCategory.communication: 1.0,
      BenchmarkCategory.housing: 1.0,
      BenchmarkCategory.daily: 1.0,
      BenchmarkCategory.insurance: 1.0,
    },
    IncomeGroup.m7to10: {
      BenchmarkCategory.food: 1.15,
      BenchmarkCategory.utility: 1.1,
      BenchmarkCategory.entertainment: 1.3,
      BenchmarkCategory.transport: 1.15,
      BenchmarkCategory.communication: 1.05,
      BenchmarkCategory.housing: 1.3,
      BenchmarkCategory.daily: 1.1,
      BenchmarkCategory.insurance: 1.2,
    },
    IncomeGroup.over10m: {
      BenchmarkCategory.food: 1.35,
      BenchmarkCategory.utility: 1.25,
      BenchmarkCategory.entertainment: 1.7,
      BenchmarkCategory.transport: 1.4,
      BenchmarkCategory.communication: 1.1,
      BenchmarkCategory.housing: 1.7,
      BenchmarkCategory.daily: 1.25,
      BenchmarkCategory.insurance: 1.5,
    },
  };

  /// 年代による貯蓄率・純資産の目安（教育目的の近似値）
  static const Map<AgeGroup, double> savingsRateByAgeGroup = {
    AgeGroup.twenties: 20.0,
    AgeGroup.thirties: 20.0,
    AgeGroup.forties: 15.0,
    AgeGroup.fifties: 15.0,
    AgeGroup.sixtiesPlus: 10.0,
  };

  static const Map<AgeGroup, int> netWorthByAgeGroup = {
    AgeGroup.twenties: 2000000,
    AgeGroup.thirties: 5000000,
    AgeGroup.forties: 8000000,
    AgeGroup.fifties: 12000000,
    AgeGroup.sixtiesPlus: 18000000,
  };

  static int getNationalAverage(BenchmarkCategory category) {
    return nationalAverages[category] ?? 0;
  }

  /// 年代を考慮した平均支出額の目安
  static int getAgeGroupAverage(BenchmarkCategory category, AgeGroup ageGroup) {
    final base = getNationalAverage(category);
    final factor = _ageGroupFactors[ageGroup]?[category] ?? 1.0;
    return (base * factor).round();
  }

  /// 世帯年収を考慮した平均支出額の目安
  static int getIncomeGroupAverage(BenchmarkCategory category, IncomeGroup incomeGroup) {
    final base = getNationalAverage(category);
    final factor = _incomeGroupFactors[incomeGroup]?[category] ?? 1.0;
    return (base * factor).round();
  }

  /// ユーザーの値が同世代内でどのあたりに位置するかを0〜100のパーセンタイルで返す
  /// （平均を50とし、平均からの乖離をなだらかなロジスティック曲線で0〜100に変換）。
  /// 値が小さいほど良い指標（支出額など）を想定: 平均より少なければ50未満。
  static int calculatePercentileForLowerIsBetter(int userAmount, int average) {
    if (average <= 0) return 50;
    final ratio = userAmount / average;
    return _ratioToPercentile(ratio);
  }

  /// 値が大きいほど良い指標（貯蓄率・純資産など）用のパーセンタイル。
  /// calculatePercentileForLowerIsBetterと同様、返り値は「実際の値が同世代内で
  /// どの高さに位置するか」を表す（平均より高ければ50超）。「上位」表示への変換は
  /// 呼び出し側（UI）で100からこの値を引いて行う。
  static int calculatePercentileForHigherIsBetter(double userValue, double average) {
    if (average <= 0) return 50;
    final ratio = userValue / average;
    return _ratioToPercentile(ratio);
  }

  /// 平均に対する比率(ratio)を、なだらかなロジスティック曲線で
  /// 0〜100のパーセンタイル（比率が高いほど大きい値）に変換する。
  /// ratio=1.0（平均と同じ）のとき50になる。
  static int _ratioToPercentile(double ratio) {
    // ロジスティック関数: 1 / (1 + e^(-k*(ratio-1))) を 0-100 にスケール
    const k = 3.0;
    final x = -k * (ratio - 1.0);
    final logistic = 1 / (1 + math.exp(x));
    return (logistic * 100).round().clamp(1, 99);
  }

  @Deprecated('Use calculatePercentileForLowerIsBetter instead')
  static int calculatePercentile(int userAmount, BenchmarkCategory category) {
    final average = getNationalAverage(category);
    return calculatePercentileForLowerIsBetter(userAmount, average);
  }
}
