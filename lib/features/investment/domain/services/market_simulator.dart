import 'dart:math';
import '../models/investment.dart';

/// 教育目的の仮想市場データシミュレーター。
/// 実際の証券取引・実売買は一切行わない（金融庁ガイドライン準拠）。
/// 日付をシードにした決定論的な疑似変動モデルで、同じ日には同じ値を返す。
class MarketSimulator {
  static double getCurrentIndexValue(InvestmentType type, {DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    final baseValue = InvestmentTypeInfo.baseIndexValues[type]!;
    final annualGrowth = InvestmentTypeInfo.annualGrowthRate[type]!;

    // 基準日からの経過日数
    final epoch = DateTime(2026, 1, 1);
    final daysSinceEpoch = now.difference(epoch).inDays;
    final yearsElapsed = daysSinceEpoch / 365.0;

    // 長期トレンド（年利成長）
    final trendValue = baseValue * pow(1 + annualGrowth, yearsElapsed);

    // 日次疑似変動（シードは日付+銘柄種別で決定論的）
    final seed = daysSinceEpoch * 31 + type.index * 7919;
    final random = Random(seed);
    final dailyNoise = (random.nextDouble() - 0.5) * 0.04; // ±2%の変動

    return trendValue * (1 + dailyNoise);
  }

  static List<double> getHistorySeries(InvestmentType type,
      {int days = 30, DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    return List.generate(days, (i) {
      final date = now.subtract(Duration(days: days - 1 - i));
      return getCurrentIndexValue(type, asOf: date);
    });
  }
}
