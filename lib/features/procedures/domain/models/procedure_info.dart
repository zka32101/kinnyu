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
        return Colors.cyan;
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
      eligibility: '高校生年代までの子どもを養育する世帯（所得制限なし）',
      benefitAmount: '月額目安 1万円〜1.5万円／人。第3子以降は月額3万円（年齢・人数により変動）',
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
      summary: '高校の授業料負担を軽減する国の制度。学校種別（公立・私立）に応じて支給額が変わる。',
      eligibility: '高等学校等に在学する生徒がいる世帯（所得制限は撤廃済み）',
      benefitAmount: '公立高校授業料相当額〜私立向け加算あり（学校種別により変動）',
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
      benefitAmount: '年末ローン残高の0.7%程度を最大13年間控除。ただし新築住宅は省エネ基準等の認定を満たさないと控除額が大きく減る（対象外になる）場合があるため要確認',
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
      title: '消費者ホットライン（188）・消費生活センター',
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
      benefitAmount: '所得税は保険料区分ごとに最大4万円・合計最大12万円、住民税は区分ごとに最大2.8万円・合計最大7万円の所得控除（制度上限）',
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
      benefitAmount: '休業開始時賃金の67%（180日経過後は50%）を目安に支給。両親そろって取得する場合等の要件を満たすと、出生後一定期間（最大28日）は実質8割相当まで給付が上乗せされる制度もある',
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
      benefitAmount: '受講費用の20%〜最大70%程度（資格取得・早期の再就職等の要件を満たす場合は最大80%程度まで引き上げられることがある。講座の種類により支給率・上限額が異なる）',
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
    ProcedureInfo(
      id: 'jido_fuyo_teate',
      title: '児童扶養手当',
      category: ProcedureCategory.childcare,
      summary: 'ひとり親家庭等の生活の安定と自立を支援するために支給される手当。',
      eligibility: '18歳到達年度末までの子を養育するひとり親家庭等（所得制限あり）',
      benefitAmount: '月額目安 全部支給で4万円台〜（所得に応じて一部支給に減額。第2子以降は加算あり）',
      howToApply: 'お住まいの市区町村窓口で認定請求書等を提出',
      applyWindow: 'ひとり親になった時点でできるだけ早めに',
      sourceNote: 'お住まいの市区町村窓口／こども家庭庁',
      relevantScenarios: [LifeStage.youngFamily, LifeStage.singleProfessional],
    ),
    ProcedureInfo(
      id: 'shussan_kosodate_ouen',
      title: '出産・子育て応援交付金（出産応援ギフト・子育て応援ギフト）',
      category: ProcedureCategory.childcare,
      summary: '妊娠届出時・出生届出後の面談等を通じて、経済的支援（ギフト）を受けられる国の事業。',
      eligibility: '妊娠届出をした方・出産した方（自治体経由で実施）',
      benefitAmount: '妊娠時・出産後それぞれ5万円相当が目安（現金・クーポン等、形式は自治体により異なる）',
      howToApply: '母子健康手帳交付時の面談、出生後の面談等を経て自治体から案内',
      applyWindow: '妊娠届出時・出産後の面談時',
      sourceNote: 'お住まいの市区町村窓口／こども家庭庁',
      relevantScenarios: [LifeStage.youngFamily],
    ),
    ProcedureInfo(
      id: 'koutou_kyoiku_shugaku_shien',
      title: '高等教育の修学支援新制度（大学等の授業料減免・給付型奨学金）',
      category: ProcedureCategory.education,
      summary: '大学・短大・高専・専門学校の授業料等減免と給付型奨学金を組み合わせて支援する制度。',
      eligibility: '住民税非課税世帯及びそれに準ずる世帯の学生（成績基準等あり）',
      benefitAmount: '授業料等減免（学校種別ごとに上限あり）と給付型奨学金（世帯収入により変動）',
      howToApply: '在学（予定）校または日本学生支援機構（JASSO）を通じて申請',
      applyWindow: '進学前の予約採用または在学中の在学採用（募集時期は学校の案内による）',
      sourceNote: '日本学生支援機構（JASSO）／在学校',
      relevantScenarios: [LifeStage.youngFamily],
      reminderMonths: [4, 5],
    ),
    ProcedureInfo(
      id: 'kyushokusha_shien',
      title: '求職者支援制度（求職者支援訓練）',
      category: ProcedureCategory.education,
      summary: '雇用保険を受給できない求職者が、無料の職業訓練を受けながら給付金を受け取れる制度。',
      eligibility: 'ハローワークに求職申込みをしている失業者で、雇用保険（失業給付）を受給できない・受給が終了した人等',
      benefitAmount: '職業訓練受講給付金 月10万円（収入・資産等の要件を満たす場合）＋通所手当等',
      howToApply: 'ハローワークで受講希望の申込みを行い、審査を経て訓練コースを受講',
      applyWindow: '随時（希望する訓練コースの開始時期に合わせる）',
      sourceNote: 'ハローワーク（公共職業安定所）',
      relevantScenarios: [LifeStage.singleProfessional],
    ),
    ProcedureInfo(
      id: 'kosodate_eco_home',
      title: '子育てエコホーム支援事業',
      category: ProcedureCategory.housing,
      summary: '子育て世帯・若者夫婦世帯等の住宅取得やリフォームに対し、省エネ性能等に応じて補助金が支給される事業。',
      eligibility: '子育て世帯・若者夫婦世帯等が省エネ性能を満たす住宅を新築・購入、またはリフォームする場合（年度により対象・要件が変動）',
      benefitAmount: '新築で数十万円〜100万円程度、リフォームで数万円〜60万円程度が目安（住宅性能・工事内容により変動）',
      howToApply: '登録事業者（施工会社等）を通じて交付申請',
      applyWindow: '予算上限に達し次第終了するため、着工前・年度の早めに要確認',
      sourceNote: '国土交通省／登録事業者（施工会社）',
      relevantScenarios: [LifeStage.youngFamily],
    ),
    ProcedureInfo(
      id: 'haigusha_koujo',
      title: '配偶者控除・配偶者特別控除',
      category: ProcedureCategory.tax,
      summary: '一定以下の所得の配偶者がいる場合に、所得税・住民税の負担が軽減される控除制度。',
      eligibility: '納税者本人の合計所得金額が1,000万円以下で、配偶者の所得が一定以下の場合',
      benefitAmount: '所得税で最大38万円、住民税で最大33万円の所得控除（本人・配偶者の所得により逓減）',
      howToApply: '年末調整（会社員）または確定申告で配偶者の所得情報を申告',
      applyWindow: '年末調整時期（11〜12月）または確定申告時期（2〜3月）',
      sourceNote: '勤務先の年末調整担当／税務署',
      relevantScenarios: [LifeStage.youngFamily, LifeStage.preRetirement],
      reminderMonths: [11, 12],
    ),
    ProcedureInfo(
      id: 'fuyou_koujo',
      title: '扶養控除',
      category: ProcedureCategory.tax,
      summary: '生計を一にする親族を扶養している場合に受けられる所得控除。',
      eligibility: '16歳以上の子や親などの親族を扶養しており、扶養親族の所得が一定以下の場合',
      benefitAmount: '一般の控除対象扶養親族で所得税38万円・住民税33万円が目安（年齢区分により金額が変動、16歳未満は対象外）',
      howToApply: '年末調整（会社員）または確定申告で申告',
      applyWindow: '年末調整時期（11〜12月）または確定申告時期（2〜3月）',
      sourceNote: '勤務先の年末調整担当／税務署',
      relevantScenarios: [LifeStage.youngFamily, LifeStage.preRetirement],
      reminderMonths: [11, 12],
    ),
    ProcedureInfo(
      id: 'fuka_nenkin',
      title: '付加年金',
      category: ProcedureCategory.pension,
      summary: '国民年金保険料に少額を上乗せして納めることで、将来の年金受給額を増やせる制度。',
      eligibility: '国民年金第1号被保険者（自営業・フリーランス等）',
      benefitAmount: '月額400円の付加保険料納付で、将来「200円×納付月数」が老齢基礎年金に上乗せ',
      howToApply: '市区町村窓口または年金事務所で申し込み',
      applyWindow: 'いつでも申込可能（国民年金基金との併用は不可）',
      sourceNote: '市区町村窓口／年金事務所',
      relevantScenarios: [LifeStage.singleProfessional],
    ),
    ProcedureInfo(
      id: 'kigyogata_dc',
      title: '企業型確定拠出年金（企業型DC）',
      category: ProcedureCategory.pension,
      summary: '勤務先が掛金を拠出し、従業員自身が運用商品を選んで老後資金を準備する制度。',
      eligibility: '企業型DCを導入している企業の従業員',
      benefitAmount: '運用益が非課税。マッチング拠出（従業員が上乗せ拠出）した分は所得控除の対象',
      howToApply: '勤務先の人事・総務部門を通じて加入し、運用商品を選択',
      applyWindow: '入社時または制度導入時',
      sourceNote: '勤務先の人事部門／運営管理機関',
      relevantScenarios: [LifeStage.singleProfessional, LifeStage.youngFamily],
    ),
    ProcedureInfo(
      id: 'kougaku_kaigo_service_hi',
      title: '高額介護サービス費',
      category: ProcedureCategory.insurance,
      summary: '介護保険サービスの自己負担額が月の上限を超えた場合、超えた分が払い戻される制度。',
      eligibility: '介護保険サービスを利用している要介護・要支援認定者',
      benefitAmount: '所得区分に応じた自己負担限度額を超えた分を払い戻し',
      howToApply: '市区町村から送付される申請書を提出（初回のみ申請、以降は自動払い戻しとなる自治体が多い）',
      applyWindow: 'サービス利用月の翌々月以降、随時（自治体により運用が異なる）',
      sourceNote: 'お住まいの市区町村の介護保険窓口',
      relevantScenarios: [LifeStage.preRetirement],
    ),
    ProcedureInfo(
      id: 'kaigo_kyugyo_kyufu',
      title: '介護休業給付金',
      category: ProcedureCategory.insurance,
      summary: '家族の介護のために休業し給与が支払われない場合に、雇用保険から給付が受けられる制度。',
      eligibility: '雇用保険加入者で、対象家族の介護のため通算93日を上限に休業した場合',
      benefitAmount: '休業開始時賃金の67%を目安に支給（対象家族1人につき通算93日まで、3回を上限に分割取得可）',
      howToApply: '勤務先を通じてハローワークに申請',
      applyWindow: '介護休業終了後、勤務先の案内に沿って申請',
      sourceNote: 'ハローワーク（公共職業安定所）／勤務先',
      relevantScenarios: [LifeStage.preRetirement, LifeStage.singleProfessional],
    ),
    ProcedureInfo(
      id: 'jukyo_kakuho_kyufukin',
      title: '住居確保給付金',
      category: ProcedureCategory.housing,
      summary: '離職・廃業や収入減少により住居を失うおそれがある人に、家賃相当額を一定期間支給する制度。',
      eligibility: '離職・廃業から2年以内、または収入が離職・廃業と同程度まで減少し、求職活動等を行う人（収入・資産要件あり）',
      benefitAmount: '地域・世帯人数に応じた家賃相当額を原則3ヶ月（最長9ヶ月まで延長可）支給',
      howToApply: 'お住まいの自立相談支援機関（生活困窮者自立相談窓口）に相談・申請',
      applyWindow: '収入減少・離職後、早めに相談窓口へ',
      sourceNote: '自立相談支援機関／福祉事務所',
      relevantScenarios: [LifeStage.singleProfessional],
    ),
    ProcedureInfo(
      id: 'seikatsu_fukushi_shikin',
      title: '生活福祉資金貸付制度',
      category: ProcedureCategory.consumerProtection,
      summary: '低所得世帯・高齢者世帯・障害者世帯等を対象に、生活再建等に必要な資金を無利子・低利子で貸し付ける公的制度。',
      eligibility: '低所得世帯・高齢者世帯・障害者世帯等（世帯の状況により貸付できる資金の種類が異なる）',
      benefitAmount: '資金の種類により貸付上限額・据置期間・返済期間が異なる（無利子または低利子）',
      howToApply: 'お住まいの市区町村社会福祉協議会に相談・申請',
      applyWindow: '生活に困った際、早めに相談窓口へ',
      sourceNote: '市区町村社会福祉協議会',
      relevantScenarios: [LifeStage.singleProfessional, LifeStage.preRetirement],
    ),
    ProcedureInfo(
      id: 'ideco_plus',
      title: 'iDeCo+（中小事業主掛金納付制度）',
      category: ProcedureCategory.investment,
      summary: '企業型年金のない中小企業が、従業員のiDeCo掛金に事業主として上乗せ拠出できる制度。',
      eligibility: '企業型年金を実施していない従業員300人以下の事業主とその従業員（iDeCo加入者）',
      benefitAmount: '事業主拠出分は損金算入可能。従業員は上乗せ分を含め掛金全額が所得控除の対象',
      howToApply: '事業主が国民年金基金連合会に届出を行い、労使合意のうえ従業員が加入',
      applyWindow: '労使合意が整い次第いつでも導入可能',
      sourceNote: '勤務先の人事部門／国民年金基金連合会',
      relevantScenarios: [LifeStage.singleProfessional],
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
