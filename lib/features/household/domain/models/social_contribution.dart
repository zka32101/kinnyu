/// 社会貢献・ESG関連のモデル定義

/// カーボンフットプリント計算用の支出カテゴリマッピング
class CarbonEmissionFactor {
  final String category;           // 支出カテゴリ
  final double emissionPerYen;     // 1円あたりのCO2排出量（g）
  final String description;        // 説明

  const CarbonEmissionFactor({
    required this.category,
    required this.emissionPerYen,
    required this.description,
  });

  /// 支出額からカーボンフットプリントを計算
  double calculateEmission(int amount) {
    return amount * emissionPerYen;
  }

  /// デフォルトの排出係数マッピング
  static Map<String, CarbonEmissionFactor> defaultFactors = {
    '食費': CarbonEmissionFactor(
      category: '食費',
      emissionPerYen: 0.15,
      description: '食品購入のCO2排出量（生産・輸送を含む）',
    ),
    '交通費': CarbonEmissionFactor(
      category: '交通費',
      emissionPerYen: 0.08,
      description: '交通手段のCO2排出量（電車・バス基準）',
    ),
    'エネルギー': CarbonEmissionFactor(
      category: 'エネルギー',
      emissionPerYen: 0.25,
      description: '電気・ガス・水道のCO2排出量',
    ),
    'オンラインショッピング': CarbonEmissionFactor(
      category: 'オンラインショッピング',
      emissionPerYen: 0.12,
      description: '商品配送のCO2排出量',
    ),
    'エンタメ': CarbonEmissionFactor(
      category: 'エンタメ',
      emissionPerYen: 0.05,
      description: '娯楽サービスのCO2排出量',
    ),
    'その他': CarbonEmissionFactor(
      category: 'その他',
      emissionPerYen: 0.10,
      description: 'デフォルトCO2排出量',
    ),
  };
}

/// ユーザーのカーボンフットプリント記録
class CarbonFootprintRecord {
  final String id;
  final String userId;
  final String groupId;
  final DateTime date;
  final String category;
  final int expenseAmount;
  final double carbonEmission;    // g単位
  final String description;
  final bool isSaved;             // 削減フラグ

  const CarbonFootprintRecord({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.date,
    required this.category,
    required this.expenseAmount,
    required this.carbonEmission,
    required this.description,
    required this.isSaved,
  });

  /// JSON変換
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'groupId': groupId,
    'date': date.toIso8601String(),
    'category': category,
    'expenseAmount': expenseAmount,
    'carbonEmission': carbonEmission,
    'description': description,
    'isSaved': isSaved,
  };

  static CarbonFootprintRecord fromJson(Map<String, dynamic> json) {
    return CarbonFootprintRecord(
      id: json['id'] as String,
      userId: json['userId'] as String,
      groupId: json['groupId'] as String,
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String,
      expenseAmount: json['expenseAmount'] as int,
      carbonEmission: (json['carbonEmission'] as num).toDouble(),
      description: json['description'] as String,
      isSaved: json['isSaved'] as bool? ?? false,
    );
  }
}

/// 寄付・チャリティ情報
class CharityDonation {
  final String id;
  final String name;               // 慈善団体名
  final String description;        // 説明
  final String category;           // カテゴリ（教育、環境、医療など）
  final String emoji;              // ビジュアルアイデンティティ
  final double impactPerYen;       // 1円あたりの社会的インパクト度合い
  final String impactDescription;  // インパクト説明（例：「1円で子ども1人に本1冊」）
  final String website;            // ウェブサイト

  const CharityDonation({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.emoji,
    required this.impactPerYen,
    required this.impactDescription,
    required this.website,
  });

  /// デフォルトのチャリティカテゴリ
  static List<CharityDonation> defaultCharities = [
    CharityDonation(
      id: 'charity_1',
      name: '日本赤十字社',
      description: '災害支援・血液事業・健康福祉',
      category: '人道支援',
      emoji: '🩸',
      impactPerYen: 1.0,
      impactDescription: '1,000円で5人の家族に清潔な水を提供',
      website: 'https://www.jrc.or.jp/',
    ),
    CharityDonation(
      id: 'charity_2',
      name: 'WWFジャパン',
      description: '環境保全・野生生物保護',
      category: '環境',
      emoji: '🌍',
      impactPerYen: 0.8,
      impactDescription: '1,000円でマングローブ林50㎡を保全',
      website: 'https://www.wwf.or.jp/',
    ),
    CharityDonation(
      id: 'charity_3',
      name: 'ユニセフ',
      description: '子どもの貧困対策・教育支援',
      category: '教育',
      emoji: '📚',
      impactPerYen: 1.2,
      impactDescription: '1,000円で子ども1人に教科書を提供',
      website: 'https://www.unicef.or.jp/',
    ),
    CharityDonation(
      id: 'charity_4',
      name: 'オックスファムジャパン',
      description: '飢餓対策・貧困削減',
      category: '貧困対策',
      emoji: '🍚',
      impactPerYen: 0.9,
      impactDescription: '500円でアフリカの家族1世帯に食料を提供',
      website: 'https://oxfam.jp/',
    ),
    CharityDonation(
      id: 'charity_5',
      name: 'グリーンピース・ジャパン',
      description: '気候変動対策・再生可能エネルギー',
      category: '気候変動',
      emoji: '♻️',
      impactPerYen: 0.7,
      impactDescription: '2,000円で太陽光パネル1枚相当の削減',
      website: 'https://www.greenpeace.org/japan/',
    ),
  ];
}

/// ユーザーの寄付実績
class UserDonationRecord {
  final String id;
  final String userId;
  final String groupId;
  final String charityId;
  final String charityName;
  final int donationAmount;
  final DateTime date;
  final String source;             // 寄付の出所（例：「カテゴリAで節約」）

  const UserDonationRecord({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.charityId,
    required this.charityName,
    required this.donationAmount,
    required this.date,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'groupId': groupId,
    'charityId': charityId,
    'charityName': charityName,
    'donationAmount': donationAmount,
    'date': date.toIso8601String(),
    'source': source,
  };

  static UserDonationRecord fromJson(Map<String, dynamic> json) {
    return UserDonationRecord(
      id: json['id'] as String,
      userId: json['userId'] as String,
      groupId: json['groupId'] as String,
      charityId: json['charityId'] as String,
      charityName: json['charityName'] as String,
      donationAmount: json['donationAmount'] as int,
      date: DateTime.parse(json['date'] as String),
      source: json['source'] as String,
    );
  }
}

/// 社会貢献インパクトダッシュボード
class SocialImpactDashboard {
  final String groupId;
  final double totalCarbonSaved;           // g単位
  final int totalDonationsAmount;          // 円
  final int familiesHelped;                // 支援した家族数（推計）
  final Map<String, double> impactByCharity;  // 慈善団体別のインパクト
  final List<String> topCategories;        // CO2削減トップカテゴリ

  const SocialImpactDashboard({
    required this.groupId,
    required this.totalCarbonSaved,
    required this.totalDonationsAmount,
    required this.familiesHelped,
    required this.impactByCharity,
    required this.topCategories,
  });

  /// CO2削減を木の本数に換算（1本の木が1年で吸収する量：約20kg CO2）
  int get treesEquivalent => (totalCarbonSaved / 20000).toInt();

  /// CO2削減を走行距離に換算（乗用車のCO2排出量：約200g/km）
  int get carKmSaved => (totalCarbonSaved / 200).toInt();

  /// インパクトレベル（1-5）
  int get impactLevel {
    if (totalDonationsAmount >= 100000) return 5;
    if (totalDonationsAmount >= 50000) return 4;
    if (totalDonationsAmount >= 10000) return 3;
    if (totalDonationsAmount >= 1000) return 2;
    return 1;
  }

  /// インパクトレベルの説明
  String get impactLevelDescription {
    switch (impactLevel) {
      case 5:
        return 'エコリーダー 🌟';
      case 4:
        return 'エコサポーター 🌱';
      case 3:
        return 'エコマインド 💚';
      case 2:
        return 'エコビギナー 🌿';
      default:
        return 'チャレンジ開始 👶';
    }
  }
}

/// ESGスコア（環境・社会・ガバナンス）
class ESGScore {
  final String categoryName;
  final double environmentScore;   // 環境スコア（0-100）
  final double socialScore;        // 社会スコア（0-100）
  final double governanceScore;    // ガバナンススコア（0-100）

  const ESGScore({
    required this.categoryName,
    required this.environmentScore,
    required this.socialScore,
    required this.governanceScore,
  });

  /// 総合スコア
  double get totalScore =>
      (environmentScore + socialScore + governanceScore) / 3;

  /// グレード（A-F）
  String get grade {
    if (totalScore >= 80) return 'A+';
    if (totalScore >= 70) return 'A';
    if (totalScore >= 60) return 'B+';
    if (totalScore >= 50) return 'B';
    if (totalScore >= 40) return 'C';
    return 'D';
  }

  /// デフォルトのESGスコア（カテゴリ別）
  static Map<String, ESGScore> defaultScores = {
    '食費': ESGScore(
      categoryName: '食費',
      environmentScore: 60,  // 農業の環境負荷
      socialScore: 70,       // 労働条件
      governanceScore: 75,   // サプライチェーン透明性
    ),
    '交通費': ESGScore(
      categoryName: '交通費',
      environmentScore: 85,  // 公共交通利用時
      socialScore: 75,
      governanceScore: 80,
    ),
    'エネルギー': ESGScore(
      categoryName: 'エネルギー',
      environmentScore: 55,  // 再生可能エネルギーの割合に依存
      socialScore: 80,
      governanceScore: 85,
    ),
    'オンラインショッピング': ESGScore(
      categoryName: 'オンラインショッピング',
      environmentScore: 50,  // 配送による排出
      socialScore: 65,       // 労働条件
      governanceScore: 70,
    ),
    'エンタメ': ESGScore(
      categoryName: 'エンタメ',
      environmentScore: 65,
      socialScore: 75,
      governanceScore: 80,
    ),
  };
}
