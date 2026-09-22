enum SubscriptionBillingCycle { monthly, yearly }

enum SubscriptionCategory { video, music, app, fitness, news, cloud, other }

extension SubscriptionCategoryInfo on SubscriptionCategory {
  String get displayName {
    switch (this) {
      case SubscriptionCategory.video:
        return '動画配信';
      case SubscriptionCategory.music:
        return '音楽配信';
      case SubscriptionCategory.app:
        return 'アプリ・ソフト';
      case SubscriptionCategory.fitness:
        return 'フィットネス';
      case SubscriptionCategory.news:
        return 'ニュース・雑誌';
      case SubscriptionCategory.cloud:
        return 'クラウド・ストレージ';
      case SubscriptionCategory.other:
        return 'その他';
    }
  }
}

extension SubscriptionBillingCycleInfo on SubscriptionBillingCycle {
  String get displayName {
    switch (this) {
      case SubscriptionBillingCycle.monthly:
        return '月払い';
      case SubscriptionBillingCycle.yearly:
        return '年払い';
    }
  }
}

class Subscription {
  final String id;
  final String uid;
  final String name;
  final int amount; // 1回あたりの請求額
  final SubscriptionBillingCycle billingCycle;
  final SubscriptionCategory category;
  final bool isActive;
  final DateTime createdAt;
  final int? billingDay; // 請求日（1〜31）。支払いカレンダー・リマインダー用（任意）
  final int? billingMonth; // 年払いの場合の請求月（1〜12）。月払いの場合は無視

  const Subscription({
    required this.id,
    required this.uid,
    required this.name,
    required this.amount,
    required this.billingCycle,
    required this.category,
    this.isActive = true,
    required this.createdAt,
    this.billingDay,
    this.billingMonth,
  });

  /// 次回の請求予定日。billingDayが未設定の場合はnull。
  DateTime? get nextBillingDate {
    final day = billingDay;
    if (day == null) return null;

    final now = DateTime.now();
    if (billingCycle == SubscriptionBillingCycle.monthly) {
      var candidate = _dateInMonth(now.year, now.month, day);
      if (!candidate.isAfter(now)) {
        final nextMonth = now.month == 12 ? 1 : now.month + 1;
        final nextYear = now.month == 12 ? now.year + 1 : now.year;
        candidate = _dateInMonth(nextYear, nextMonth, day);
      }
      return candidate;
    } else {
      final month = billingMonth ?? now.month;
      var candidate = _dateInMonth(now.year, month, day);
      if (!candidate.isAfter(now)) {
        candidate = _dateInMonth(now.year + 1, month, day);
      }
      return candidate;
    }
  }

  /// 月額換算額（年払いの場合は12で割った金額）
  int get monthlyEquivalentAmount {
    switch (billingCycle) {
      case SubscriptionBillingCycle.monthly:
        return amount;
      case SubscriptionBillingCycle.yearly:
        return (amount / 12).round();
    }
  }

  int get annualAmount {
    switch (billingCycle) {
      case SubscriptionBillingCycle.monthly:
        return amount * 12;
      case SubscriptionBillingCycle.yearly:
        return amount;
    }
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      uid: json['uid'] as String,
      name: json['name'] as String,
      amount: json['amount'] as int,
      billingCycle: SubscriptionBillingCycle.values[json['billingCycle'] as int? ?? 0],
      category: SubscriptionCategory.values[json['category'] as int? ?? 6],
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      billingDay: json['billingDay'] as int?,
      billingMonth: json['billingMonth'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'amount': amount,
      'billingCycle': billingCycle.index,
      'category': category.index,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'billingDay': billingDay,
      'billingMonth': billingMonth,
    };
  }

  Subscription copyWith({
    String? name,
    int? amount,
    SubscriptionBillingCycle? billingCycle,
    SubscriptionCategory? category,
    bool? isActive,
    int? billingDay,
    int? billingMonth,
  }) {
    return Subscription(
      id: id,
      uid: uid,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      billingCycle: billingCycle ?? this.billingCycle,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      billingDay: billingDay ?? this.billingDay,
      billingMonth: billingMonth ?? this.billingMonth,
    );
  }
}

/// 指定した年月の中で有効な日付を返す（月末を超える日は月末に丸める）
DateTime _dateInMonth(int year, int month, int day) {
  final lastDayOfMonth = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day.clamp(1, lastDayOfMonth));
}
