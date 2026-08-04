enum InvestmentType { topix, nasdaq, sp500, bond, gold, allCountry }

enum InvestmentStatus { active, realized }

class Investment {
  final String id;
  final String uid;
  final int savingsAmount;
  final InvestmentType investmentType;
  final DateTime purchaseDate;
  final double purchaseIndexValue;
  final InvestmentStatus status;
  final DateTime? realizedAt;
  final double? realizedIndexValue;

  Investment({
    required this.id,
    required this.uid,
    required this.savingsAmount,
    required this.investmentType,
    required this.purchaseDate,
    required this.purchaseIndexValue,
    this.status = InvestmentStatus.active,
    this.realizedAt,
    this.realizedIndexValue,
  });

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'] as String,
      uid: json['uid'] as String,
      savingsAmount: json['savingsAmount'] as int,
      investmentType: InvestmentType.values[json['investmentType'] as int],
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      purchaseIndexValue: (json['purchaseIndexValue'] as num).toDouble(),
      status: InvestmentStatus.values[json['status'] as int? ?? 0],
      realizedAt: json['realizedAt'] != null
          ? DateTime.parse(json['realizedAt'] as String)
          : null,
      realizedIndexValue: json['realizedIndexValue'] != null
          ? (json['realizedIndexValue'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'savingsAmount': savingsAmount,
      'investmentType': investmentType.index,
      'purchaseDate': purchaseDate.toIso8601String(),
      'purchaseIndexValue': purchaseIndexValue,
      'status': status.index,
      'realizedAt': realizedAt?.toIso8601String(),
      'realizedIndexValue': realizedIndexValue,
    };
  }

  // 現在価値を計算（現在の指数値を渡す）。教育目的シミュレーションのため実際の市場データではなく
  // 決定論的な擬似変動モデルを使用する。
  double currentValue(double currentIndexValue) {
    final ratio = currentIndexValue / purchaseIndexValue;
    return savingsAmount * ratio;
  }

  double profitLoss(double currentIndexValue) {
    return currentValue(currentIndexValue) - savingsAmount;
  }
}

class InvestmentTypeInfo {
  static const Map<InvestmentType, String> displayNames = {
    InvestmentType.topix: 'TOPIX（日本株式）',
    InvestmentType.nasdaq: 'NASDAQ（米国株式）',
    InvestmentType.sp500: 'S&P500（米国株式）',
    InvestmentType.bond: '先進国債券',
    InvestmentType.gold: '金（ゴールド）',
    InvestmentType.allCountry: '全世界株式（オルカン）',
  };

  /// 各投資タイプの一言解説（教育目的）
  static const Map<InvestmentType, String> descriptions = {
    InvestmentType.topix: '東証プライム市場全体の値動きを示す指数。日本経済の縮図と言われる。',
    InvestmentType.nasdaq: '米国のハイテク企業が多く上場する市場の指数。値動きが大きめ。',
    InvestmentType.sp500: '米国を代表する約500社で構成される指数。世界的に人気の高い投資対象。',
    InvestmentType.bond: '国や企業への貸付。株式より値動きが穏やかでローリスク・ローリターン傾向。',
    InvestmentType.gold: 'インフレや金融不安に強いとされる実物資産。価格変動はあるが分散効果が期待できる。',
    InvestmentType.allCountry: '日本を含む世界中の株式に分散投資する指数。1本で国際分散が完結する。',
  };

  static const Map<InvestmentType, double> baseIndexValues = {
    InvestmentType.topix: 2800.0,
    InvestmentType.nasdaq: 16000.0,
    InvestmentType.sp500: 5500.0,
    InvestmentType.bond: 100.0,
    InvestmentType.gold: 300.0,
    InvestmentType.allCountry: 25000.0,
  };

  static const Map<InvestmentType, double> annualGrowthRate = {
    InvestmentType.topix: 0.05,
    InvestmentType.nasdaq: 0.09,
    InvestmentType.sp500: 0.07,
    InvestmentType.bond: 0.02,
    InvestmentType.gold: 0.04,
    InvestmentType.allCountry: 0.06,
  };

  /// 年間リターンのボラティリティ（変動の大きさ、%）。教育目的の概算値。
  /// 「リアル変動」シミュレーションで、好況・不況の波を再現するために使う。
  static const Map<InvestmentType, double> volatilityPercent = {
    InvestmentType.topix: 18,
    InvestmentType.nasdaq: 25,
    InvestmentType.sp500: 18,
    InvestmentType.bond: 5,
    InvestmentType.gold: 15,
    InvestmentType.allCountry: 16,
  };
}
