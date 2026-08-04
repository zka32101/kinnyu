class HouseholdGroup {
  final String id;
  final String name;
  final List<String> members;
  final int totalSavings;
  final int monthlyGoal;
  final DateTime createdAt;

  HouseholdGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.totalSavings,
    required this.monthlyGoal,
    required this.createdAt,
  });

  factory HouseholdGroup.fromJson(Map<String, dynamic> json) {
    return HouseholdGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      members: List<String>.from(json['members'] as List),
      totalSavings: json['totalSavings'] as int? ?? 0,
      monthlyGoal: json['monthlyGoal'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'members': members,
      'totalSavings': totalSavings,
      'monthlyGoal': monthlyGoal,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  double get progressRatio =>
      monthlyGoal > 0 ? (totalSavings / monthlyGoal).clamp(0.0, 1.0) : 0.0;
}
