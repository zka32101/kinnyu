import 'take_home_pay_calculator.dart';

class FurusatoNozeiInput {
  final int grossAnnualIncome;
  final bool isOver40;
  final int dependents;

  const FurusatoNozeiInput({
    required this.grossAnnualIncome,
    this.isOver40 = false,
    this.dependents = 0,
  });
}

class FurusatoNozeiResult {
  final int residentTaxIncomeLevy; // 住民税所得割額（概算）
  final double marginalIncomeTaxRate; // 適用される所得税の限界税率
  final int donationLimit; // 控除上限額（実質負担2,000円で寄付できる上限）

  const FurusatoNozeiResult({
    required this.residentTaxIncomeLevy,
    required this.marginalIncomeTaxRate,
    required this.donationLimit,
  });
}

/// ふるさと納税の（ワンストップ特例・確定申告共通の）控除上限額を試算する
/// （教育目的の概算計算）。
///
/// 総務省が公表する近似式を用いる:
///   控除上限額 ≒ 住民税所得割額 × 20% ÷ (90% − 所得税率 × 1.021) + 2,000円
/// 実際の上限額はふるさと納税ポータルサイトの詳細シミュレーターや
/// 自治体の案内でご確認ください。
class FurusatoNozeiCalculator {
  static FurusatoNozeiResult calculate(FurusatoNozeiInput input) {
    final payResult = TakeHomePayCalculator.calculate(
      TakeHomePayInput(
        grossAnnualIncome: input.grossAnnualIncome,
        isOver40: input.isOver40,
        dependents: input.dependents,
      ),
    );

    // 住民税所得割額（均等割を除いた所得割部分のみ）
    const residentTaxRate = 0.10;
    final residentTaxIncomeLevy =
        (payResult.taxableIncomeForResidentTax * residentTaxRate).round();

    final marginalRate =
        _marginalIncomeTaxRate(payResult.taxableIncomeForIncomeTax);

    final denominator = 0.90 - (marginalRate * 1.021);
    final donationLimit = denominator > 0
        ? ((residentTaxIncomeLevy * 0.20) / denominator + 2000).round()
        : 2000;

    return FurusatoNozeiResult(
      residentTaxIncomeLevy: residentTaxIncomeLevy,
      marginalIncomeTaxRate: marginalRate,
      donationLimit: donationLimit,
    );
  }

  /// 所得税の限界税率（速算表の税率をそのまま使用、復興特別所得税は式側で加味）
  static double _marginalIncomeTaxRate(int taxableIncome) {
    final t = taxableIncome;
    if (t <= 1949000) return 0.05;
    if (t <= 3299000) return 0.10;
    if (t <= 6949000) return 0.20;
    if (t <= 8999000) return 0.23;
    if (t <= 17999000) return 0.33;
    if (t <= 39999000) return 0.40;
    return 0.45;
  }
}
