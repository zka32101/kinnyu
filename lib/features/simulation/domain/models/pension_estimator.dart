/// 勤務先の規模（退職金の目安算定に使用）
enum CompanySize { large, medium, small, selfEmployed }

extension CompanySizeInfo on CompanySize {
  String get displayName {
    switch (this) {
      case CompanySize.large:
        return '大企業（1000人以上）';
      case CompanySize.medium:
        return '中小企業';
      case CompanySize.small:
        return '小規模事業者';
      case CompanySize.selfEmployed:
        return '自営業・フリーランス';
    }
  }

  /// 退職金概算に用いる、月給に対する支給率の目安（企業規模による近似値）
  double get retirementLumpSumFactor {
    switch (this) {
      case CompanySize.large:
        return 2.0;
      case CompanySize.medium:
        return 1.5;
      case CompanySize.small:
        return 1.0;
      case CompanySize.selfEmployed:
        return 0.0;
    }
  }
}

class PensionEstimatorInput {
  final int currentAge;
  final int retirementAge;
  final int averageAnnualIncome; // 平均額面年収（厚生年金保険料算定の目安として使用）
  final int pensionEnrollmentYears; // 厚生年金の加入予定年数（通算）
  final CompanySize companySize;
  final int yearsOfService; // 勤続年数（退職金算定用）
  final int currentRetirementSavings; // 既に準備している老後資金

  const PensionEstimatorInput({
    required this.currentAge,
    this.retirementAge = 65,
    required this.averageAnnualIncome,
    required this.pensionEnrollmentYears,
    required this.companySize,
    required this.yearsOfService,
    this.currentRetirementSavings = 0,
  });
}

class PensionEstimatorResult {
  final int annualBasicPension; // 老齢基礎年金（国民年金）年額
  final int annualEmployeePension; // 老齢厚生年金 年額
  final int annualTotalPension; // 合計年額
  final int monthlyTotalPension; // 合計月額
  final int estimatedRetirementLumpSum; // 退職金概算
  final int totalRetirementFunds; // 退職金 + 既存の老後資金準備額

  const PensionEstimatorResult({
    required this.annualBasicPension,
    required this.annualEmployeePension,
    required this.annualTotalPension,
    required this.monthlyTotalPension,
    required this.estimatedRetirementLumpSum,
    required this.totalRetirementFunds,
  });
}

/// 年金受給見込み額・退職金の概算を試算する（教育目的の近似計算）。
///
/// 老齢基礎年金は2024年度の満額（40年間納付の場合）を基準に、老齢厚生年金は
/// 2003年4月以降の報酬比例部分の簡易乗率（5.481/1000）を通算加入期間全体に
/// 適用した概算とする。実際の受給額は納付実績・標準報酬月額の推移等により異なる。
class PensionEstimator {
  static const int _fullBasicPensionAnnual = 816000; // 満額（40年=480ヶ月納付時）
  static const int _fullBasicPensionMonths = 480;
  static const double _employeePensionRate = 5.481 / 1000;

  static PensionEstimatorResult calculate(PensionEstimatorInput input) {
    final enrollmentMonths = input.pensionEnrollmentYears * 12;

    final basicPensionMonths = enrollmentMonths.clamp(0, _fullBasicPensionMonths);
    final annualBasicPension =
        (_fullBasicPensionAnnual * basicPensionMonths / _fullBasicPensionMonths).round();

    final avgMonthlyIncome = input.averageAnnualIncome / 12;
    final annualEmployeePension = input.companySize == CompanySize.selfEmployed
        ? 0
        : (avgMonthlyIncome * _employeePensionRate * enrollmentMonths).round();

    final annualTotalPension = annualBasicPension + annualEmployeePension;
    final monthlyTotalPension = (annualTotalPension / 12).round();

    final monthlySalary = input.averageAnnualIncome / 12;
    final estimatedRetirementLumpSum = input.companySize == CompanySize.selfEmployed
        ? 0
        : (monthlySalary * input.yearsOfService * input.companySize.retirementLumpSumFactor)
            .round();

    final totalRetirementFunds =
        estimatedRetirementLumpSum + input.currentRetirementSavings;

    return PensionEstimatorResult(
      annualBasicPension: annualBasicPension,
      annualEmployeePension: annualEmployeePension,
      annualTotalPension: annualTotalPension,
      monthlyTotalPension: monthlyTotalPension,
      estimatedRetirementLumpSum: estimatedRetirementLumpSum,
      totalRetirementFunds: totalRetirementFunds,
    );
  }
}
