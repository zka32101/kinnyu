import 'dart:math';

/// 積立複利シミュレーションの1年分のスナップショット
class CompoundYearResult {
  final int year;
  final int principal; // 累計元本（初期投資額＋積立額の合計）
  final double balance; // その年末時点の評価額
  final double realBalance; // 物価上昇分を割り引いた、現在の購買力での評価額
  double get profit => balance - principal;
  double get realProfit => realBalance - principal;

  CompoundYearResult({
    required this.year,
    required this.principal,
    required this.balance,
    required this.realBalance,
  });
}

/// ランダム変動シミュレーションの1年分のスナップショット。
/// 年ごとの実際の運用利回り（好況・不況の波）も保持する。
class RandomYearResult {
  final int year;
  final int principal;
  final double balance;
  final double realBalance; // 物価上昇分を割り引いた、現在の購買力での評価額
  final double annualReturnPercent; // その年に実際に適用された利回り
  double get profit => balance - principal;
  double get realProfit => realBalance - principal;

  RandomYearResult({
    required this.year,
    required this.principal,
    required this.balance,
    required this.realBalance,
    required this.annualReturnPercent,
  });
}

/// 教育目的の積立複利シミュレーター。
/// 月初に積立額を入れてから月利で運用するモデル（簡易近似）。
class CompoundSimulator {
  static List<CompoundYearResult> simulate({
    int initial = 0,
    required int monthlyContribution,
    required double annualRatePercent,
    required int years,
    double inflationRatePercent = 0.0,
  }) {
    assert(years > 0, 'years must be positive');
    final monthlyRate = annualRatePercent / 100 / 12;

    double balance = initial.toDouble();
    int principal = initial;
    final results = <CompoundYearResult>[];

    for (var year = 1; year <= years; year++) {
      for (var m = 0; m < 12; m++) {
        balance += monthlyContribution;
        principal += monthlyContribution;
        balance *= (1 + monthlyRate);
      }
      final inflationFactor = pow(1 + inflationRatePercent / 100, year);
      final realBalance = balance / inflationFactor;
      results.add(CompoundYearResult(
        year: year,
        principal: principal,
        balance: balance,
        realBalance: realBalance,
      ));
    }
    return results;
  }

  /// 教育目的の「リアル変動」シミュレーション。
  /// 毎年の利回りを平均値の周りでランダムに変動させ（正規分布に近い擬似乱数、
  /// Box-Muller法）、実際の市場のような好況・不況の波を再現する（簡易モンテカルロ）。
  /// 同じseedを渡せば同じ結果を再現でき、seedを変えれば異なる相場シナリオになる。
  static List<RandomYearResult> simulateRandom({
    int initial = 0,
    required int monthlyContribution,
    required double meanAnnualRatePercent,
    required double volatilityPercent,
    required int years,
    int? seed,
    double inflationRatePercent = 0.0,
  }) {
    assert(years > 0, 'years must be positive');
    final random = Random(seed);

    double balance = initial.toDouble();
    int principal = initial;
    final results = <RandomYearResult>[];

    for (var year = 1; year <= years; year++) {
      final annualReturn = _nextGaussianReturn(
        random,
        meanAnnualRatePercent,
        volatilityPercent,
      );
      final monthlyRate = annualReturn / 100 / 12;

      for (var m = 0; m < 12; m++) {
        balance += monthlyContribution;
        principal += monthlyContribution;
        balance *= (1 + monthlyRate);
      }
      if (balance < 0) balance = 0; // 理論上ほぼ発生しないが下限ガード

      final inflationFactor = pow(1 + inflationRatePercent / 100, year);
      final realBalance = balance / inflationFactor;

      results.add(RandomYearResult(
        year: year,
        principal: principal,
        balance: balance,
        realBalance: realBalance,
        annualReturnPercent: annualReturn,
      ));
    }
    return results;
  }

  /// Box-Muller法で正規分布に近い乱数を生成し、平均・標準偏差でスケールする。
  /// 現実離れした極端値を避けるため -60%〜+150% にクランプする。
  static double _nextGaussianReturn(Random random, double mean, double stdDev) {
    final u1 = max(random.nextDouble(), 1e-9);
    final u2 = random.nextDouble();
    final z = sqrt(-2 * log(u1)) * cos(2 * pi * u2);
    final value = mean + z * stdDev;
    return value.clamp(-60.0, 150.0);
  }
}
