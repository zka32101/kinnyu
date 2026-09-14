/// 収入源のタイプ
enum IncomeSourceType {
  salary,      // 給与
  bonus,       // ボーナス
  business,    // ビジネス/副業
  investment,  // 投資収入
  other,       // その他
}

/// 単一の収入源
class IncomeSource {
  final String id;
  final String uid;
  final String sourceName;         // 給与, ボーナス, etc.
  final IncomeSourceType type;
  final int monthlyAmount;
  final DateTime startDate;
  final DateTime? endDate;          // null = ongoing
  final bool isActive;

  const IncomeSource({
    required this.id,
    required this.uid,
    required this.sourceName,
    required this.type,
    required this.monthlyAmount,
    required this.startDate,
    this.endDate,
    required this.isActive,
  });
}

/// 月間収入サマリー
class MonthlyIncome {
  final String groupId;
  final String month;               // YYYY-MM
  final List<IncomeSource> sources;

  const MonthlyIncome({
    required this.groupId,
    required this.month,
    required this.sources,
  });

  /// 総収入
  int get totalIncome => sources.fold(0, (sum, src) => sum + src.monthlyAmount);
}
