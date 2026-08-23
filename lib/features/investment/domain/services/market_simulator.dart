import 'dart:math';
import '../models/investment.dart';

/// 教育目的の仮想市場データシミュレーター。
/// 実際の証券取引・実売買は一切行わない（金融庁ガイドライン準拠）。
/// 幾何ブラウン運動（GBM）による決定論的な疑似ランダムウォークモデルで、
/// 銘柄種別ごとの実際のボラティリティ（InvestmentTypeInfo.volatilityPercent）を
/// 反映する。同じ日付・銘柄には常に同じ値を返す。
class MarketSimulator {
  static final DateTime _epoch = DateTime(2026, 1, 1);
  static const int _tradingDaysPerYear = 252;

  static double getCurrentIndexValue(InvestmentType type, {DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    final daysSinceEpoch = now.difference(_epoch).inDays;
    final series = _walkRange(type, daysSinceEpoch, daysSinceEpoch);
    return series.first;
  }

  static List<double> getHistorySeries(InvestmentType type,
      {int days = 30, DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    final endDay = now.difference(_epoch).inDays;
    final startDay = endDay - days + 1;
    return _walkRange(type, startDay, endDay);
  }

  /// [fromDay, toDay]（基準日からの経過日数、両端含む）の範囲の価格を、
  /// 累積対数リターン（幾何ブラウン運動）で計算して返す（古い日付→新しい日付の順）。
  ///
  /// 銘柄種別ごとに固定シードの疑似乱数列を必ず先頭（1日目）から再生するため、
  /// 同じ (type, day) の組み合わせは常に同じ値になる決定論性を保つ。
  static List<double> _walkRange(InvestmentType type, int fromDay, int toDay) {
    final baseValue = InvestmentTypeInfo.baseIndexValues[type]!;

    if (toDay <= 0) {
      // 基準日（2026-01-01）以前は疑似変動データを持たないため、基準値を返す。
      final count = toDay - fromDay + 1;
      return List.filled(count > 0 ? count : 0, baseValue);
    }

    final annualGrowth = InvestmentTypeInfo.annualGrowthRate[type]!;
    final annualVol = InvestmentTypeInfo.volatilityPercent[type]! / 100;

    // 年率の想定リターン・ボラティリティを日次に換算（GBMの標準的な変換式）
    final dailyDrift = log(1 + annualGrowth) / _tradingDaysPerYear;
    final dailyVol = annualVol / sqrt(_tradingDaysPerYear);

    final random = Random(type.index * 104729 + 17);
    double cumulativeLogReturn = 0.0;
    final results = <double>[];
    final effectiveFromDay = fromDay < 1 ? 1 : fromDay;

    for (var d = 1; d <= toDay; d++) {
      final z = _nextStandardGaussian(random);
      cumulativeLogReturn += dailyDrift + dailyVol * z;
      if (d >= effectiveFromDay) {
        results.add(baseValue * exp(cumulativeLogReturn));
      }
    }

    if (fromDay < effectiveFromDay) {
      final padCount = effectiveFromDay - fromDay;
      results.insertAll(0, List.filled(padCount, baseValue));
    }
    return results;
  }

  /// Box-Muller法で標準正規分布 N(0,1) の乱数を1つ生成する。
  static double _nextStandardGaussian(Random random) {
    final u1 = max(random.nextDouble(), 1e-9);
    final u2 = random.nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }
}
