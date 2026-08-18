import '../../features/quiz/domain/models/question.dart';

/// 投資カテゴリの問題データ（投資信託・株式・分散投資・リスク・複利）
List<Question> investQuestions() => [
      Question(
        id: 'q_invest_001',
        category: QuizCategory.invest,
        difficulty: QuizDifficulty.easy,
        question: '投資信託の「ベンチマーク」とは何ですか？',
        options: ['最低投資額', '比較対象となる指数', '手数料', '運用期間'],
        correctAnswerIndex: 1,
        explanation: 'ベンチマークは、ファンドの運用成績を比較する基準となる指数（日経平均やS&P500など）です。',
      ),
      Question(
        id: 'q_invest_002',
        category: QuizCategory.invest,
        difficulty: QuizDifficulty.easy,
        question: '「卵を一つのカゴに盛るな」という投資の格言が示す考え方は？',
        options: ['集中投資', '分散投資', '短期売買', '借金投資'],
        correctAnswerIndex: 1,
        explanation: '複数の資産に分けて投資する「分散投資」の大切さを説く格言。一つが値下がりしてもリスクを抑えられます。',
      ),
      Question(
        id: 'q_invest_003',
        category: QuizCategory.invest,
        difficulty: QuizDifficulty.easy,
        question: '株式投資で受け取れる「配当金」とは何でしょう？',
        options: [
          '会社が利益の一部を株主に分配するお金',
          '株を売ったときの手数料',
          '銀行の利息',
          '国からの補助金'
        ],
        correctAnswerIndex: 0,
        explanation: '配当金は、企業が得た利益の一部を株主に還元するもの。保有株数に応じて支払われます。',
      ),
      Question(
        id: 'q_invest_004',
        category: QuizCategory.invest,
        difficulty: QuizDifficulty.medium,
        question: '「ドルコスト平均法」の説明として正しいものは？',
        options: [
          '一括で大きく買う手法',
          '毎回一定額を定期的に買い続ける手法',
          '株価が下がったら売る手法',
          'ドルだけに投資する手法'
        ],
        correctAnswerIndex: 1,
        explanation: '定額購入を続けることで、高いときは少なく安いときは多く買え、平均購入単価を平準化できます。',
      ),
      Question(
        id: 'q_invest_005',
        category: QuizCategory.invest,
        difficulty: QuizDifficulty.medium,
        question: 'インデックスファンドの特徴として正しいものは？',
        options: [
          '市場平均を上回ることを目指す',
          '特定の指数に連動し、手数料が低め',
          'プロが個別銘柄を厳選する',
          '元本が保証される'
        ],
        correctAnswerIndex: 1,
        explanation: 'インデックスファンドは指数に連動する運用で、アクティブファンドより信託報酬（手数料）が低い傾向です。',
      ),
      Question(
        id: 'q_invest_006',
        category: QuizCategory.invest,
        difficulty: QuizDifficulty.easy,
        question: '投資における「リスク」の正しい意味は？',
        options: ['損する危険だけを指す', 'リターンの振れ幅（不確実性）', '手数料の高さ', '必ず損すること'],
        correctAnswerIndex: 1,
        explanation: '金融でいうリスクは「危険」ではなく、価格が上下に振れる度合い（不確実性）を意味します。',
      ),
      Question(
        id: 'q_invest_007',
        category: QuizCategory.invest,
        difficulty: QuizDifficulty.medium,
        question: '一般に「ローリスク・ローリターン」に最も近い金融商品は？',
        options: ['新興国株式', '個別株の信用取引', '国債（国が発行する債券）', '暗号資産'],
        correctAnswerIndex: 2,
        explanation: '国債は国が元本と利子を保証するため低リスク。その分リターンも小さめです。',
      ),
      Question(
        id: 'q_invest_008',
        category: QuizCategory.invest,
        difficulty: QuizDifficulty.hard,
        question: '長期投資で「複利効果」が最大化されるための最も重要な要素は？',
        options: ['短期で売買を繰り返す', '運用期間を長くする', '一度に全額投資する', '毎年利益を引き出す'],
        correctAnswerIndex: 1,
        explanation: '複利は利益が利益を生む仕組み。運用期間が長いほど雪だるま式に増え、時間が最大の味方になります。',
      ),
      Question(
        id: 'q_invest_009',
        category: QuizCategory.invest,
        difficulty: QuizDifficulty.easy,
        question: '「株価」が上がったり下がったりする主な理由は？',
        options: [
          '国が価格を決めているから',
          '買いたい人と売りたい人のバランスで決まるから',
          '銀行が毎日設定するから',
          '天気によって決まるから'
        ],
        correctAnswerIndex: 1,
        explanation: '株価は需要と供給で変動。買いたい人が多ければ上がり、売りたい人が多ければ下がります。',
      ),
      Question(
        id: 'q_invest_010',
        category: QuizCategory.invest,
        difficulty: QuizDifficulty.hard,
        question: '投資信託の「信託報酬」とは何を指す？',
        options: [
          '購入時に一度だけ払う手数料',
          '保有している間ずっとかかる運用管理費用',
          '売却益にかかる税金',
          '配当金の一種'
        ],
        correctAnswerIndex: 1,
        explanation: '信託報酬は保有期間中、毎日残高から差し引かれる運用コスト。長期投資では低い商品を選ぶことが重要です。',
      ),
      Question(
        id: 'q_invest_011',
        category: QuizCategory.invest,
        difficulty: QuizDifficulty.medium,
        question: '次のうち、分散投資の考え方と矛盾するものはどれ？',
        options: ['資産の種類（株・債券など）', '地域（国内・海外）', '購入する時期', '同じ会社の株を1銘柄に集中'],
        correctAnswerIndex: 3,
        explanation: '分散投資は資産・地域・時間などを分けてリスクを抑える考え方。1銘柄集中はその逆で、リスクが高まります。',
      ),
      Question(
        id: 'q_invest_012',
        category: QuizCategory.invest,
        difficulty: QuizDifficulty.easy,
        question: '投資を始める前に、まず準備しておくべきとされるものは？',
        options: ['生活防衛資金', '高級車', '大量の株の知識', 'FX口座'],
        correctAnswerIndex: 0,
        explanation: '急な出費に備える生活防衛資金を確保してから、余裕資金で投資を始めるのが基本です。',
      ),
      Question(
        id: 'q_invest_013',
        category: QuizCategory.invest,
        difficulty: QuizDifficulty.medium,
        question: '「アクティブファンド」と「インデックスファンド」の主な違いは？',
        options: [
          'アクティブは指数超えを目指し手数料が高め、インデックスは指数連動で低コスト',
          '両者は全く同じ',
          'インデックスは必ず儲かる',
          'アクティブは元本保証がある'
        ],
        correctAnswerIndex: 0,
        explanation: 'アクティブは積極運用で信託報酬が高め、インデックスは指数連動で低コスト。長期では低コストが有利になりやすいです。',
      ),
      Question(
        id: 'q_invest_014',
        category: QuizCategory.invest,
        difficulty: QuizDifficulty.hard,
        question: '「S&P500」とは何を表す指数？',
        options: [
          '米国の代表的な約500社の株価指数',
          '日本の株価指数',
          '金の価格',
          '為替レート'
        ],
        correctAnswerIndex: 0,
        explanation: 'S&P500は米国を代表する約500社で構成される株価指数。世界中の投資家に広く使われています。',
      ),
      Question(
        id: 'q_invest_015',
        category: QuizCategory.invest,
        difficulty: QuizDifficulty.medium,
        question: '株価が大きく下がったとき、長期の積立投資家がとるべき基本姿勢は？',
        options: [
          '慌てず積立を続ける（安く買えるチャンスと捉える）',
          'すぐに全部売る',
          '借金してでも全力で買う',
          '二度と投資しない'
        ],
        correctAnswerIndex: 0,
        explanation: '長期積立では下落時こそ安く買える局面。狼狽売りを避け、淡々と続けることが成功の鍵とされます。',
      ),
      Question(
        id: 'q_invest_016',
        category: QuizCategory.invest,
        difficulty: QuizDifficulty.easy,
        question: '「債券」とはどのような金融商品？',
        options: [
          '国や企業にお金を貸し、利子を受け取る仕組み',
          '会社の所有権',
          '宝くじの一種',
          '銀行の預金'
        ],
        correctAnswerIndex: 0,
        explanation: '債券は発行体（国・企業）への貸付。満期に元本が返り、期間中は利子を受け取れます。株より低リスク傾向です。',
      ),
      Question(
        id: 'q_invest_017',
        category: QuizCategory.invest,
        difficulty: QuizDifficulty.hard,
        question: '「レバレッジ」をかけた投資の特徴として正しいものは？',
        options: [
          '利益も損失も大きくなり、リスクが高まる',
          '必ず利益が出る',
          'リスクがなくなる',
          '手数料が無料になる'
        ],
        correctAnswerIndex: 0,
        explanation: 'レバレッジは自己資金以上の取引を可能にしますが、損失も拡大。初心者には特に注意が必要です。',
      ),
      Question(
        id: 'q_invest_018',
        category: QuizCategory.invest,
        difficulty: QuizDifficulty.medium,
        question: '「ポートフォリオ」という言葉の投資における意味は？',
        options: [
          '保有する資産の組み合わせ・配分',
          '証券会社の名前',
          '株の売買手数料',
          '投資の資格'
        ],
        correctAnswerIndex: 0,
        explanation: 'ポートフォリオは資産の組み合わせ。株・債券・現金などのバランスがリスクとリターンを左右します。',
      ),
      Question(
        id: 'q_invest_019',
        category: QuizCategory.invest,
        difficulty: QuizDifficulty.easy,
        question: '「長期・積立・分散」が初心者に推奨される理由として最も適切なのは？',
        options: [
          'リスクを抑えながら安定的な資産形成を目指せるから',
          '短期間で必ず儲かるから',
          '税金がかからないから',
          'プロだけができる手法だから'
        ],
        correctAnswerIndex: 0,
        explanation: '長期・積立・分散は、値動きのタイミングを読まずにリスクを抑える王道。新NISAもこの考え方が土台です。',
      ),
      Question(
        id: 'q_invest_020',
        category: QuizCategory.invest,
        difficulty: QuizDifficulty.hard,
        question: '「元本保証」をうたう高利回り投資話への正しい対応は？',
        options: [
          '高利回りと元本保証の両立は基本ありえず、詐欺を疑う',
          'すぐに大金を預ける',
          '友人にも勧める',
          '借金して投資する'
        ],
        correctAnswerIndex: 0,
        explanation: '「元本保証で高利回り」はほぼ詐欺のサイン。リターンとリスクは表裏一体であることを忘れないことが大切です。',
      ),
    ];
