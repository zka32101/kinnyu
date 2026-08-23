import 'package:flutter/material.dart';

/// 実績（バッジ）のカテゴリ
enum AchievementCategory { streak, level, mission, procedure, investment }

extension AchievementCategoryX on AchievementCategory {
  String get label {
    switch (this) {
      case AchievementCategory.streak:
        return '継続';
      case AchievementCategory.level:
        return 'レベル';
      case AchievementCategory.mission:
        return 'ミッション';
      case AchievementCategory.procedure:
        return '制度活用';
      case AchievementCategory.investment:
        return '資産形成';
    }
  }
}

/// 実績（バッジ）の定義。閾値（threshold）に到達すると解除される。
class Achievement {
  final String id;
  final AchievementCategory category;
  final String title;
  final String description;
  final IconData icon;
  final int threshold;

  const Achievement({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    required this.threshold,
  });
}

/// ある実績に対する、あるユーザーの現在の進捗状況。
class AchievementProgress {
  final Achievement achievement;
  final int currentValue;
  final bool unlocked;

  const AchievementProgress({
    required this.achievement,
    required this.currentValue,
    required this.unlocked,
  });

  /// 0.0〜1.0 に正規化した達成度。
  double get progress =>
      (currentValue / achievement.threshold).clamp(0.0, 1.0);
}

/// 全実績（バッジ）の定義一覧。
class AchievementDefinitions {
  static const List<Achievement> all = [
    // --- 継続（ログインストリーク） ---
    Achievement(
      id: 'streak_3',
      category: AchievementCategory.streak,
      title: '3日連続ログイン',
      description: '3日連続でログインしました',
      icon: Icons.local_fire_department,
      threshold: 3,
    ),
    Achievement(
      id: 'streak_7',
      category: AchievementCategory.streak,
      title: '1週間の継続力',
      description: '7日連続でログインしました',
      icon: Icons.local_fire_department,
      threshold: 7,
    ),
    Achievement(
      id: 'streak_30',
      category: AchievementCategory.streak,
      title: '1ヶ月継続の達人',
      description: '30日連続でログインしました',
      icon: Icons.local_fire_department,
      threshold: 30,
    ),
    Achievement(
      id: 'streak_100',
      category: AchievementCategory.streak,
      title: '継続の鬼',
      description: '100日連続でログインしました',
      icon: Icons.local_fire_department,
      threshold: 100,
    ),

    // --- レベル ---
    Achievement(
      id: 'level_5',
      category: AchievementCategory.level,
      title: '駆け出し家計マネージャー',
      description: 'レベル5に到達しました',
      icon: Icons.military_tech,
      threshold: 5,
    ),
    Achievement(
      id: 'level_10',
      category: AchievementCategory.level,
      title: '家計マネージャー',
      description: 'レベル10に到達しました',
      icon: Icons.military_tech,
      threshold: 10,
    ),
    Achievement(
      id: 'level_20',
      category: AchievementCategory.level,
      title: 'ベテラン家計マネージャー',
      description: 'レベル20に到達しました',
      icon: Icons.military_tech,
      threshold: 20,
    ),
    Achievement(
      id: 'level_30',
      category: AchievementCategory.level,
      title: '家計マスター',
      description: 'レベル30に到達しました',
      icon: Icons.military_tech,
      threshold: 30,
    ),

    // --- ミッション ---
    Achievement(
      id: 'mission_5',
      category: AchievementCategory.mission,
      title: 'ミッション初心者',
      description: '5件のミッションを完了しました',
      icon: Icons.task_alt,
      threshold: 5,
    ),
    Achievement(
      id: 'mission_20',
      category: AchievementCategory.mission,
      title: 'ミッションハンター',
      description: '20件のミッションを完了しました',
      icon: Icons.task_alt,
      threshold: 20,
    ),
    Achievement(
      id: 'mission_50',
      category: AchievementCategory.mission,
      title: 'ミッションマスター',
      description: '50件のミッションを完了しました',
      icon: Icons.task_alt,
      threshold: 50,
    ),

    // --- 制度・補助金の活用 ---
    Achievement(
      id: 'procedure_3',
      category: AchievementCategory.procedure,
      title: '制度リサーチャー',
      description: '3件の制度・補助金を確認しました',
      icon: Icons.account_balance,
      threshold: 3,
    ),
    Achievement(
      id: 'procedure_10',
      category: AchievementCategory.procedure,
      title: '制度活用エキスパート',
      description: '10件の制度・補助金を確認しました',
      icon: Icons.account_balance,
      threshold: 10,
    ),
    Achievement(
      id: 'procedure_22',
      category: AchievementCategory.procedure,
      title: '制度マスター',
      description: '全22件の制度・補助金を確認しました',
      icon: Icons.account_balance,
      threshold: 22,
    ),

    // --- 投資 ---
    Achievement(
      id: 'investment_1',
      category: AchievementCategory.investment,
      title: '投資デビュー',
      description: '初めて投資を開始しました',
      icon: Icons.trending_up,
      threshold: 1,
    ),
    Achievement(
      id: 'investment_5',
      category: AchievementCategory.investment,
      title: '分散投資家',
      description: '5件の投資を開始しました',
      icon: Icons.trending_up,
      threshold: 5,
    ),
    Achievement(
      id: 'investment_10',
      category: AchievementCategory.investment,
      title: '投資の達人',
      description: '10件の投資を開始しました',
      icon: Icons.trending_up,
      threshold: 10,
    ),
  ];
}
