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

  const Subscription({
    required this.id,
    required this.uid,
    required this.name,
    required this.amount,
    required this.billingCycle,
    required this.category,
    this.isActive = true,
    required this.createdAt,
  });

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
    };
  }

  Subscription copyWith({
    String? name,
    int? amount,
    SubscriptionBillingCycle? billingCycle,
    SubscriptionCategory? category,
    bool? isActive,
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
    );
  }
}
