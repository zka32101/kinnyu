/// 世帯バランスシート - 資産・負債・純資産を記録
class HouseholdBalanceSheet {
  final String groupId;
  final DateTime asOfDate;

  // 資産
  final int savingsAccount;      // 貯金口座
  final int checkingAccount;     // 当座預金
  final int investmentsValue;    // 投資資産現在価値
  final int otherAssets;         // その他資産

  // 負債
  final int shortTermDebt;       // 短期債務
  final int longTermDebt;        // 長期債務
  final int otherLiabilities;    // その他負債

  // 月間サマリー
  final int monthlyIncome;       // 月間収入
  final int monthlyExpense;      // 月間支出

  const HouseholdBalanceSheet({
    required this.groupId,
    required this.asOfDate,
    required this.savingsAccount,
    required this.checkingAccount,
    required this.investmentsValue,
    required this.otherAssets,
    required this.shortTermDebt,
    required this.longTermDebt,
    required this.otherLiabilities,
    required this.monthlyIncome,
    required this.monthlyExpense,
  });

  /// 総資産
  int get totalAssets =>
      savingsAccount + checkingAccount + investmentsValue + otherAssets;

  /// 総負債
  int get totalLiabilities =>
      shortTermDebt + longTermDebt + otherLiabilities;

  /// 純資産 (資産 - 負債)
  int get netWorth => totalAssets - totalLiabilities;

  /// 月間貯蓄 (収入 - 支出)
  int get monthlySavings => monthlyIncome - monthlyExpense;

  /// 貯蓄率 (%)
  double get savingsRate =>
      monthlyIncome > 0 ? (monthlySavings / monthlyIncome) * 100 : 0.0;
}

/// 資産内訳
class AssetBreakdown {
  final String assetType;           // savings, investment, checking, other
  final int amount;
  final double percentOfTotal;
  final String trendIndicator;      // ↑, →, ↓

  const AssetBreakdown({
    required this.assetType,
    required this.amount,
    required this.percentOfTotal,
    required this.trendIndicator,
  });
}

/// 負債内訳
class LiabilityBreakdown {
  final String liabilityType;       // shortTerm, longTerm, other
  final int amount;
  final double interestRate;        // e.g., 2.5
  final DateTime? repaymentDeadline;
  final double monthlyPayment;

  const LiabilityBreakdown({
    required this.liabilityType,
    required this.amount,
    required this.interestRate,
    this.repaymentDeadline,
    required this.monthlyPayment,
  });
}

/// 純資産の月次スナップショット（長期推移グラフ用）
class NetWorthSnapshot {
  final String month; // YYYY-MM形式
  final int totalAssets;
  final int totalLiabilities;

  const NetWorthSnapshot({
    required this.month,
    required this.totalAssets,
    required this.totalLiabilities,
  });

  int get netWorth => totalAssets - totalLiabilities;
}

/// 純資産の長期推移（複数ヶ月分のスナップショットをまとめたもの）
class NetWorthHistory {
  final String groupId;
  final List<NetWorthSnapshot> snapshots; // 古い順

  const NetWorthHistory({
    required this.groupId,
    required this.snapshots,
  });

  /// 期間内の純資産の増減額（最初と最後の差分）
  int get netWorthChange => snapshots.length >= 2
      ? snapshots.last.netWorth - snapshots.first.netWorth
      : 0;

  /// 期間内の純資産の増減率（%）
  double get netWorthChangePercent {
    if (snapshots.length < 2) return 0.0;
    final first = snapshots.first.netWorth;
    if (first == 0) return 0.0;
    return (netWorthChange / first.abs()) * 100;
  }
}

/// 簡易バランスサマリー - 当月の収支概要
class SimpleBalanceSummary {
  final int monthlyIncome;          // 月間収入
  final int monthlyExpense;         // 月間支出
  final int monthlySavings;         // 月間貯蓄
  final double savingsRate;         // 貯蓄率 (%)
  final Map<String, int> categoryExpenses; // カテゴリ別支出

  const SimpleBalanceSummary({
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.monthlySavings,
    required this.savingsRate,
    required this.categoryExpenses,
  });
}
