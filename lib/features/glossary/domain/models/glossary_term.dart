/// 金融用語辞典のカテゴリ
enum GlossaryCategory { savings, tax, invest, insurance, general }

/// 金融用語の1エントリ
class GlossaryTerm {
  final String id;
  final String term;
  final String reading;
  final GlossaryCategory category;
  final String definition;
  final String? example;

  const GlossaryTerm({
    required this.id,
    required this.term,
    required this.reading,
    required this.category,
    required this.definition,
    this.example,
  });
}

class GlossaryCategoryInfo {
  static const Map<GlossaryCategory, String> displayNames = {
    GlossaryCategory.savings: '貯蓄',
    GlossaryCategory.tax: '税金',
    GlossaryCategory.invest: '投資',
    GlossaryCategory.insurance: '保険',
    GlossaryCategory.general: '一般',
  };
}

/// 金融用語データベース
class GlossaryData {
  static const List<GlossaryTerm> terms = [
    // --- 一般 ---
    GlossaryTerm(
      id: 'g_compound',
      term: '複利',
      reading: 'ふくり',
      category: GlossaryCategory.general,
      definition: '利子が元本に組み込まれ、その利子にもさらに利子がつく仕組み。長期運用ほど効果が大きくなる。',
      example: '100万円を年5%複利で運用すると、10年後は約163万円になる。',
    ),
    GlossaryTerm(
      id: 'g_simple_interest',
      term: '単利',
      reading: 'たんり',
      category: GlossaryCategory.general,
      definition: '元本に対してのみ利子がつく計算方法。利子は元本に組み込まれない。',
      example: '100万円を年5%単利なら、毎年5万円ずつ増える。',
    ),
    GlossaryTerm(
      id: 'g_inflation',
      term: 'インフレ',
      reading: 'いんふれ',
      category: GlossaryCategory.general,
      definition: '物価が継続的に上昇し、お金の価値が下がること。インフレーションの略。',
      example: '年2%のインフレでは、同じ商品が翌年は102円になる。',
    ),
    GlossaryTerm(
      id: 'g_deflation',
      term: 'デフレ',
      reading: 'でふれ',
      category: GlossaryCategory.general,
      definition: '物価が継続的に下落し、お金の価値が上がること。デフレーションの略。',
    ),
    GlossaryTerm(
      id: 'g_emergency_fund',
      term: '生活防衛資金',
      reading: 'せいかつぼうえいしきん',
      category: GlossaryCategory.general,
      definition: '失業や病気など不測の事態に備える現金。生活費の3〜6ヶ月分が目安とされる。',
    ),
    GlossaryTerm(
      id: 'g_opportunity_cost',
      term: '機会費用',
      reading: 'きかいひよう',
      category: GlossaryCategory.general,
      definition: 'ある選択をしたことで得られなくなった、別の選択肢の価値のこと。',
      example: '貯金を使わず投資に回せば得られたはずの利益も機会費用の一種。',
    ),
    // --- 貯蓄 ---
    GlossaryTerm(
      id: 'g_payoff',
      term: 'ペイオフ',
      reading: 'ぺいおふ',
      category: GlossaryCategory.savings,
      definition: '金融機関が破綻したとき、預金保険制度で1金融機関あたり元本1,000万円とその利息までが保護される制度。',
    ),
    GlossaryTerm(
      id: 'g_saki_dori',
      term: '先取り貯蓄',
      reading: 'さきどりちょちく',
      category: GlossaryCategory.savings,
      definition: '給料が入ったら使う前に一定額を貯蓄に回す方法。確実に貯まりやすい。',
    ),
    GlossaryTerm(
      id: 'g_fixed_cost',
      term: '固定費',
      reading: 'こていひ',
      category: GlossaryCategory.savings,
      definition: '家賃・通信費・保険料など、毎月ほぼ一定額かかる支出。見直すと節約効果が継続する。',
    ),
    GlossaryTerm(
      id: 'g_variable_cost',
      term: '変動費',
      reading: 'へんどうひ',
      category: GlossaryCategory.savings,
      definition: '食費・娯楽費など、月によって金額が変わる支出。',
    ),
    GlossaryTerm(
      id: 'g_72_rule',
      term: '72の法則',
      reading: 'ななじゅうにのほうそく',
      category: GlossaryCategory.savings,
      definition: '「72 ÷ 金利(%)」で、複利運用でお金が2倍になるおおよその年数がわかる法則。',
      example: '年利6%なら72÷6=12年で2倍になる目安。',
    ),
    // --- 税金 ---
    GlossaryTerm(
      id: 'g_furusato',
      term: 'ふるさと納税',
      reading: 'ふるさとのうぜい',
      category: GlossaryCategory.tax,
      definition: '好きな自治体に寄付すると、自己負担2,000円を除いた額が所得税・住民税から控除される制度。返礼品ももらえる。',
    ),
    GlossaryTerm(
      id: 'g_deduction',
      term: '所得控除',
      reading: 'しょとくこうじょ',
      category: GlossaryCategory.tax,
      definition: '税金を計算する前の所得から差し引ける金額。課税対象額が減り、税負担が軽くなる。',
    ),
    GlossaryTerm(
      id: 'g_tax_credit',
      term: '税額控除',
      reading: 'ぜいがくこうじょ',
      category: GlossaryCategory.tax,
      definition: '計算後の税額から直接差し引ける控除。所得控除より減税効果が大きいことが多い。',
    ),
    GlossaryTerm(
      id: 'g_progressive',
      term: '累進課税',
      reading: 'るいしんかぜい',
      category: GlossaryCategory.tax,
      definition: '所得が高いほど税率が上がる仕組み。日本の所得税は5%〜45%の7段階。',
    ),
    GlossaryTerm(
      id: 'g_nenmatsu',
      term: '年末調整',
      reading: 'ねんまつちょうせい',
      category: GlossaryCategory.tax,
      definition: '毎月天引きされた所得税と本来の税額の差を、年末に会社が精算する手続き。',
    ),
    GlossaryTerm(
      id: 'g_kakutei',
      term: '確定申告',
      reading: 'かくていしんこく',
      category: GlossaryCategory.tax,
      definition: '1年間の所得と税額を自分で計算し税務署に申告する手続き。医療費控除や副業所得などで必要。',
    ),
    // --- 投資 ---
    GlossaryTerm(
      id: 'g_nisa',
      term: 'NISA',
      reading: 'にーさ',
      category: GlossaryCategory.invest,
      definition: '投資で得た利益が非課税になる制度。2024年からの新NISAは年間最大360万円まで投資可能。',
    ),
    GlossaryTerm(
      id: 'g_ideco',
      term: 'iDeCo',
      reading: 'いでこ',
      category: GlossaryCategory.invest,
      definition: '個人型確定拠出年金。掛金が全額所得控除になり、運用益も非課税の私的年金制度。',
    ),
    GlossaryTerm(
      id: 'g_index_fund',
      term: 'インデックスファンド',
      reading: 'いんでっくすふぁんど',
      category: GlossaryCategory.invest,
      definition: '日経平均やS&P500などの指数に連動する投資信託。低コストで分散投資できる。',
    ),
    GlossaryTerm(
      id: 'g_dollar_cost',
      term: 'ドルコスト平均法',
      reading: 'どるこすとへいきんほう',
      category: GlossaryCategory.invest,
      definition: '一定額を定期的に買い続ける投資法。高いとき少なく安いとき多く買え、平均単価を抑えられる。',
    ),
    GlossaryTerm(
      id: 'g_diversify',
      term: '分散投資',
      reading: 'ぶんさんとうし',
      category: GlossaryCategory.invest,
      definition: '資産・地域・時間を分けて投資し、リスクを抑える手法。「卵を一つのカゴに盛るな」の格言で有名。',
    ),
    GlossaryTerm(
      id: 'g_benchmark',
      term: 'ベンチマーク',
      reading: 'べんちまーく',
      category: GlossaryCategory.invest,
      definition: '投資信託の運用成績を比較する基準となる指数。日経平均やTOPIXなど。',
    ),
    GlossaryTerm(
      id: 'g_trust_fee',
      term: '信託報酬',
      reading: 'しんたくほうしゅう',
      category: GlossaryCategory.invest,
      definition: '投資信託を保有している間、毎日残高から差し引かれる運用管理費用。長期投資では低いほど有利。',
    ),
    GlossaryTerm(
      id: 'g_dividend',
      term: '配当金',
      reading: 'はいとうきん',
      category: GlossaryCategory.invest,
      definition: '企業が利益の一部を株主に分配するお金。保有株数に応じて支払われる。',
    ),
    GlossaryTerm(
      id: 'g_leverage',
      term: 'レバレッジ',
      reading: 'ればれっじ',
      category: GlossaryCategory.invest,
      definition: '自己資金以上の取引を行うこと。利益も損失も拡大するためリスクが高い。',
    ),
    GlossaryTerm(
      id: 'g_portfolio',
      term: 'ポートフォリオ',
      reading: 'ぽーとふぉりお',
      category: GlossaryCategory.invest,
      definition: '保有する資産の組み合わせ・配分のこと。株・債券・現金のバランスがリスクを左右する。',
    ),
    // --- 保険 ---
    GlossaryTerm(
      id: 'g_kakesute',
      term: '掛け捨て型保険',
      reading: 'かけすてがたほけん',
      category: GlossaryCategory.insurance,
      definition: '解約返戻金がない代わりに保険料が割安な保険。同じ保障を安く得られる。',
    ),
    GlossaryTerm(
      id: 'g_kogaku',
      term: '高額療養費制度',
      reading: 'こうがくりょうようひせいど',
      category: GlossaryCategory.insurance,
      definition: '医療費の自己負担が月の上限額を超えた分が払い戻される公的制度。民間医療保険の要否判断の鍵。',
    ),
    GlossaryTerm(
      id: 'g_shakai_hoken',
      term: '社会保険',
      reading: 'しゃかいほけん',
      category: GlossaryCategory.insurance,
      definition: '健康保険・厚生年金・雇用保険・労災・介護保険などの公的保険の総称。',
    ),
    GlossaryTerm(
      id: 'g_tokuyaku',
      term: '特約',
      reading: 'とくやく',
      category: GlossaryCategory.insurance,
      definition: '主契約に付け加えるオプションの保障。手厚くできるが、不要な特約は保険料の無駄になる。',
    ),
    GlossaryTerm(
      id: 'g_izoku_nenkin',
      term: '遺族年金',
      reading: 'いぞくねんきん',
      category: GlossaryCategory.insurance,
      definition: '生計を支える人が亡くなったとき、遺族に支給される公的年金。死亡保障を考える前提になる。',
    ),
  ];

  static List<GlossaryTerm> byCategory(GlossaryCategory category) =>
      terms.where((t) => t.category == category).toList();

  static List<GlossaryTerm> search(String keyword) {
    if (keyword.trim().isEmpty) return terms;
    final k = keyword.toLowerCase();
    return terms
        .where((t) =>
            t.term.toLowerCase().contains(k) ||
            t.reading.contains(k) ||
            t.definition.toLowerCase().contains(k))
        .toList();
  }
}
