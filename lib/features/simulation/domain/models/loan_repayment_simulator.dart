/// 返済方式
enum RepaymentType {
  /// 元利均等返済：毎月の返済額（元金+利息）が一定
  equalPayment,

  /// 元金均等返済：毎月の元金部分が一定（返済額は徐々に減っていく）
  equalPrincipal,
}

class LoanRepaymentInput {
  final int principal; // 借入元金
  final double annualInterestRatePercent; // 年利（%）
  final int years; // 返済期間（年）
  final RepaymentType repaymentType;

  const LoanRepaymentInput({
    required this.principal,
    required this.annualInterestRatePercent,
    required this.years,
    this.repaymentType = RepaymentType.equalPayment,
  });

  int get totalMonths => years * 12;
}

/// 1ヶ月分の返済内訳
class LoanRepaymentMonthResult {
  final int month; // 1始まり
  final int payment; // その月の返済額（元金+利息）
  final int principalPaid; // うち元金
  final int interestPaid; // うち利息
  final int remainingBalance; // 返済後の残高

  const LoanRepaymentMonthResult({
    required this.month,
    required this.payment,
    required this.principalPaid,
    required this.interestPaid,
    required this.remainingBalance,
  });
}

/// 1年分の返済内訳（月次結果の集計）
class LoanRepaymentYearResult {
  final int year; // 1始まり
  final int totalPayment;
  final int totalPrincipal;
  final int totalInterest;
  final int remainingBalance; // その年末時点の残高

  const LoanRepaymentYearResult({
    required this.year,
    required this.totalPayment,
    required this.totalPrincipal,
    required this.totalInterest,
    required this.remainingBalance,
  });
}

class LoanRepaymentResult {
  final List<LoanRepaymentMonthResult> months;
  final List<LoanRepaymentYearResult> years;

  const LoanRepaymentResult({
    required this.months,
    required this.years,
  });

  int get totalPayment => months.fold(0, (sum, m) => sum + m.payment);
  int get totalInterest => months.fold(0, (sum, m) => sum + m.interestPaid);
  int get totalPrincipal => months.fold(0, (sum, m) => sum + m.principalPaid);

  /// 元利均等返済の場合は全期間一定。元金均等返済の場合は初回の返済額。
  int get firstMonthPayment => months.isNotEmpty ? months.first.payment : 0;

  /// 元金均等返済の場合の最終回の返済額（元利均等では同じ値になる）
  int get lastMonthPayment => months.isNotEmpty ? months.last.payment : 0;
}

/// 借入金（住宅ローン・自動車ローン・奨学金など）の返済計画をシミュレーションする
/// （教育目的）。
class LoanRepaymentSimulator {
  static LoanRepaymentResult simulate(LoanRepaymentInput input) {
    switch (input.repaymentType) {
      case RepaymentType.equalPayment:
        return _simulateEqualPayment(input);
      case RepaymentType.equalPrincipal:
        return _simulateEqualPrincipal(input);
    }
  }

  static LoanRepaymentResult _simulateEqualPayment(LoanRepaymentInput input) {
    final totalMonths = input.totalMonths;
    final monthlyRate = input.annualInterestRatePercent / 100 / 12;

    final int monthlyPayment;
    if (monthlyRate == 0) {
      monthlyPayment = (input.principal / totalMonths).round();
    } else {
      final factor = _pow(1 + monthlyRate, totalMonths);
      monthlyPayment =
          (input.principal * monthlyRate * factor / (factor - 1)).round();
    }

    final months = <LoanRepaymentMonthResult>[];
    double remaining = input.principal.toDouble();

    for (var m = 1; m <= totalMonths; m++) {
      final interestPaid = (remaining * monthlyRate).round();
      // 最終回は端数調整のため、残高をそのまま元金充当分にする
      final isLastMonth = m == totalMonths;
      final rawPrincipalPaid = monthlyPayment - interestPaid;
      final principalPaid =
          isLastMonth ? remaining.round() : rawPrincipalPaid.clamp(0, remaining.round());
      final payment = isLastMonth ? principalPaid + interestPaid : monthlyPayment;

      remaining = (remaining - principalPaid).clamp(0, double.infinity);

      months.add(LoanRepaymentMonthResult(
        month: m,
        payment: payment,
        principalPaid: principalPaid,
        interestPaid: interestPaid,
        remainingBalance: remaining.round(),
      ));
    }

    return LoanRepaymentResult(
      months: months,
      years: _aggregateByYear(months),
    );
  }

  static LoanRepaymentResult _simulateEqualPrincipal(LoanRepaymentInput input) {
    final totalMonths = input.totalMonths;
    final monthlyRate = input.annualInterestRatePercent / 100 / 12;
    final principalPerMonth = (input.principal / totalMonths).round();

    final months = <LoanRepaymentMonthResult>[];
    double remaining = input.principal.toDouble();

    for (var m = 1; m <= totalMonths; m++) {
      final isLastMonth = m == totalMonths;
      final principalPaid = isLastMonth ? remaining.round() : principalPerMonth;
      final interestPaid = (remaining * monthlyRate).round();
      final payment = principalPaid + interestPaid;

      remaining = (remaining - principalPaid).clamp(0, double.infinity);

      months.add(LoanRepaymentMonthResult(
        month: m,
        payment: payment,
        principalPaid: principalPaid,
        interestPaid: interestPaid,
        remainingBalance: remaining.round(),
      ));
    }

    return LoanRepaymentResult(
      months: months,
      years: _aggregateByYear(months),
    );
  }

  static List<LoanRepaymentYearResult> _aggregateByYear(
    List<LoanRepaymentMonthResult> months,
  ) {
    final years = <LoanRepaymentYearResult>[];
    for (var i = 0; i < months.length; i += 12) {
      final yearMonths = months.skip(i).take(12).toList();
      if (yearMonths.isEmpty) continue;
      years.add(LoanRepaymentYearResult(
        year: (i ~/ 12) + 1,
        totalPayment: yearMonths.fold(0, (sum, m) => sum + m.payment),
        totalPrincipal: yearMonths.fold(0, (sum, m) => sum + m.principalPaid),
        totalInterest: yearMonths.fold(0, (sum, m) => sum + m.interestPaid),
        remainingBalance: yearMonths.last.remainingBalance,
      ));
    }
    return years;
  }

  static double _pow(double base, int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}
