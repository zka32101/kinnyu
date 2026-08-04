enum MissionType {
  furusatoNozei,
  insuranceReview,
  receiptReduction,
  savingsTarget,
  investmentStart,
}

enum MissionStatus { pending, completed, expired }

class Mission {
  final String id;
  final MissionType type;
  final String title;
  final String description;
  final int rewardXP;
  final DateTime deadline;
  final MissionStatus status;
  final DateTime? completedAt;

  Mission({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.rewardXP,
    required this.deadline,
    this.status = MissionStatus.pending,
    this.completedAt,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as String,
      type: MissionType.values[json['type'] as int],
      title: json['title'] as String,
      description: json['description'] as String,
      rewardXP: json['rewardXP'] as int,
      deadline: DateTime.parse(json['deadline'] as String),
      status: MissionStatus.values[json['status'] as int? ?? 0],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'title': title,
      'description': description,
      'rewardXP': rewardXP,
      'deadline': deadline.toIso8601String(),
      'status': status.index,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  Mission copyWith({
    MissionStatus? status,
    DateTime? completedAt,
  }) {
    return Mission(
      id: id,
      type: type,
      title: title,
      description: description,
      rewardXP: rewardXP,
      deadline: deadline,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  bool get isExpired => DateTime.now().isAfter(deadline) && status == MissionStatus.pending;
}

/// ミッションのテンプレート定義（タイトル・説明・報酬・種別）
class MissionTemplate {
  final MissionType type;
  final String slug;
  final String title;
  final String description;
  final int rewardXP;

  const MissionTemplate({
    required this.type,
    required this.slug,
    required this.title,
    required this.description,
    required this.rewardXP,
  });
}

class MissionTemplates {
  /// 全ミッションテンプレート（週次ミッションのプール）
  static const List<MissionTemplate> pool = [
    // --- ふるさと納税・税金 ---
    MissionTemplate(
      type: MissionType.furusatoNozei,
      slug: 'furusato',
      title: 'ふるさと納税を1件申し込む',
      description: '控除上限内でふるさと納税の返礼品を選んで申し込みましょう',
      rewardXP: 50,
    ),
    MissionTemplate(
      type: MissionType.furusatoNozei,
      slug: 'furusato_limit',
      title: 'ふるさと納税の控除上限額を調べる',
      description: 'シミュレーターで自分の年収に応じた控除上限額を確認しましょう',
      rewardXP: 40,
    ),
    // --- 保険 ---
    MissionTemplate(
      type: MissionType.insuranceReview,
      slug: 'insurance_review',
      title: '保険の保障内容を見直す',
      description: '現在加入中の保険の保障内容と保険料のバランスを確認しましょう',
      rewardXP: 50,
    ),
    MissionTemplate(
      type: MissionType.insuranceReview,
      slug: 'insurance_highcost',
      title: '高額療養費制度について調べる',
      description: '公的制度でカバーされる範囲を知り、民間医療保険の必要性を考えましょう',
      rewardXP: 40,
    ),
    // --- 支出削減 ---
    MissionTemplate(
      type: MissionType.receiptReduction,
      slug: 'conveni',
      title: 'コンビニ支出を今週¥1,000減らす',
      description: '今週のコンビニでの支出を先週より¥1,000減らしてみましょう',
      rewardXP: 50,
    ),
    MissionTemplate(
      type: MissionType.receiptReduction,
      slug: 'subscription',
      title: 'サブスクを1つ棚卸しする',
      description: '使っていないサブスク（動画・音楽・アプリ）がないか見直しましょう',
      rewardXP: 40,
    ),
    MissionTemplate(
      type: MissionType.receiptReduction,
      slug: 'lunch',
      title: '今週ランチを2回自炊にする',
      description: '外食ランチを2回、お弁当や自炊に置き換えてみましょう',
      rewardXP: 30,
    ),
    MissionTemplate(
      type: MissionType.receiptReduction,
      slug: 'mobile_fee',
      title: 'スマホ料金プランを確認する',
      description: '現在の通信費を確認し、格安SIMや料金プランの見直し余地を探しましょう',
      rewardXP: 40,
    ),
    // --- 貯蓄 ---
    MissionTemplate(
      type: MissionType.savingsTarget,
      slug: 'save_target',
      title: '今週¥3,000を貯蓄口座に移す',
      description: '先取り貯蓄を体験。使う前に¥3,000を別口座に移してみましょう',
      rewardXP: 50,
    ),
    MissionTemplate(
      type: MissionType.savingsTarget,
      slug: 'household_book',
      title: '3日間家計簿をつける',
      description: '支出を記録して「見える化」。まずは3日間続けてみましょう',
      rewardXP: 40,
    ),
    MissionTemplate(
      type: MissionType.savingsTarget,
      slug: 'emergency_fund',
      title: '生活防衛資金の目標額を決める',
      description: '毎月の生活費を把握し、3〜6ヶ月分の目標額を計算しましょう',
      rewardXP: 40,
    ),
    // --- 投資 ---
    MissionTemplate(
      type: MissionType.investmentStart,
      slug: 'nisa_learn',
      title: '新NISAの仕組みを調べる',
      description: 'つみたて投資枠・成長投資枠の違いと非課税メリットを理解しましょう',
      rewardXP: 50,
    ),
    MissionTemplate(
      type: MissionType.investmentStart,
      slug: 'index_fund',
      title: 'インデックスファンドを1つ調べる',
      description: '低コストなインデックスファンドの信託報酬とベンチマークを確認しましょう',
      rewardXP: 40,
    ),
    MissionTemplate(
      type: MissionType.investmentStart,
      slug: 'compound',
      title: '複利シミュレーションを試す',
      description: '毎月の積立額×年利×年数で、将来いくらになるか計算してみましょう',
      rewardXP: 40,
    ),
  ];

  /// 週次ミッションを生成（プールから重複しない種別で count 件を選ぶ）
  static List<Mission> generateWeeklyMissions({int count = 3, int? seed}) {
    final now = DateTime.now();
    final weekEnd = now.add(const Duration(days: 7));
    final baseSeed = seed ?? now.millisecondsSinceEpoch;

    // シードに基づき決定的にシャッフル（同じ週は同じミッション）
    final indices = List<int>.generate(pool.length, (i) => i);
    _seededShuffle(indices, baseSeed);

    // 種別が偏らないよう、異なる MissionType を優先して選ぶ
    final selected = <MissionTemplate>[];
    final usedTypes = <MissionType>{};
    for (final i in indices) {
      final t = pool[i];
      if (usedTypes.add(t.type)) {
        selected.add(t);
        if (selected.length >= count) break;
      }
    }
    // 種別が足りなければ残りから補充
    if (selected.length < count) {
      for (final i in indices) {
        final t = pool[i];
        if (!selected.contains(t)) {
          selected.add(t);
          if (selected.length >= count) break;
        }
      }
    }

    return selected
        .map((t) => Mission(
              id: 'mission_${t.slug}_$baseSeed',
              type: t.type,
              title: t.title,
              description: t.description,
              rewardXP: t.rewardXP,
              deadline: weekEnd,
            ))
        .toList();
  }

  /// シード付き Fisher-Yates シャッフル（決定的）
  static void _seededShuffle(List<int> list, int seed) {
    var s = seed & 0x7fffffff;
    int next() {
      // 線形合同法による疑似乱数
      s = (s * 1103515245 + 12345) & 0x7fffffff;
      return s;
    }

    for (var i = list.length - 1; i > 0; i--) {
      final j = next() % (i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}
