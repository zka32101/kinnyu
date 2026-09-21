class InsuranceCoverageInput {
  final int monthlyLivingExpenseForFamily; // 遺族の毎月の生活費
  final int yearsNeeded; // 保障が必要な年数（末子独立までの年数など）
  final int oneTimeCosts; // 葬儀費用など一時的にかかる費用
  final int currentSavings; // 現在の金融資産（貯蓄・投資等）
  final int monthlySurvivorPension; // 遺族年金等の見込み月額
  final int spouseMonthlyIncome; // 配偶者の収入見込み月額

  const InsuranceCoverageInput({
    required this.monthlyLivingExpenseForFamily,
    required this.yearsNeeded,
    this.oneTimeCosts = 2000000,
    this.currentSavings = 0,
    this.monthlySurvivorPension = 0,
    this.spouseMonthlyIncome = 0,
  });
}

class InsuranceCoverageResult {
  final int totalLivingExpenseNeeded; // 必要な生活費総額
  final int totalIncomeExpected; // 遺族年金・配偶者収入の総見込み額
  final int requiredCoverage; // 必要保障額（不足分）

  const InsuranceCoverageResult({
    required this.totalLivingExpenseNeeded,
    required this.totalIncomeExpected,
    required this.requiredCoverage,
  });
}

/// 万一の場合に遺族の生活を支えるために必要な生命保険の保障額を試算する
/// （教育目的の概算計算）。
///
/// 必要保障額 = (生活費総額 + 一時費用) − (現在の金融資産 + 遺族年金等の総見込み額)
class InsuranceCoverageCalculator {
  static InsuranceCoverageResult calculate(InsuranceCoverageInput input) {
    final totalLivingExpenseNeeded =
        input.monthlyLivingExpenseForFamily * 12 * input.yearsNeeded +
            input.oneTimeCosts;

    final totalIncomeExpected =
        (input.monthlySurvivorPension + input.spouseMonthlyIncome) *
                12 *
                input.yearsNeeded +
            input.currentSavings;

    final requiredCoverage =
        (totalLivingExpenseNeeded - totalIncomeExpected).clamp(0, totalLivingExpenseNeeded);

    return InsuranceCoverageResult(
      totalLivingExpenseNeeded: totalLivingExpenseNeeded,
      totalIncomeExpected: totalIncomeExpected,
      requiredCoverage: requiredCoverage,
    );
  }
}
