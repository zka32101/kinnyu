import 'compound_simulator.dart';

class HouseholdSimulationInput {
  final int monthlyIncome;
  final int monthlyExpense;
  final double investmentReturnPercent; // 0 = 貯金のみ（運用しない）
  final int years;

  const HouseholdSimulationInput({
    required this.monthlyIncome,
    required this.monthlyExpense,
    this.investmentReturnPercent = 0,
    required this.years,
  });
}

class HouseholdSimulationResult {
  final int monthlySavings; // 収入 - 支出（マイナスなら赤字）
  final double savingsRate; // 貯蓄率（収入に対する貯蓄額の割合）
  final bool isDeficit;
  final List<CompoundYearResult> projection;

  HouseholdSimulationResult({
    required this.monthlySavings,
    required this.savingsRate,
    required this.isDeficit,
    required this.projection,
  });
}

/// 詳細モード：年ごとに収入・支出を変えられる1年分の計画
class YearlyPlan {
  final int year; // 1始まり
  final int monthlyIncome;
  final int monthlyExpense;

  const YearlyPlan({
    required this.year,
    required this.monthlyIncome,
    required this.monthlyExpense,
  });

  int get monthlySavings => monthlyIncome - monthlyExpense;
  bool get isDeficit => monthlySavings < 0;

  YearlyPlan copyWith({int? monthlyIncome, int? monthlyExpense}) {
    return YearlyPlan(
      year: year,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyExpense: monthlyExpense ?? this.monthlyExpense,
    );
  }
}

/// 詳細モードの1年分の結果
class DetailedYearResult {
  final int year;
  final int monthlyIncome;
  final int monthlyExpense;
  final int monthlySavings;
  final bool isDeficit;
  final int principal; // 累計元本
  final double balance; // 評価額
  double get profit => balance - principal;

  DetailedYearResult({
    required this.year,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.monthlySavings,
    required this.isDeficit,
    required this.principal,
    required this.balance,
  });
}

/// 家計の収支から将来の資産形成をシミュレーションする（教育目的）。
class HouseholdSimulator {
  /// 簡易モード：収入・支出が全期間一定という前提で計算
  static HouseholdSimulationResult simulate(HouseholdSimulationInput input) {
    final monthlySavings = input.monthlyIncome - input.monthlyExpense;
    final isDeficit = monthlySavings < 0;
    final savingsRate = input.monthlyIncome > 0
        ? monthlySavings / input.monthlyIncome
        : 0.0;

    final projection = CompoundSimulator.simulate(
      monthlyContribution: isDeficit ? 0 : monthlySavings,
      annualRatePercent: input.investmentReturnPercent,
      years: input.years,
    );

    return HouseholdSimulationResult(
      monthlySavings: monthlySavings,
      savingsRate: savingsRate,
      isDeficit: isDeficit,
      projection: projection,
    );
  }

  /// 詳細モード：年ごとに異なる収入・支出を入力して計算
  /// （昇給・出産・住宅購入など、ライフイベントによる変化を反映できる）
  static List<DetailedYearResult> simulateDetailed({
    required List<YearlyPlan> plans,
    double investmentReturnPercent = 0,
  }) {
    assert(plans.isNotEmpty, 'plans must not be empty');
    final monthlyRate = investmentReturnPercent / 100 / 12;

    double balance = 0;
    int principal = 0;
    final results = <DetailedYearResult>[];

    for (final plan in plans) {
      final monthlySavings = plan.monthlySavings;
      final contribution = plan.isDeficit ? 0 : monthlySavings;

      for (var m = 0; m < 12; m++) {
        balance += contribution;
        principal += contribution;
        balance *= (1 + monthlyRate);
      }

      results.add(DetailedYearResult(
        year: plan.year,
        monthlyIncome: plan.monthlyIncome,
        monthlyExpense: plan.monthlyExpense,
        monthlySavings: monthlySavings,
        isDeficit: plan.isDeficit,
        principal: principal,
        balance: balance,
      ));
    }
    return results;
  }

  /// 簡易モードの入力から、詳細モード用の年度別プラン（全年同一値）を生成する。
  /// 簡易⇄詳細モードの切り替えや、Excel出力を共通化するために使う。
  static List<YearlyPlan> expandToYearlyPlans(HouseholdSimulationInput input) {
    return List.generate(
      input.years,
      (i) => YearlyPlan(
        year: i + 1,
        monthlyIncome: input.monthlyIncome,
        monthlyExpense: input.monthlyExpense,
      ),
    );
  }
}
