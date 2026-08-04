class ChallengeParticipant {
  final String uid;
  final int reductionAmount;

  ChallengeParticipant({required this.uid, required this.reductionAmount});

  factory ChallengeParticipant.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipant(
      uid: json['uid'] as String,
      reductionAmount: json['reductionAmount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'uid': uid, 'reductionAmount': reductionAmount};
  }
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final int targetReduction;
  final List<ChallengeParticipant> participants;
  final int rewardXP;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.targetReduction,
    required this.participants,
    required this.rewardXP,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      targetReduction: json['targetReduction'] as int,
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map((p) => ChallengeParticipant.fromJson(p as Map<String, dynamic>))
          .toList(),
      rewardXP: json['rewardXP'] as int? ?? 150,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'targetReduction': targetReduction,
      'participants': participants.map((p) => p.toJson()).toList(),
      'rewardXP': rewardXP,
    };
  }

  bool get isActive =>
      DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);

  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  List<ChallengeParticipant> get ranking {
    final sorted = List<ChallengeParticipant>.from(participants);
    sorted.sort((a, b) => b.reductionAmount.compareTo(a.reductionAmount));
    return sorted;
  }

  bool isParticipating(String uid) =>
      participants.any((p) => p.uid == uid);
}

/// チャレンジのテンプレート定義
class ChallengeTemplate {
  final String slug;
  final String title;
  final String description;
  final int targetReduction;
  final int rewardXP;

  const ChallengeTemplate({
    required this.slug,
    required this.title,
    required this.description,
    required this.targetReduction,
    required this.rewardXP,
  });
}

class ChallengeTemplates {
  /// 週替わりチャレンジのプール
  static const List<ChallengeTemplate> pool = [
    ChallengeTemplate(
      slug: 'no_conveni',
      title: '脱コンビニチャレンジ',
      description: '今週、コンビニでの支出を減らして節約しよう！',
      targetReduction: 1000,
      rewardXP: 150,
    ),
    ChallengeTemplate(
      slug: 'jisui',
      title: '自炊で節約チャレンジ',
      description: '外食・中食を減らし、今週の食費を自炊で抑えよう！',
      targetReduction: 2000,
      rewardXP: 180,
    ),
    ChallengeTemplate(
      slug: 'cafe',
      title: 'カフェ代セーブチャレンジ',
      description: 'カフェやドリンクの出費を見直して、水筒生活に挑戦！',
      targetReduction: 800,
      rewardXP: 120,
    ),
    ChallengeTemplate(
      slug: 'muda_subsc',
      title: 'サブスク断捨離チャレンジ',
      description: '使っていないサブスクを解約して固定費をカットしよう！',
      targetReduction: 1500,
      rewardXP: 200,
    ),
    ChallengeTemplate(
      slug: 'cashless_track',
      title: '支出見える化チャレンジ',
      description: '今週の支出をすべて記録して、無駄を見つけよう！',
      targetReduction: 1000,
      rewardXP: 150,
    ),
    ChallengeTemplate(
      slug: 'no_impulse',
      title: '衝動買いガマンチャレンジ',
      description: '「24時間ルール」で衝動買いを我慢し、ムダ遣いを減らそう！',
      targetReduction: 1200,
      rewardXP: 160,
    ),
  ];

  /// 今週のチャレンジ（週ごとに決定的に切り替わる）
  static Challenge currentWeeklyChallenge() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final startOfWeek = now.subtract(Duration(days: weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 7));

    // 年間通算の週番号でプールを巡回選択（毎週異なるチャレンジ）
    final weekOfYear =
        ((start.difference(DateTime(start.year, 1, 1)).inDays) / 7).floor();
    final template = pool[weekOfYear % pool.length];

    return Challenge(
      id: 'challenge_${template.slug}_${start.toIso8601String().substring(0, 10)}',
      title: template.title,
      description: template.description,
      startDate: start,
      endDate: end,
      targetReduction: template.targetReduction,
      participants: [],
      rewardXP: template.rewardXP,
    );
  }
}
