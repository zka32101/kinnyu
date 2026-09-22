import 'loan_repayment_simulator.dart';

/// 住宅購入 vs 賃貸の比較シミュレーション入力。
class RentVsBuyInput {
  final int monthlyRent; // 現在の家賃（月額）
  final double annualRentIncreaseRatePercent; // 家賃の年間上昇率（%）
  final int purchasePrice; // 物件価格
  final int downPayment; // 頭金
  final double loanInterestRatePercent; // 住宅ローン金利（年率%）
  final int loanYears; // 住宅ローン返済期間（年）
  final int annualPropertyTax; // 固定資産税・都市計画税（年額）
  final int annualMaintenanceCost; // 管理費・修繕積立金・維持費（年額）
  final int comparisonYears; // 比較する年数

  const RentVsBuyInput({
    required this.monthlyRent,
    this.annualRentIncreaseRatePercent = 0.0,
    required this.purchasePrice,
    required this.downPayment,
    required this.loanInterestRatePercent,
    required this.loanYears,
    this.annualPropertyTax = 0,
    this.annualMaintenanceCost = 0,
    required this.comparisonYears,
  });
}

class RentVsBuyYearResult {
  final int year;
  final int cumulativeRentCost;
  final int cumulativeBuyCost;

  const RentVsBuyYearResult({
    required this.year,
    required this.cumulativeRentCost,
    required this.cumulativeBuyCost,
  });
}

class RentVsBuyResult {
  final List<RentVsBuyYearResult> years;
  final int finalRentCost; // 比較期間終了時点の賃貸累計コスト
  final int finalBuyCost; // 比較期間終了時点の購入累計コスト（頭金・ローン返済・税・維持費）
  final int? breakEvenYear; // 購入コストが賃貸コストを下回り始める最初の年（期間内に無ければnull）
  final int remainingLoanBalance; // 比較期間終了時点のローン残高
  final int totalInterestPaid; // ローン完済までの総利息

  const RentVsBuyResult({
    required this.years,
    required this.finalRentCost,
    required this.finalBuyCost,
    required this.breakEvenYear,
    required this.remainingLoanBalance,
    required this.totalInterestPaid,
  });
}

/// 住宅購入と賃貸のキャッシュアウトを比較するシミュレーター（教育目的の概算）。
/// 購入した場合に手元に残る不動産という資産の価値（値上がり・値下がり）は
/// 考慮せず、あくまで支払い総額の比較である点に注意。
class RentVsBuyCalculator {
  static RentVsBuyResult calculate(RentVsBuyInput input) {
    final loanPrincipal =
        (input.purchasePrice - input.downPayment).clamp(0, input.purchasePrice);
    final loanResult = LoanRepaymentSimulator.simulate(LoanRepaymentInput(
      principal: loanPrincipal,
      annualInterestRatePercent: input.loanInterestRatePercent,
      years: input.loanYears,
    ));

    final years = <RentVsBuyYearResult>[];
    var cumulativeRent = 0;
    var cumulativeBuy = input.downPayment;
    int? breakEvenYear;
    var currentMonthlyRent = input.monthlyRent.toDouble();

    for (var y = 1; y <= input.comparisonYears; y++) {
      final annualRent = (currentMonthlyRent * 12).round();
      cumulativeRent += annualRent;
      currentMonthlyRent *= (1 + input.annualRentIncreaseRatePercent / 100);

      final loanPaymentThisYear =
          y <= loanResult.years.length ? loanResult.years[y - 1].totalPayment : 0;
      cumulativeBuy +=
          loanPaymentThisYear + input.annualPropertyTax + input.annualMaintenanceCost;

      years.add(RentVsBuyYearResult(
        year: y,
        cumulativeRentCost: cumulativeRent,
        cumulativeBuyCost: cumulativeBuy,
      ));

      breakEvenYear ??= cumulativeBuy <= cumulativeRent ? y : null;
    }

    final remainingBalance = input.comparisonYears < input.loanYears
        ? loanResult.years[input.comparisonYears - 1].remainingBalance
        : 0;

    return RentVsBuyResult(
      years: years,
      finalRentCost: cumulativeRent,
      finalBuyCost: cumulativeBuy,
      breakEvenYear: breakEvenYear,
      remainingLoanBalance: remainingBalance,
      totalInterestPaid: loanResult.totalInterest,
    );
  }
}
