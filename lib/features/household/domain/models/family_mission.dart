import 'package:intl/intl.dart';

/// 家族ミッション参加者
class FamilyMissionParticipant {
  final String uid;
  final String nickname;
  final int contribution; // その週の貢献額
  final int score; // ミッション専用スコア
  final List<DateTime> completedDates; // 完了日の記録

  FamilyMissionParticipant({
    required this.uid,
    required this.nickname,
    this.contribution = 0,
    this.score = 0,
    this.completedDates = const [],
  });

  factory FamilyMissionParticipant.fromJson(Map<String, dynamic> json) {
    return FamilyMissionParticipant(
      uid: json['uid'] as String,
      nickname: json['nickname'] as String? ?? 'メンバー',
      contribution: json['contribution'] as int? ?? 0,
      score: json['score'] as int? ?? 0,
      completedDates: (json['completedDates'] as List<dynamic>? ?? [])
          .map((d) => DateTime.parse(d as String))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nickname': nickname,
      'contribution': contribution,
      'score': score,
      'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  int get rank => score; // ランキング用
}

/// 家族ミッション
class FamilyMission {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final String emoji; // 🏠, 💰, 📊 など
  final DateTime startDate; // 週の開始日（月曜日）
  final DateTime endDate; // 週の終了日（日曜日）
  final int targetAmount; // 目標節約額
  final List<FamilyMissionParticipant> participants;
  final int weeklyBonusXP; // 週間ボーナスXP
  final bool isCompleted; // 達成フラグ
  final String? eventProposal; // 達成時のイベント提案

  FamilyMission({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    this.emoji = '🏠',
    required this.startDate,
    required this.endDate,
    this.targetAmount = 10000,
    this.participants = const [],
    this.weeklyBonusXP = 500,
    this.isCompleted = false,
    this.eventProposal,
  });

  factory FamilyMission.fromJson(Map<String, dynamic> json) {
    return FamilyMission(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String? ?? '🏠',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      targetAmount: json['targetAmount'] as int? ?? 10000,
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map((p) => FamilyMissionParticipant.fromJson(p as Map<String, dynamic>))
          .toList(),
      weeklyBonusXP: json['weeklyBonusXP'] as int? ?? 500,
      isCompleted: json['isCompleted'] as bool? ?? false,
      eventProposal: json['eventProposal'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'title': title,
      'description': description,
      'emoji': emoji,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'targetAmount': targetAmount,
      'participants': participants.map((p) => p.toJson()).toList(),
      'weeklyBonusXP': weeklyBonusXP,
      'isCompleted': isCompleted,
      'eventProposal': eventProposal,
    };
  }

  /// ミッションが有効か（開始日から終了日の間）
  bool get isActive =>
      DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);

  /// 残り日数
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  /// 家族全体の貢献額合計
  int get totalContribution =>
      participants.fold(0, (sum, p) => sum + p.contribution);

  /// 達成度（0.0-1.0）
  double get progressRatio =>
      targetAmount > 0 ? (totalContribution / targetAmount).clamp(0.0, 1.0) : 0.0;

  /// ランキング（スコア順）
  List<FamilyMissionParticipant> get ranking {
    final sorted = List<FamilyMissionParticipant>.from(participants);
    sorted.sort((a, b) => b.score.compareTo(a.score));
    return sorted;
  }

  /// 参加者数
  int get memberCount => participants.length;

  /// 特定ユーザーが参加しているか
  bool isParticipating(String uid) =>
      participants.any((p) => p.uid == uid);

  /// 参加者を取得（ニックネーム付き）
  FamilyMissionParticipant? getParticipant(String uid) =>
      participants.firstWhere(
        (p) => p.uid == uid,
        orElse: () => FamilyMissionParticipant(uid: uid, nickname: '未参加'),
      );
}

/// 家族ミッション達成時のイベント提案
class MissionEventProposal {
  final String title; // 例: "家族で温泉旅行"
  final String description;
  final int estimatedCost; // 必要な金額
  final String emoji;

  const MissionEventProposal({
    required this.title,
    required this.description,
    required this.estimatedCost,
    required this.emoji,
  });
}

/// 家族ミッションテンプレート
class FamilyMissionTemplate {
  final String slug;
  final String title;
  final String description;
  final String emoji;
  final int targetAmount;
  final int weeklyBonusXP;
  final MissionEventProposal eventProposal;

  const FamilyMissionTemplate({
    required this.slug,
    required this.title,
    required this.description,
    required this.emoji,
    required this.targetAmount,
    required this.weeklyBonusXP,
    required this.eventProposal,
  });
}

/// 家族ミッションテンプレートプール
class FamilyMissionTemplates {
  static const List<FamilyMissionTemplate> pool = [
    FamilyMissionTemplate(
      slug: 'family_home_cooking',
      title: '家族で自炊チャレンジ',
      description: '家族で協力して外食を減らし、自炊で食費を節約！',
      emoji: '🍳',
      targetAmount: 15000,
      weeklyBonusXP: 500,
      eventProposal: MissionEventProposal(
        title: '家族でホームパーティー',
        description: '節約した分で家族でホームパーティーを開こう！',
        estimatedCost: 5000,
        emoji: '🎉',
      ),
    ),
    FamilyMissionTemplate(
      slug: 'family_no_conveni',
      title: '脱コンビニ家族チャレンジ',
      description: 'コンビニ通いを家族で減らして、毎日の出費をカット',
      emoji: '🚫',
      targetAmount: 10000,
      weeklyBonusXP: 400,
      eventProposal: MissionEventProposal(
        title: '家族映画鑑賞ナイト',
        description: '節約した分で好きな映画をレンタルして家族で楽しもう',
        estimatedCost: 3000,
        emoji: '🎬',
      ),
    ),
    FamilyMissionTemplate(
      slug: 'family_subscription_audit',
      title: 'サブスク見直し家族会議',
      description: '使っていないサブスクを家族で一緒に見直そう',
      emoji: '📱',
      targetAmount: 20000,
      weeklyBonusXP: 600,
      eventProposal: MissionEventProposal(
        title: '家族で温泉旅行',
        description: '節約した分で家族で温泉旅行に行こう',
        estimatedCost: 30000,
        emoji: '♨️',
      ),
    ),
    FamilyMissionTemplate(
      slug: 'family_savings_goal',
      title: '家族貯蓄目標達成',
      description: '家族全員で力を合わせて月間貯蓄目標を達成',
      emoji: '💰',
      targetAmount: 25000,
      weeklyBonusXP: 700,
      eventProposal: MissionEventProposal(
        title: '家族で高級レストラン',
        description: '頑張った家族で美味しい食事をしよう',
        estimatedCost: 15000,
        emoji: '🍽️',
      ),
    ),
    FamilyMissionTemplate(
      slug: 'family_expense_tracking',
      title: '家族で支出見える化',
      description: '家族全員が支出を記録して、無駄を一緒に見つけよう',
      emoji: '📊',
      targetAmount: 12000,
      weeklyBonusXP: 450,
      eventProposal: MissionEventProposal(
        title: '家族でボーリング大会',
        description: '節約して浮いた分で家族でボーリングをしよう',
        estimatedCost: 5000,
        emoji: '🎳',
      ),
    ),
    FamilyMissionTemplate(
      slug: 'family_utility_saving',
      title: '光熱費削減家族チャレンジ',
      description: '家族で節電・節水に協力して光熱費をカット',
      emoji: '⚡',
      targetAmount: 8000,
      weeklyBonusXP: 350,
      eventProposal: MissionEventProposal(
        title: '家族でピクニック',
        description: '節約した分で家族でピクニックに行こう',
        estimatedCost: 3000,
        emoji: '🧺',
      ),
    ),
  ];

  /// 今週の家族ミッション（週ごとに切り替わる）
  static FamilyMission currentWeeklyMission(String groupId) {
    final now = DateTime.now();
    final weekday = now.weekday;
    final startOfWeek = now.subtract(Duration(days: weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 7));

    // 年間通算の週番号でプールを巡回選択（毎週異なるミッション）
    final weekOfYear =
        ((start.difference(DateTime(start.year, 1, 1)).inDays) / 7).floor();
    final template = pool[weekOfYear % pool.length];

    return FamilyMission(
      id: 'mission_${groupId}_${template.slug}_${start.toIso8601String().substring(0, 10)}',
      groupId: groupId,
      title: template.title,
      description: template.description,
      emoji: template.emoji,
      startDate: start,
      endDate: end,
      targetAmount: template.targetAmount,
      weeklyBonusXP: template.weeklyBonusXP,
      eventProposal: template.eventProposal.title,
    );
  }
}
