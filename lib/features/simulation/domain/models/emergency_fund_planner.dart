class EmergencyFundInput {
  final int monthlyEssentialExpense; // 毎月の生活必需支出
  final int coverageMonths; // 目標カバー月数（3〜12ヶ月が目安）
  final int currentSavings; // 現在の生活防衛資金の貯蓄額
  final int monthlyContribution; // 毎月積み立てられる額

  const EmergencyFundInput({
    required this.monthlyEssentialExpense,
    required this.coverageMonths,
    required this.currentSavings,
    required this.monthlyContribution,
  });
}

class EmergencyFundResult {
  final int targetAmount; // 目標金額
  final int remainingAmount; // 目標までの不足額
  final double progressPercent; // 達成率（%）
  final int? monthsToGoal; // 目標達成までの月数（積立額が0なら null）
  final bool isGoalReached;

  const EmergencyFundResult({
    required this.targetAmount,
    required this.remainingAmount,
    required this.progressPercent,
    required this.monthsToGoal,
    required this.isGoalReached,
  });
}

/// 生活防衛資金（緊急予備資金）の目標額と達成時期を試算する（教育目的）。
///
/// 生活防衛資金は、失業や病気などで収入が途絶えた場合に備え、
/// 毎月の必要生活費の3〜6ヶ月分（会社員）〜12ヶ月分（自営業）を
/// 目安に準備しておくことが推奨される。
class EmergencyFundPlanner {
  static EmergencyFundResult calculate(EmergencyFundInput input) {
    final targetAmount =
        input.monthlyEssentialExpense * input.coverageMonths;
    final remainingAmount =
        (targetAmount - input.currentSavings).clamp(0, targetAmount);
    final isGoalReached = remainingAmount == 0 && targetAmount > 0;
    final progressPercent = targetAmount > 0
        ? (input.currentSavings / targetAmount * 100).clamp(0.0, 100.0)
        : 0.0;

    int? monthsToGoal;
    if (!isGoalReached && input.monthlyContribution > 0) {
      monthsToGoal = (remainingAmount / input.monthlyContribution).ceil();
    }

    return EmergencyFundResult(
      targetAmount: targetAmount,
      remainingAmount: remainingAmount,
      progressPercent: progressPercent,
      monthsToGoal: monthsToGoal,
      isGoalReached: isGoalReached,
    );
  }
}
