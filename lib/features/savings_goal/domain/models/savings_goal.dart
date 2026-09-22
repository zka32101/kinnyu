class SavingsGoal {
  final String id;
  final String uid;
  final String name;
  final String emoji;
  final int targetAmount;
  final int currentAmount;
  final DateTime deadline;
  final DateTime createdAt;

  const SavingsGoal({
    required this.id,
    required this.uid,
    required this.name,
    required this.emoji,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.createdAt,
  });

  /// 0.0〜1.0 に正規化した進捗率
  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  int get remainingAmount => (targetAmount - currentAmount).clamp(0, targetAmount);

  bool get isAchieved => currentAmount >= targetAmount;

  /// 期限までに毎月いくら積み立てる必要があるか（期限を過ぎている場合は残額を返す）
  int get requiredMonthlyAmount {
    final remaining = remainingAmount;
    if (remaining <= 0) return 0;

    final now = DateTime.now();
    final monthsLeft = (deadline.year - now.year) * 12 + (deadline.month - now.month);
    if (monthsLeft <= 0) return remaining;

    return (remaining / monthsLeft).ceil();
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      uid: json['uid'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '🎯',
      targetAmount: json['targetAmount'] as int,
      currentAmount: json['currentAmount'] as int? ?? 0,
      deadline: DateTime.parse(json['deadline'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'emoji': emoji,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  SavingsGoal copyWith({
    String? name,
    String? emoji,
    int? targetAmount,
    int? currentAmount,
    DateTime? deadline,
  }) {
    return SavingsGoal(
      id: id,
      uid: uid,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt,
    );
  }
}
