class HouseholdGroup {
  final String id;
  final String name;
  final List<String> members;
  final int totalSavings;
  final int monthlyGoal;
  final DateTime createdAt;
  final Map<String, String> memberNicknames;
  final Map<String, int> memberContributions;

  HouseholdGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.totalSavings,
    required this.monthlyGoal,
    required this.createdAt,
    this.memberNicknames = const {},
    this.memberContributions = const {},
  });

  factory HouseholdGroup.fromJson(Map<String, dynamic> json) {
    return HouseholdGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      members: List<String>.from(json['members'] as List),
      totalSavings: json['totalSavings'] as int? ?? 0,
      monthlyGoal: json['monthlyGoal'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      memberNicknames: Map<String, String>.from(
        (json['memberNicknames'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, value as String),
        ),
      ),
      memberContributions: Map<String, int>.from(
        (json['memberContributions'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, value as int? ?? 0),
        ),
      ),
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
      'memberNicknames': memberNicknames,
      'memberContributions': memberContributions,
    };
  }

  double get progressRatio =>
      monthlyGoal > 0 ? (totalSavings / monthlyGoal).clamp(0.0, 1.0) : 0.0;
}
