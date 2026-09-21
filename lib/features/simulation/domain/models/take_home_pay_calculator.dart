/// 給与所得者の額面年収から手取り額を試算するための入力。
class TakeHomePayInput {
  final int grossAnnualIncome; // 額面年収
  final bool isOver40; // 40歳以上（介護保険料が発生）
  final int dependents; // 扶養親族の数（扶養控除: 1人あたり38万円で概算）

  const TakeHomePayInput({
    required this.grossAnnualIncome,
    this.isOver40 = false,
    this.dependents = 0,
  });
}

/// 社会保険料の内訳（年額）
class SocialInsurancePremiums {
  final int healthInsurance; // 健康保険料（労使折半・従業員負担分）
  final int longTermCareInsurance; // 介護保険料（40歳以上のみ）
  final int pensionInsurance; // 厚生年金保険料（労使折半・従業員負担分）
  final int employmentInsurance; // 雇用保険料

  const SocialInsurancePremiums({
    required this.healthInsurance,
    required this.longTermCareInsurance,
    required this.pensionInsurance,
    required this.employmentInsurance,
  });

  int get total =>
      healthInsurance + longTermCareInsurance + pensionInsurance + employmentInsurance;
}

class TakeHomePayResult {
  final int grossAnnualIncome;
  final SocialInsurancePremiums socialInsurance;
  final int employmentIncomeDeduction; // 給与所得控除
  final int employmentIncome; // 給与所得（額面 - 給与所得控除）
  final int basicDeduction; // 基礎控除
  final int dependentDeduction; // 扶養控除
  final int taxableIncomeForIncomeTax; // 所得税の課税所得
  final int incomeTax; // 所得税（復興特別所得税込み）
  final int taxableIncomeForResidentTax; // 住民税の課税所得
  final int residentTax; // 住民税（所得割+均等割の概算）

  const TakeHomePayResult({
    required this.grossAnnualIncome,
    required this.socialInsurance,
    required this.employmentIncomeDeduction,
    required this.employmentIncome,
    required this.basicDeduction,
    required this.dependentDeduction,
    required this.taxableIncomeForIncomeTax,
    required this.incomeTax,
    required this.taxableIncomeForResidentTax,
    required this.residentTax,
  });

  int get totalDeductions => socialInsurance.total + incomeTax + residentTax;
  int get takeHomeAnnual => grossAnnualIncome - totalDeductions;
  int get takeHomeMonthly => (takeHomeAnnual / 12).round();
  double get takeHomeRate =>
      grossAnnualIncome > 0 ? takeHomeAnnual / grossAnnualIncome : 0.0;
}

/// 給与所得者の額面年収から手取り額を試算する（教育目的の概算計算）。
///
/// 社会保険料率・税率は制度改正や自治体・健康保険組合により変動するため、
/// ここでは協会けんぽ（東京都）の目安料率と国税庁の所得税速算表（令和6年分）を
/// 用いた概算とする。実際の手取り額は勤務先の給与規程や居住地によって異なる。
class TakeHomePayCalculator {
  // --- 社会保険料率（2024年度・協会けんぽ東京都の目安、従業員負担分） ---
  static const double _healthInsuranceRate = 0.0499; // 健康保険料率（労使折半後）
  static const double _longTermCareInsuranceRate = 0.0080; // 介護保険料率（40歳以上）
  static const double _pensionInsuranceRate = 0.0915; // 厚生年金保険料率（労使折半後）
  static const double _employmentInsuranceRate = 0.006; // 雇用保険料率（一般の事業）

  // 厚生年金保険料の算定基礎となる標準報酬月額の上限（65万円/月 = 年780万円相当）
  static const int _pensionableIncomeCap = 7800000;

  static const int _basicDeductionAmount = 480000; // 基礎控除（合計所得2,400万円以下）
  static const int _dependentDeductionPerPerson = 380000; // 扶養控除（1人あたり概算）

  // 住民税の基礎控除（所得税より少し低い）
  static const int _residentTaxBasicDeduction = 430000;
  static const int _residentTaxDependentDeductionPerPerson = 330000;
  static const double _residentTaxRate = 0.10; // 住民税所得割（標準税率10%）
  static const int _residentTaxPerCapita = 5000; // 住民税均等割の概算（自治体により変動）

  static TakeHomePayResult calculate(TakeHomePayInput input) {
    final gross = input.grossAnnualIncome;

    final socialInsurance = _calculateSocialInsurance(gross, input.isOver40);

    final employmentIncomeDeduction = _employmentIncomeDeduction(gross);
    final employmentIncome =
        (gross - employmentIncomeDeduction).clamp(0, gross);

    final dependentDeduction =
        input.dependents * _dependentDeductionPerPerson;

    // --- 所得税 ---
    final taxableForIncomeTax = (employmentIncome -
            _basicDeductionAmount -
            dependentDeduction -
            socialInsurance.total)
        .clamp(0, employmentIncome);
    final incomeTax = _calculateIncomeTax(taxableForIncomeTax);

    // --- 住民税（概算） ---
    final residentDependentDeduction =
        input.dependents * _residentTaxDependentDeductionPerPerson;
    final taxableForResidentTax = (employmentIncome -
            _residentTaxBasicDeduction -
            residentDependentDeduction -
            socialInsurance.total)
        .clamp(0, employmentIncome);
    final residentTax = taxableForResidentTax > 0
        ? (taxableForResidentTax * _residentTaxRate).round() +
            _residentTaxPerCapita
        : 0;

    return TakeHomePayResult(
      grossAnnualIncome: gross,
      socialInsurance: socialInsurance,
      employmentIncomeDeduction: employmentIncomeDeduction,
      employmentIncome: employmentIncome,
      basicDeduction: _basicDeductionAmount,
      dependentDeduction: dependentDeduction,
      taxableIncomeForIncomeTax: taxableForIncomeTax,
      incomeTax: incomeTax,
      taxableIncomeForResidentTax: taxableForResidentTax,
      residentTax: residentTax,
    );
  }

  static SocialInsurancePremiums _calculateSocialInsurance(
    int grossAnnualIncome,
    bool isOver40,
  ) {
    final pensionableIncome =
        grossAnnualIncome.clamp(0, _pensionableIncomeCap);

    return SocialInsurancePremiums(
      healthInsurance: (grossAnnualIncome * _healthInsuranceRate).round(),
      longTermCareInsurance: isOver40
          ? (grossAnnualIncome * _longTermCareInsuranceRate).round()
          : 0,
      pensionInsurance: (pensionableIncome * _pensionInsuranceRate).round(),
      employmentInsurance:
          (grossAnnualIncome * _employmentInsuranceRate).round(),
    );
  }

  /// 給与所得控除（令和2年分以降の速算表）
  static int _employmentIncomeDeduction(int grossAnnualIncome) {
    final g = grossAnnualIncome;
    if (g <= 1625000) return 550000;
    if (g <= 1800000) return (g * 0.4 - 100000).round();
    if (g <= 3600000) return (g * 0.3 + 80000).round();
    if (g <= 6600000) return (g * 0.2 + 440000).round();
    if (g <= 8500000) return (g * 0.1 + 1100000).round();
    return 1950000; // 850万円超は上限一律195万円
  }

  /// 所得税額（復興特別所得税2.1%を含む）を、国税庁の速算表に基づいて計算する。
  static int _calculateIncomeTax(int taxableIncome) {
    final t = taxableIncome;
    double rate;
    int deduction;

    if (t <= 1949000) {
      rate = 0.05;
      deduction = 0;
    } else if (t <= 3299000) {
      rate = 0.10;
      deduction = 97500;
    } else if (t <= 6949000) {
      rate = 0.20;
      deduction = 427500;
    } else if (t <= 8999000) {
      rate = 0.23;
      deduction = 636000;
    } else if (t <= 17999000) {
      rate = 0.33;
      deduction = 1536000;
    } else if (t <= 39999000) {
      rate = 0.40;
      deduction = 2796000;
    } else {
      rate = 0.45;
      deduction = 4796000;
    }

    final baseIncomeTax = (t * rate - deduction).clamp(0, double.infinity);
    // 復興特別所得税：基準所得税額の2.1%
    final reconstructionTax = baseIncomeTax * 0.021;
    return (baseIncomeTax + reconstructionTax).round();
  }
}
