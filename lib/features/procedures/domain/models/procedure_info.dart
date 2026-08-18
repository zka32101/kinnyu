import 'package:flutter/material.dart';

/// ライフステージ（制度・補助金の関連度をひもづけるための軽量な分類）。
/// ロールプレイのシナリオ種別と1:1で対応するが、procedures フィーチャーを
/// roleplay フィーチャーから独立させるためにあえて別の enum として定義する。
enum LifeStage { youngFamily, singleProfessional, preRetirement }

extension LifeStageX on LifeStage {
  String get label {
    switch (this) {
      case LifeStage.youngFamily:
        return '若い家族';
      case LifeStage.singleProfessional:
        return '独身社会人';
      case LifeStage.preRetirement:
        return '退職前世代';
    }
  }
}

/// 制度・手続きのカテゴリ
enum ProcedureCategory {
  childcare, // 子育て
  education, // 教育
  housing, // 住宅
  tax, // 税制
  pension, // 年金
  insurance, // 保険
  investment, // 資産形成
  consumerProtection, // 消費者保護
}

extension ProcedureCategoryX on ProcedureCategory {
  String get label {
    switch (this) {
      case ProcedureCategory.childcare:
        return '子育て';
      case ProcedureCategory.education:
        return '教育';
      case ProcedureCategory.housing:
        return '住宅';
      case ProcedureCategory.tax:
        return '税制';
      case ProcedureCategory.pension:
        return '年金';
      case ProcedureCategory.insurance:
        return '保険';
      case ProcedureCategory.investment:
        return '資産形成';
      case ProcedureCategory.consumerProtection:
        return '消費者保護';
    }
  }

  IconData get icon {
    switch (this) {
      case ProcedureCategory.childcare:
        return Icons.child_care;
      case ProcedureCategory.education:
        return Icons.school;
      case ProcedureCategory.housing:
        return Icons.home;
      case ProcedureCategory.tax:
        return Icons.receipt_long;
      case ProcedureCategory.pension:
        return Icons.elderly;
      case ProcedureCategory.insurance:
        return Icons.health_and_safety;
      case ProcedureCategory.investment:
        return Icons.trending_up;
      case ProcedureCategory.consumerProtection:
        return Icons.report_problem;
    }
  }

  Color get color {
    switch (this) {
      case ProcedureCategory.childcare:
        return Colors.pink;
      case ProcedureCategory.education:
        return Colors.blue;
      case ProcedureCategory.housing:
        return Colors.brown;
      case ProcedureCategory.tax:
        return Colors.orange;
      case ProcedureCategory.pension:
        return Colors.deepPurple;
      case ProcedureCategory.insurance:
        return Colors.red;
      case ProcedureCategory.investment:
        return Colors.green;
      case ProcedureCategory.consumerProtection:
        return Colors.amber;
    }
  }
}

/// 手続き・補助金・公的制度の情報
class ProcedureInfo {
  final String id;
  final String title; // 制度名
  final ProcedureCategory category;
  final String summary; // 概要
  final String eligibility; // 対象者
  final String benefitAmount; // 支給額・控除額の目安
  final String howToApply; // 申請方法
  final String applyWindow; // 申請時期・タイミングの目安
  final String sourceNote; // 相談・申請先（正式名称のみ。URLは変わりやすいため記載しない）
  final List<LifeStage> relevantScenarios;

  /// この制度の申請・確認を促すリマインダー通知を送るべき月（1〜12）。
  /// 恒常的に利用可能で締切のない制度は空リストのままにする。
  final List<int> reminderMonths;

  const ProcedureInfo({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.eligibility,
    required this.benefitAmount,
    required this.howToApply,
    required this.applyWindow,
    required this.sourceNote,
    required this.relevantScenarios,
    this.reminderMonths = const [],
  });
}

/// 制度・手続きのライブラリ（教育用の一般的な参考情報）
///
/// 制度の内容・金額・要件は法改正等で変更されることがあります。
/// 実際に利用する際は、必ず記載の相談・申請先で最新情報をご確認ください。
class ProcedureLibrary {
  static const List<ProcedureInfo> all = [
    ProcedureInfo(
      id: 'jido_teate',
      title: '児童手当',
      category: ProcedureCategory.childcare,
      summary: '子どもを養育する世帯に対し、国から手当が支給される制度。',
      eligibility: '中学生以下の子どもを養育する世帯（高校生年代までの対象拡大が順次実施）',
      benefitAmount: '月額目安 1万円〜1.5万円／人（年齢・人数により変動）',
      howToApply: '出生・転入から15日以内を目安に、市区町村窓口またはオンラインで申請',
      applyWindow: '出産後・転入後はできるだけ早めに',
      sourceNote: 'お住まいの市区町村窓口／こども家庭庁',
      relevantScenarios: [LifeStage.youngFamily],
    ),
    ProcedureInfo(
      id: 'shussan_ikuji',
      title: '出産育児一時金',
      category: ProcedureCategory.childcare,
      summary: '出産費用の負担を軽減するため、加入する健康保険から一定額が支給される制度。',
      eligibility: '健康保険加入者が出産した場合',
      benefitAmount: '子ども1人につき50万円前後（分娩機関の種別により変動）',
      howToApply: '医療機関の直接支払制度を利用すれば窓口負担を軽減可能。加入健康保険に要確認。',
      applyWindow: '出産予定が決まったら早めに医療機関・保険者へ確認',
      sourceNote: '加入している健康保険組合・協会けんぽ',
      relevantScenarios: [LifeStage.youngFamily],
    ),
    ProcedureInfo(
      id: 'koukou_shugaku',
      title: '高等学校等就学支援金',
      category: ProcedureCategory.education,
      summary: '高校の授業料負担を軽減する国の制度。所得に応じて支給額が変わる。',
      eligibility: '高等学校等に在学する生徒がいる世帯（所得要件あり）',
      benefitAmount: '公立高校授業料相当額〜私立向け加算あり（所得により変動）',
      howToApply: '入学時に学校を通じて申請書・マイナンバー等の必要書類を提出',
      applyWindow: '入学時・新年度に学校から案内',
      sourceNote: '在学する高等学校／文部科学省',
      relevantScenarios: [LifeStage.youngFamily],
      reminderMonths: [3, 4],
    ),
    ProcedureInfo(
      id: 'juutaku_loan_koujo',
      title: '住宅ローン控除（住宅借入金等特別控除）',
      category: ProcedureCategory.housing,
      summary: '住宅ローンでマイホームを取得した場合、年末残高の一定割合を所得税等から控除できる制度。',
      eligibility: '床面積等の要件を満たす住宅を住宅ローンで取得し、居住を開始した人',
      benefitAmount: '年末ローン残高の0.7%程度を最大13年間控除（住宅の種類で条件が変動）',
      howToApply: '入居初年度は確定申告が必要。会社員は2年目以降は年末調整で対応可能。',
      applyWindow: '入居した年の翌年2〜3月の確定申告時期',
      sourceNote: '税務署／国税庁',
      relevantScenarios: [LifeStage.youngFamily],
      reminderMonths: [2, 3],
    ),
    ProcedureInfo(
      id: 'nisa',
      title: 'NISA（新NISA・つみたて投資枠等）',
      category: ProcedureCategory.investment,
      summary: '投資で得た利益が非課税になる制度。つみたて投資枠・成長投資枠を活用できる。',
      eligibility: '18歳以上の日本在住者',
      benefitAmount: '運用益が非課税（非課税保有限度額など制度の枠内）',
      howToApply: '証券会社・銀行等でNISA口座を開設して申し込み',
      applyWindow: '口座開設後いつでも利用可能（年間投資枠は年単位でリセット）',
      sourceNote: '利用する金融機関／金融庁',
      relevantScenarios: [
        LifeStage.youngFamily,
        LifeStage.singleProfessional,
        LifeStage.preRetirement,
      ],
      reminderMonths: [1],
    ),
    ProcedureInfo(
      id: 'ideco',
      title: 'iDeCo（個人型確定拠出年金）',
      category: ProcedureCategory.pension,
      summary: '掛金が全額所得控除になる私的年金制度。運用益も非課税、受取時にも控除がある。',
      eligibility: '20歳以上65歳未満の国民年金・厚生年金被保険者等',
      benefitAmount: '掛金全額が所得控除（節税額は所得・掛金による）',
      howToApply: '金融機関でiDeCo口座を開設し、掛金額・運用商品を設定',
      applyWindow: 'いつでも申込可能（会社員は事業主証明が必要な場合あり）',
      sourceNote: '国民年金基金連合会／利用する金融機関',
      relevantScenarios: [
        LifeStage.youngFamily,
        LifeStage.singleProfessional,
      ],
    ),
    ProcedureInfo(
      id: 'furusato',
      title: 'ふるさと納税（ワンストップ特例制度）',
      category: ProcedureCategory.tax,
      summary: '自治体への寄付が実質2,000円の自己負担で返礼品を受け取れ、住民税等が控除される制度。',
      eligibility: '確定申告不要な給与所得者等で、寄付先が5自治体以内の場合はワンストップ特例が利用可能',
      benefitAmount: '寄付額から自己負担2,000円を除いた額が翌年度の税金から控除（上限は年収等により変動）',
      howToApply: '寄付時にワンストップ特例申請書を提出、または確定申告で寄付金控除を申告',
      applyWindow: '寄付した翌年1月10日必着でワンストップ特例申請書を提出',
      sourceNote: '寄付先自治体／総務省',
      relevantScenarios: [
        LifeStage.youngFamily,
        LifeStage.singleProfessional,
        LifeStage.preRetirement,
      ],
      reminderMonths: [12, 1],
    ),
    ProcedureInfo(
      id: 'shohisha_hotline',
      title: '消費者ホットライン(188)・消費生活センター',
      category: ProcedureCategory.consumerProtection,
      summary: '怪しい投資話や詐欺的な勧誘を受けた際に無料で相談できる公的な窓口。',
      eligibility: 'どなたでも利用可能',
      benefitAmount: '相談は原則無料',
      howToApply: '局番なしの「188」に電話するか、最寄りの消費生活センターへ相談',
      applyWindow: '被害に遭う前・遭った後どちらでも、迷ったらすぐ相談',
      sourceNote: '消費者庁／国民生活センター',
      relevantScenarios: [
        LifeStage.singleProfessional,
        LifeStage.preRetirement,
      ],
    ),
    ProcedureInfo(
      id: 'nenkin_kuridage',
      title: '年金の繰下げ受給',
      category: ProcedureCategory.pension,
      summary: '公的年金の受給開始を66歳以降に遅らせることで、受給額を増やせる制度。',
      eligibility: '老齢基礎年金・老齢厚生年金の受給資格がある人',
      benefitAmount: '繰下げ1ヶ月ごとに受給額が0.7%増加（最大75歳まで繰下げ可能）',
      howToApply: '受給開始時に年金事務所または年金相談センターで請求手続き',
      applyWindow: '65歳の受給権発生後、繰下げ待機し希望時期に請求',
      sourceNote: '年金事務所／日本年金機構',
      relevantScenarios: [LifeStage.preRetirement],
    ),
    ProcedureInfo(
      id: 'nenkin_teikibin',
      title: 'ねんきん定期便・ねんきんネット',
      category: ProcedureCategory.pension,
      summary: '将来の年金見込み額や納付記録を確認できる公的なサービス。',
      eligibility: '国民年金・厚生年金の被保険者',
      benefitAmount: '見込み額の確認サービス（無料）',
      howToApply: '毎年誕生月に郵送される定期便を確認、または「ねんきんネット」に登録してオンライン確認',
      applyWindow: 'いつでも確認可能（誕生月に定期便が届く）',
      sourceNote: '日本年金機構',
      relevantScenarios: [
        LifeStage.preRetirement,
        LifeStage.singleProfessional,
      ],
    ),
    ProcedureInfo(
      id: 'seimei_hoken_koujo',
      title: '生命保険料控除',
      category: ProcedureCategory.insurance,
      summary: '支払った生命保険料に応じて所得控除が受けられる制度。',
      eligibility: '生命保険・個人年金保険・介護医療保険の保険料を支払っている人',
      benefitAmount: '保険料区分ごとに最大4万円、合計最大12万円の所得控除（制度上限）',
      howToApply: '年末調整（会社員）または確定申告で保険会社発行の控除証明書を添付',
      applyWindow: '年末調整時期（10〜12月）または確定申告時期（2〜3月）',
      sourceNote: '加入している保険会社／税務署',
      relevantScenarios: [
        LifeStage.preRetirement,
        LifeStage.youngFamily,
      ],
      reminderMonths: [10, 11],
    ),
    ProcedureInfo(
      id: 'iryohi_koujo',
      title: '医療費控除',
      category: ProcedureCategory.tax,
      summary: '年間の医療費が一定額を超えた場合に所得控除が受けられる制度。',
      eligibility: '本人または生計を一にする家族の医療費が年間10万円（所得により変動）を超えた場合',
      benefitAmount: '実際に支払った医療費等に応じて所得控除（上限200万円）',
      howToApply: '確定申告で医療費控除の明細書を作成し提出（医療費通知やレシートを保管）',
      applyWindow: '確定申告時期（2月中旬〜3月中旬）。還付申告は5年間さかのぼって申告可能',
      sourceNote: '税務署／国税庁',
      relevantScenarios: [
        LifeStage.preRetirement,
        LifeStage.youngFamily,
      ],
      reminderMonths: [2, 3],
    ),
    ProcedureInfo(
      id: 'zaikei_chochiku',
      title: '財形貯蓄制度',
      category: ProcedureCategory.investment,
      summary: '勤務先を通じて給与天引きで積立できる貯蓄制度。住宅財形・年金財形は利子が非課税になる場合がある。',
      eligibility: '財形貯蓄制度を導入している企業の従業員',
      benefitAmount: '住宅財形・年金財形は合計550万円まで利子等非課税（条件あり）',
      howToApply: '勤務先の人事・総務部門に申込書を提出',
      applyWindow: '入社時または制度導入時にいつでも申込可能',
      sourceNote: '勤務先の人事部門',
      relevantScenarios: [LifeStage.singleProfessional],
    ),
    ProcedureInfo(
      id: 'koukyoiryohi',
      title: '高額療養費制度',
      category: ProcedureCategory.insurance,
      summary: '医療機関や薬局で支払った医療費が月の上限額を超えた場合、超えた分が払い戻される制度。',
      eligibility: '公的医療保険（健康保険・国民健康保険等）の加入者',
      benefitAmount: '年齢・所得に応じた自己負担限度額を超えた分が払い戻し（限度額適用認定証を使えば窓口負担も軽減）',
      howToApply: '加入する健康保険へ支給申請書を提出。事前に「限度額適用認定証」を取得すると窓口負担を抑えられる。',
      applyWindow: '診療を受けた月の翌月以降いつでも申請可能（2年で時効）',
      sourceNote: '加入している健康保険組合・協会けんぽ・市区町村国保',
      relevantScenarios: [
        LifeStage.youngFamily,
        LifeStage.singleProfessional,
        LifeStage.preRetirement,
      ],
    ),
    ProcedureInfo(
      id: 'shobyo_teate',
      title: '傷病手当金',
      category: ProcedureCategory.insurance,
      summary: '病気やけがで働けず給与が支払われない場合に、健康保険から生活費の一部が支給される制度。',
      eligibility: '健康保険加入者（会社員等）で、連続3日間を含み4日以上仕事を休んだ場合',
      benefitAmount: '標準報酬日額の約3分の2を、最長1年6ヶ月支給',
      howToApply: '勤務先経由で加入健康保険に傷病手当金支給申請書を提出（医師の意見書が必要）',
      applyWindow: '休業4日目以降、随時申請可能',
      sourceNote: '加入している健康保険組合・協会けんぽ',
      relevantScenarios: [
        LifeStage.youngFamily,
        LifeStage.singleProfessional,
      ],
    ),
    ProcedureInfo(
      id: 'ikuji_kyugyo_kyufu',
      title: '育児休業給付金',
      category: ProcedureCategory.childcare,
      summary: '育児休業を取得し給与が支払われない場合に、雇用保険から給付が受けられる制度。',
      eligibility: '雇用保険加入者で1歳未満（延長で最長2歳）の子を養育するために育休を取得した人',
      benefitAmount: '休業開始時賃金の67%（180日経過後は50%）を目安に支給',
      howToApply: '勤務先を通じてハローワークに申請（原則2ヶ月ごとの支給申請）',
      applyWindow: '育休開始後、勤務先の案内に沿って申請',
      sourceNote: 'ハローワーク（公共職業安定所）／勤務先',
      relevantScenarios: [LifeStage.youngFamily],
    ),
    ProcedureInfo(
      id: 'shussan_teate',
      title: '出産手当金',
      category: ProcedureCategory.childcare,
      summary: '出産のために会社を休み給与が支払われない期間、健康保険から生活費の一部が支給される制度。',
      eligibility: '健康保険加入者本人が出産のため休業した場合（産前42日・産後56日が目安）',
      benefitAmount: '標準報酬日額の約3分の2を、休業期間に応じて支給',
      howToApply: '勤務先経由で加入健康保険に出産手当金支給申請書を提出',
      applyWindow: '産休開始後、出産後にまとめて申請するのが一般的',
      sourceNote: '加入している健康保険組合・協会けんぽ',
      relevantScenarios: [LifeStage.youngFamily],
    ),
    ProcedureInfo(
      id: 'kodomo_iryohi_jyosei',
      title: 'こども医療費助成',
      category: ProcedureCategory.childcare,
      summary: '子どもの医療費の自己負担分を自治体が助成する制度。対象年齢や助成範囲は市区町村により異なる。',
      eligibility: '対象年齢の子どもを養育する世帯（所得制限は自治体により異なる）',
      benefitAmount: '通院・入院の自己負担が無料〜一部負担に軽減（自治体により条件が大きく異なる）',
      howToApply: '市区町村窓口で「こども医療証」の交付を受け、医療機関で提示',
      applyWindow: '出生後・転入後、早めに市区町村窓口へ申請',
      sourceNote: 'お住まいの市区町村窓口',
      relevantScenarios: [LifeStage.youngFamily],
    ),
    ProcedureInfo(
      id: 'koureisha_koyou_keizoku',
      title: '高年齢雇用継続給付',
      category: ProcedureCategory.pension,
      summary: '60歳以降も働き続けるが賃金が低下した場合に、雇用保険から給付を受けられる制度。',
      eligibility: '雇用保険の被保険者期間が5年以上あり、60歳時点と比べ賃金が75%未満に低下した60〜65歳の人',
      benefitAmount: '低下後の賃金の最大10%程度を目安に支給（低下率により変動）',
      howToApply: '勤務先を通じてハローワークに支給申請',
      applyWindow: '60歳到達後、賃金低下が確認され次第申請',
      sourceNote: 'ハローワーク（公共職業安定所）／勤務先',
      relevantScenarios: [LifeStage.preRetirement],
    ),
    ProcedureInfo(
      id: 'kyouiku_kunren_kyufu',
      title: '教育訓練給付制度',
      category: ProcedureCategory.education,
      summary: '働く人のスキルアップを支援するため、対象講座の受講費用の一部が支給される雇用保険の制度。',
      eligibility: '雇用保険の加入期間等の要件を満たす在職者・離職者',
      benefitAmount: '受講費用の20%〜最大70%程度（講座の種類により支給率・上限額が異なる）',
      howToApply: '受講前にハローワークで受給資格を確認し、受講修了後に必要書類を提出',
      applyWindow: '受講開始前に要件確認、修了後1ヶ月以内に支給申請',
      sourceNote: 'ハローワーク（公共職業安定所）',
      relevantScenarios: [LifeStage.singleProfessional],
    ),
    ProcedureInfo(
      id: 'juutaku_shikin_zouyo',
      title: '住宅取得等資金の贈与税非課税措置',
      category: ProcedureCategory.housing,
      summary: '親や祖父母から住宅取得資金の贈与を受けた場合に、一定額まで贈与税が非課税になる制度。',
      eligibility: '直系尊属から住宅取得等資金の贈与を受け、一定の要件を満たす住宅を取得する人',
      benefitAmount: '省エネ等住宅で最大1,000万円、それ以外で最大500万円が非課税（金額は年度により変動）',
      howToApply: '贈与を受けた翌年に確定申告（贈与税の申告）で非課税の特例を適用',
      applyWindow: '贈与を受けた年の翌年2月1日〜3月15日の贈与税申告期間',
      sourceNote: '税務署／国税庁',
      relevantScenarios: [LifeStage.youngFamily],
      reminderMonths: [2, 3],
    ),
    ProcedureInfo(
      id: 'jishin_hoken_koujo',
      title: '地震保険料控除',
      category: ProcedureCategory.insurance,
      summary: '支払った地震保険料に応じて所得控除が受けられる制度。',
      eligibility: '地震保険料を支払っている人（火災保険とセット契約が一般的）',
      benefitAmount: '所得税で最大5万円、住民税で最大2.5万円の所得控除',
      howToApply: '年末調整（会社員）または確定申告で保険会社発行の控除証明書を添付',
      applyWindow: '年末調整時期（10〜12月）または確定申告時期（2〜3月）',
      sourceNote: '加入している保険会社／税務署',
      relevantScenarios: [
        LifeStage.youngFamily,
        LifeStage.preRetirement,
      ],
      reminderMonths: [10, 11],
    ),
  ];

  static final Map<String, ProcedureInfo> _byId = {
    for (final p in all) p.id: p,
  };

  /// ID のリストから該当する制度情報を取得（存在しないIDは無視）
  static List<ProcedureInfo> byIds(List<String> ids) {
    return ids
        .map((id) => _byId[id])
        .whereType<ProcedureInfo>()
        .toList(growable: false);
  }

  /// ライフステージに関連する制度を一覧取得（シーンで個別に紐付いていないものも含む）
  static List<ProcedureInfo> byLifeStage(LifeStage stage) {
    return all
        .where((p) => p.relevantScenarios.contains(stage))
        .toList(growable: false);
  }

  /// 申請期限のリマインダーが設定されている全制度
  static List<ProcedureInfo> withReminders() {
    return all.where((p) => p.reminderMonths.isNotEmpty).toList(growable: false);
  }
}
