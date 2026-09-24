/// iDeCoの掛金上限は加入区分によって異なる
enum IdecoOccupationType {
  selfEmployed, // 自営業者等（第1号被保険者）
  employeeNoPension, // 会社員（企業年金なし）
  employeeWithDc, // 会社員（企業型DCのみ加入）
  employeeWithDb, // 会社員（DB・企業型DC併用等）
  publicServant, // 公務員等
  dependentSpouse, // 専業主婦(夫)（第3号被保険者）
}

extension IdecoOccupationTypeInfo on IdecoOccupationType {
  String get displayName {
    switch (this) {
      case IdecoOccupationType.selfEmployed:
        return '自営業者等';
      case IdecoOccupationType.employeeNoPension:
        return '会社員（企業年金なし）';
      case IdecoOccupationType.employeeWithDc:
        return '会社員（企業型DCのみ）';
      case IdecoOccupationType.employeeWithDb:
        return '会社員（DB等併用）';
      case IdecoOccupationType.publicServant:
        return '公務員等';
      case IdecoOccupationType.dependentSpouse:
        return '専業主婦(夫)';
    }
  }

  /// 月額拠出限度額（2024年度時点の目安）
  int get monthlyLimit {
    switch (this) {
      case IdecoOccupationType.selfEmployed:
        return 68000;
      case IdecoOccupationType.employeeNoPension:
        return 23000;
      case IdecoOccupationType.employeeWithDc:
        return 20000;
      case IdecoOccupationType.employeeWithDb:
        return 12000;
      case IdecoOccupationType.publicServant:
        return 12000;
      case IdecoOccupationType.dependentSpouse:
        return 23000;
    }
  }
}

class NisaInput {
  final int tsumitateInvestedThisYear; // つみたて投資枠の今年の投資済み額
  final int growthInvestedThisYear; // 成長投資枠の今年の投資済み額
  final int lifetimeInvestedTotal; // 生涯投資枠の累計投資済み額

  const NisaInput({
    this.tsumitateInvestedThisYear = 0,
    this.growthInvestedThisYear = 0,
    this.lifetimeInvestedTotal = 0,
  });

  static const int tsumitateAnnualLimit = 1200000; // つみたて投資枠：年120万円
  static const int growthAnnualLimit = 2400000; // 成長投資枠：年240万円
  static const int lifetimeLimit = 18000000; // 生涯投資枠：合計1,800万円
}

class NisaResult {
  final int tsumitateRemaining;
  final int growthRemaining;
  final int annualRemaining;
  final int lifetimeRemaining;

  const NisaResult({
    required this.tsumitateRemaining,
    required this.growthRemaining,
    required this.annualRemaining,
    required this.lifetimeRemaining,
  });
}

class IdecoInput {
  final IdecoOccupationType occupationType;
  final int monthlyContribution;
  final double assumedTaxRatePercent; // 所得税+住民税の概算合計税率

  const IdecoInput({
    required this.occupationType,
    required this.monthlyContribution,
    this.assumedTaxRatePercent = 20.0,
  });
}

class IdecoResult {
  final int monthlyLimit;
  final int monthlyRemaining;
  final int annualContribution;
  final int estimatedAnnualTaxSaving; // 掛金全額所得控除による概算節税額

  const IdecoResult({
    required this.monthlyLimit,
    required this.monthlyRemaining,
    required this.annualContribution,
    required this.estimatedAnnualTaxSaving,
  });
}

/// NISA・iDeCoの非課税投資枠の消化状況と節税効果を試算する（教育目的）。
class NisaIdecoCalculator {
  static NisaResult calculateNisa(NisaInput input) {
    final tsumitateRemaining =
        (NisaInput.tsumitateAnnualLimit - input.tsumitateInvestedThisYear)
            .clamp(0, NisaInput.tsumitateAnnualLimit);
    final growthRemaining =
        (NisaInput.growthAnnualLimit - input.growthInvestedThisYear)
            .clamp(0, NisaInput.growthAnnualLimit);
    final lifetimeRemaining =
        (NisaInput.lifetimeLimit - input.lifetimeInvestedTotal)
            .clamp(0, NisaInput.lifetimeLimit);

    return NisaResult(
      tsumitateRemaining: tsumitateRemaining,
      growthRemaining: growthRemaining,
      annualRemaining: tsumitateRemaining + growthRemaining,
      lifetimeRemaining: lifetimeRemaining,
    );
  }

  static IdecoResult calculateIdeco(IdecoInput input) {
    final monthlyLimit = input.occupationType.monthlyLimit;
    final monthlyRemaining =
        (monthlyLimit - input.monthlyContribution).clamp(0, monthlyLimit);
    final annualContribution = input.monthlyContribution * 12;
    final estimatedAnnualTaxSaving =
        (annualContribution * input.assumedTaxRatePercent / 100).round();

    return IdecoResult(
      monthlyLimit: monthlyLimit,
      monthlyRemaining: monthlyRemaining,
      annualContribution: annualContribution,
      estimatedAnnualTaxSaving: estimatedAnnualTaxSaving,
    );
  }
}

/// 積立投資の複利成長シミュレーション結果（1年ごとのポイント）
class CompoundGrowthPoint {
  final int year;
  final int cumulativePrincipal; // 累計元本
  final int estimatedValue; // 運用益を含めた評価額（概算）

  const CompoundGrowthPoint({
    required this.year,
    required this.cumulativePrincipal,
    required this.estimatedValue,
  });
}

/// NISA・iDeCoなど、毎年一定額を積み立てた場合の複利成長を試算する（教育目的の概算）。
/// 年1回・年初に積立額全体を投資し、年率リターンで複利運用されると仮定する簡易モデル。
class CompoundGrowthSimulator {
  static List<CompoundGrowthPoint> simulate({
    required int annualContribution,
    required double annualReturnRatePercent,
    required int years,
  }) {
    final points = <CompoundGrowthPoint>[];
    var cumulativePrincipal = 0;
    var value = 0.0;

    for (var y = 1; y <= years; y++) {
      value = (value + annualContribution) * (1 + annualReturnRatePercent / 100);
      cumulativePrincipal += annualContribution;
      points.add(CompoundGrowthPoint(
        year: y,
        cumulativePrincipal: cumulativePrincipal,
        estimatedValue: value.round(),
      ));
    }

    return points;
  }
}
