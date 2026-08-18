import '../../../procedures/domain/models/procedure_info.dart';

enum RoleplayScenarioType { youngFamily, singleProfessional, preRetirement }

extension RoleplayScenarioTypeX on RoleplayScenarioType {
  /// procedures フィーチャーの LifeStage に対応させるためのマッピング。
  LifeStage get lifeStage {
    switch (this) {
      case RoleplayScenarioType.youngFamily:
        return LifeStage.youngFamily;
      case RoleplayScenarioType.singleProfessional:
        return LifeStage.singleProfessional;
      case RoleplayScenarioType.preRetirement:
        return LifeStage.preRetirement;
    }
  }
}

class RoleplayDecision {
  final String question;
  final List<String> options;
  final List<int> scoreDeltas;
  final String? explanation;

  /// このシーンに関連する制度・手続き・補助金の ID（ProcedureLibrary 参照）
  final List<String> relatedProcedureIds;

  RoleplayDecision({
    required this.question,
    required this.options,
    required this.scoreDeltas,
    this.explanation,
    this.relatedProcedureIds = const [],
  });
}

class RoleplayScenario {
  final RoleplayScenarioType type;
  final String title;
  final String description;
  final int annualIncome;
  final String familyComposition;
  final List<RoleplayDecision> decisions;

  RoleplayScenario({
    required this.type,
    required this.title,
    required this.description,
    required this.annualIncome,
    required this.familyComposition,
    required this.decisions,
  });
}

class RoleplayResult {
  final RoleplayScenarioType scenario;
  final List<int> selectedAnswers;
  final int score;
  final DateTime createdAt;

  RoleplayResult({
    required this.scenario,
    required this.selectedAnswers,
    required this.score,
    required this.createdAt,
  });

  factory RoleplayResult.fromJson(Map<String, dynamic> json) {
    return RoleplayResult(
      scenario: RoleplayScenarioType.values[json['scenario'] as int],
      selectedAnswers: List<int>.from(json['selectedAnswers'] as List),
      score: json['score'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scenario': scenario.index,
      'selectedAnswers': selectedAnswers,
      'score': score,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class RoleplayScenarios {
  /// 全シナリオのリスト（選択画面で使用）
  static List<RoleplayScenario> all() => [
        youngFamily(),
        singleProfessional(),
        preRetirement(),
      ];

  static RoleplayScenario byType(RoleplayScenarioType type) {
    switch (type) {
      case RoleplayScenarioType.youngFamily:
        return youngFamily();
      case RoleplayScenarioType.singleProfessional:
        return singleProfessional();
      case RoleplayScenarioType.preRetirement:
        return preRetirement();
    }
  }

  static RoleplayScenario youngFamily() {
    return RoleplayScenario(
      type: RoleplayScenarioType.youngFamily,
      title: '年収400万・子ども2人の家計判断',
      description: 'あなたは年収400万円、子ども2人（小学生・幼稚園児）の親です。以下の判断をしてみましょう。',
      annualIncome: 4000000,
      familyComposition: '夫婦+子ども2人',
      decisions: [
        RoleplayDecision(
          question: 'ボーナス20万円が入りました。どう使いますか？',
          options: ['全額貯蓄する', '半分貯蓄・半分レジャーに使う', '全額レジャーに使う'],
          scoreDeltas: [10, 5, 0],
          explanation: '教育費・老後資金のためにも、ボーナスの一部は貯蓄に回すことが推奨されます。',
        ),
        RoleplayDecision(
          question: '子どもの教育資金、どう準備しますか？',
          options: ['学資保険で計画的に積立', '銀行預金でコツコツ貯める', '特に準備していない'],
          scoreDeltas: [10, 7, 0],
          explanation: '学資保険や積立NISAなど、計画的な準備が教育資金の負担を軽減します。',
          relatedProcedureIds: ['koukou_shugaku', 'jido_teate', 'kodomo_iryohi_jyosei'],
        ),
        RoleplayDecision(
          question: '突然の出費（家電故障¥5万）が発生。どう対応しますか？',
          options: ['緊急予備資金から支払う', 'クレジットカードのリボ払い', '消費者金融で借りる'],
          scoreDeltas: [10, 3, -5],
          explanation: '生活費3-6ヶ月分の緊急予備資金があると、突発的な出費にも冷静に対応できます。',
        ),
        RoleplayDecision(
          question: '住宅ローンの金利タイプ、どちらを選びますか？',
          options: ['固定金利で返済額を安定させる', '変動金利で当初の負担を抑える', 'よく分からず勧められるまま契約'],
          scoreDeltas: [8, 6, -3],
          explanation: '金利タイプは家計の安定性に直結します。仕組みを理解して選ぶことが最も重要です。',
          relatedProcedureIds: ['juutaku_loan_koujo', 'juutaku_shikin_zouyo'],
        ),
        RoleplayDecision(
          question: '毎月の家計に少し余裕が。どうしますか？',
          options: ['つみたてNISAで長期投資を始める', '使わず全部普通預金へ', '生活水準を上げて外食を増やす'],
          scoreDeltas: [10, 5, 0],
          explanation: '若い家族世帯は運用期間を長く取れるため、少額でも長期投資を始める好機です。',
          relatedProcedureIds: ['nisa', 'ideco'],
        ),
      ],
    );
  }

  static RoleplayScenario singleProfessional() {
    return RoleplayScenario(
      type: RoleplayScenarioType.singleProfessional,
      title: '年収500万・独身社会人の資産形成',
      description: 'あなたは年収500万円の独身会社員（28歳）。自由に使えるお金が多い今、将来に向けた判断をしてみましょう。',
      annualIncome: 5000000,
      familyComposition: '独身・一人暮らし',
      decisions: [
        RoleplayDecision(
          question: '毎月の手取りから、まず何をしますか？',
          options: ['先取りで一定額を自動積立', '余ったら貯金', '全部使い切る'],
          scoreDeltas: [10, 4, -3],
          explanation: '収入が多い独身期こそ、先取り貯蓄・投資で資産形成の土台を作る絶好のタイミングです。',
          relatedProcedureIds: ['zaikei_chochiku'],
        ),
        RoleplayDecision(
          question: '会社にiDeCoの案内が。どうしますか？',
          options: ['節税メリットを理解して加入', '内容を調べてから検討', '面倒なので無視'],
          scoreDeltas: [10, 6, 0],
          explanation: 'iDeCoは掛金が全額所得控除。若いうちから始めるほど複利と節税の効果が大きくなります。',
          relatedProcedureIds: ['ideco'],
        ),
        RoleplayDecision(
          question: '同僚に「絶対儲かる」という投資話を持ちかけられました。',
          options: ['きっぱり断る', '少額なら試す', '貯金を全額つぎ込む'],
          scoreDeltas: [10, 2, -10],
          explanation: '「絶対儲かる」は詐欺の典型的な誘い文句。うまい話には必ず裏があります。',
          relatedProcedureIds: ['shohisha_hotline'],
        ),
        RoleplayDecision(
          question: 'ボーナスでほしかった高級時計（30万円）。どうしますか？',
          options: ['予算内なら計画的に購入', 'リボ払いで今すぐ買う', 'カードローンを組んで買う'],
          scoreDeltas: [7, 0, -8],
          explanation: '欲しいものを買うのは悪くありませんが、借金や高金利のリボ払いに頼るのは避けましょう。',
        ),
        RoleplayDecision(
          question: '将来のために今から準備すべきものは？',
          options: ['生活防衛資金＋長期投資の両立', '保険にたくさん入る', '特に何もしない'],
          scoreDeltas: [10, 3, 0],
          explanation: 'まず生活防衛資金を確保し、余裕資金で長期投資。独身期の手厚すぎる保険は不要なことが多いです。',
          relatedProcedureIds: ['nisa', 'furusato', 'kyouiku_kunren_kyufu'],
        ),
      ],
    );
  }

  static RoleplayScenario preRetirement() {
    return RoleplayScenario(
      type: RoleplayScenarioType.preRetirement,
      title: '年収600万・退職前世代の老後準備',
      description: 'あなたは年収600万円の会社員（55歳）。定年まであと10年。老後を見据えた判断をしてみましょう。',
      annualIncome: 6000000,
      familyComposition: '夫婦（子どもは独立）',
      decisions: [
        RoleplayDecision(
          question: '退職金の運用方針を考えます。どうしますか？',
          options: ['リスクを抑えた分散運用', '銀行の勧める商品に一括投資', 'ハイリスク商品で一発逆転を狙う'],
          scoreDeltas: [10, 3, -8],
          explanation: '退職が近い世代は、大きな損失から回復する時間が限られます。リスクを抑えた分散運用が基本です。',
          relatedProcedureIds: ['nisa'],
        ),
        RoleplayDecision(
          question: '公的年金の受給、いつから始めますか？',
          options: ['繰下げ受給で受給額を増やすか検討', '65歳から普通に受給', '仕組みを知らず放置'],
          scoreDeltas: [9, 6, -2],
          explanation: '年金は繰下げると受給額が増えます。健康状態や就労状況を踏まえて受給開始年齢を検討しましょう。',
          relatedProcedureIds: ['nenkin_kuridage', 'koureisha_koyou_keizoku'],
        ),
        RoleplayDecision(
          question: '老後の生活費、把握していますか？',
          options: ['ねんきん定期便で見込み額を確認済み', 'なんとなく大丈夫だと思う', '考えたことがない'],
          scoreDeltas: [10, 3, 0],
          explanation: '「ねんきん定期便」やねんきんネットで受給見込みを確認し、不足分を逆算するのが老後設計の第一歩です。',
          relatedProcedureIds: ['nenkin_teikibin'],
        ),
        RoleplayDecision(
          question: '子どもが独立し保険を見直すことに。どうしますか？',
          options: ['過剰な死亡保障を減らし保険料を節約', '不安なので今のまま継続', '逆に保障を増やす'],
          scoreDeltas: [9, 4, 0],
          explanation: '扶養する家族が減れば大きな死亡保障の必要性は下がります。ライフステージに応じた見直しが有効です。',
          relatedProcedureIds: ['seimei_hoken_koujo', 'iryohi_koujo', 'koukyoiryohi', 'jishin_hoken_koujo'],
        ),
        RoleplayDecision(
          question: '「高利回り確実」をうたう海外不動産の勧誘が。',
          options: ['きっぱり断る', '話だけ聞いて検討', '退職金をつぎ込む'],
          scoreDeltas: [10, 3, -10],
          explanation: '退職金を狙った投資詐欺は後を絶ちません。「確実に高利回り」は存在しないと考えましょう。',
          relatedProcedureIds: ['shohisha_hotline'],
        ),
      ],
    );
  }
}
