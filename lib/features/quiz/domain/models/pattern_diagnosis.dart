class PatternDiagnosis {
  final String patternId;
  final String typeName;
  final String savingsTip1;
  final String savingsTip2;
  final String savingsTip3;
  final String disclaimer;
  final int estimatedMonthlySavings;
  final String imageAsset;

  PatternDiagnosis({
    required this.patternId,
    this.typeName = '',
    required this.savingsTip1,
    required this.savingsTip2,
    required this.savingsTip3,
    required this.disclaimer,
    required this.estimatedMonthlySavings,
    this.imageAsset = '',
  });

  factory PatternDiagnosis.fromJson(Map<String, dynamic> json) {
    return PatternDiagnosis(
      patternId: json['patternId'],
      typeName: json['typeName'] ?? '',
      savingsTip1: json['savingsTip1'],
      savingsTip2: json['savingsTip2'],
      savingsTip3: json['savingsTip3'],
      disclaimer: json['disclaimer'],
      estimatedMonthlySavings: json['estimatedMonthlySavings'] ?? 10000,
      imageAsset: json['imageAsset'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patternId': patternId,
      'typeName': typeName,
      'savingsTip1': savingsTip1,
      'savingsTip2': savingsTip2,
      'savingsTip3': savingsTip3,
      'disclaimer': disclaimer,
      'estimatedMonthlySavings': estimatedMonthlySavings,
      'imageAsset': imageAsset,
    };
  }
}

/// 診断ロジック:
/// 質問1(支出傾向) × 質問2(管理レベル) × 質問3(興味テーマ) の回答から
/// 節約タイプと3つのアドバイスを生成する。
class PatternDiagnosisGenerator {
  static const String _disclaimer =
      'この診断は教育目的です。実際の家計改善は専門家にご相談ください';

  // 質問1: 支出傾向 → タイプ名の軸
  static const List<String> _spendingTypes = [
    'ちりつも支出タイプ', // 0: こまめな出費
    'メリハリ消費タイプ', // 1: まとまった出費
    '固定費モヤモヤタイプ', // 2: 固定費増加
  ];

  // 質問1に応じた「支出削減」アドバイス
  static const List<String> _spendingTips = [
    'コンビニ・カフェは週の回数を決めて利用（月¥3,000節約）',
    '外食・レジャーは月予算を先に決めてから使う（月¥5,000節約）',
    'サブスク・保険など固定費を棚卸しして解約・乗り換え（月¥4,000節約）',
  ];

  // 質問2に応じた「管理習慣」アドバイス
  static const List<String> _managementTips = [
    'まず家計簿アプリで1ヶ月、支出を記録して見える化する',
    '固定費と変動費を分けて、削れる固定費から手をつける',
    '先取り貯蓄を自動化し、余力を投資に回す仕組みを作る',
  ];

  // 質問3に応じた「興味テーマ」アドバイス
  static const List<String> _goalTips = [
    '生活防衛資金（生活費3〜6ヶ月分）を最優先で貯める',
    'ふるさと納税と控除で、払いすぎた税金を取り戻す',
    'つみたてNISAで少額から長期・分散・積立を始める',
  ];

  // 質問3に応じた推定月間節約額の目安
  static const List<int> _goalSavings = [6000, 5000, 4000];

  // 質問1（支出傾向）に対応するイラスト
  static const List<String> _typeImages = [
    'assets/images/diagnosis/diag_chiritsumo.png',
    'assets/images/diagnosis/diag_merihari.png',
    'assets/images/diagnosis/diag_kotei.png',
  ];

  /// パターンIDは "q1_q2_q3"（各0〜2）の形式
  static PatternDiagnosis getDiagnosis(String patternId) {
    final parts = patternId.split('_');
    int q1 = 0, q2 = 0, q3 = 0;
    if (parts.length == 3) {
      q1 = _clampIndex(parts[0]);
      q2 = _clampIndex(parts[1]);
      q3 = _clampIndex(parts[2]);
    }

    return PatternDiagnosis(
      patternId: patternId,
      typeName: _spendingTypes[q1],
      savingsTip1: _spendingTips[q1],
      savingsTip2: _managementTips[q2],
      savingsTip3: _goalTips[q3],
      disclaimer: _disclaimer,
      estimatedMonthlySavings: _goalSavings[q3],
      imageAsset: _typeImages[q1],
    );
  }

  static int _clampIndex(String s) {
    final v = int.tryParse(s) ?? 0;
    if (v < 0) return 0;
    if (v > 2) return 2;
    return v;
  }

  static PatternDiagnosis getRandomDiagnosis() {
    final seed = DateTime.now().millisecondsSinceEpoch;
    final q1 = seed % 3;
    final q2 = (seed ~/ 3) % 3;
    final q3 = (seed ~/ 9) % 3;
    return getDiagnosis('${q1}_${q2}_${q3}');
  }
}
