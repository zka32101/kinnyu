import '../../features/quiz/domain/models/question.dart';

/// 保険カテゴリの問題データ（生命保険・医療保険・社会保険・見直し）
List<Question> insuranceQuestions() => [
      Question(
        id: 'q_insurance_001',
        category: QuizCategory.insurance,
        difficulty: QuizDifficulty.easy,
        question: '生命保険の見直しで重要なポイントは？',
        options: ['安さだけ', '保障内容と保険料のバランス', '販売員の推奨', '保険会社の知名度'],
        correctAnswerIndex: 1,
        explanation: '生命保険は自分のライフステージに合わせ、保障内容と保険料のバランスを考えて選ぶことが大切です。',
      ),
      Question(
        id: 'q_insurance_002',
        category: QuizCategory.insurance,
        difficulty: QuizDifficulty.easy,
        question: '保険の基本的な役割として最も適切なものは？',
        options: [
          '確実に儲けるため',
          '低い確率だが起きたら大きな損失に備えるため',
          '税金を無くすため',
          '毎月お金を増やすため'
        ],
        correctAnswerIndex: 1,
        explanation: '保険は「めったに起きないが起きると家計が破綻する損失」に備えるもの。貯蓄と役割が異なります。',
      ),
      Question(
        id: 'q_insurance_003',
        category: QuizCategory.insurance,
        difficulty: QuizDifficulty.medium,
        question: '「掛け捨て型」の保険の特徴として正しいものは？',
        options: [
          '解約時にお金が戻る',
          '保険料が割安で貯蓄性がない',
          '必ず満期金がもらえる',
          '保険料が最も高い'
        ],
        correctAnswerIndex: 1,
        explanation: '掛け捨て型は貯蓄性がない分、保険料が割安。同じ保障を安く得られるのがメリットです。',
      ),
      Question(
        id: 'q_insurance_004',
        category: QuizCategory.insurance,
        difficulty: QuizDifficulty.medium,
        question: '会社員が加入している「健康保険」で、医療費の自己負担割合は原則何割？',
        options: ['1割', '2割', '3割', '全額'],
        correctAnswerIndex: 2,
        explanation: '現役世代の医療費自己負担は原則3割。残り7割は公的健康保険がカバーします。',
      ),
      Question(
        id: 'q_insurance_005',
        category: QuizCategory.insurance,
        difficulty: QuizDifficulty.hard,
        question: '医療費が高額になったとき、自己負担を一定額に抑える公的制度は？',
        options: ['高額療養費制度', '確定申告', 'ふるさと納税', '年末調整'],
        correctAnswerIndex: 0,
        explanation: '高額療養費制度により、月の医療費自己負担が上限額を超えた分は払い戻されます。民間医療保険の要否判断の鍵です。',
      ),
      Question(
        id: 'q_insurance_006',
        category: QuizCategory.insurance,
        difficulty: QuizDifficulty.easy,
        question: '独身で扶養家族がいない人が、高額な死亡保障保険に入る必要性は一般に？',
        options: ['非常に高い', '比較的低い', '必ず必要', '法律で義務'],
        correctAnswerIndex: 1,
        explanation: '死亡保障は「残された家族の生活費」のためのもの。扶養家族がいない場合、必要性は低めです。',
      ),
      Question(
        id: 'q_insurance_007',
        category: QuizCategory.insurance,
        difficulty: QuizDifficulty.medium,
        question: '自動車保険の「対人賠償保険」は無制限に設定するのが推奨される理由は？',
        options: [
          '保険料が安いから',
          '事故で他人を死傷させた賠償額が高額になり得るから',
          '法律で無制限が義務だから',
          '自分のケガを補償するから'
        ],
        correctAnswerIndex: 1,
        explanation: '対人事故の賠償は数億円になる例もあります。対人・対物は無制限が基本とされています。',
      ),
      Question(
        id: 'q_insurance_008',
        category: QuizCategory.insurance,
        difficulty: QuizDifficulty.hard,
        question: '「社会保険」に含まれないものは次のうちどれ？',
        options: ['健康保険', '厚生年金', '雇用保険', '生命保険'],
        correctAnswerIndex: 3,
        explanation: '社会保険は公的制度（健康保険・年金・雇用・労災・介護）。生命保険は民間の任意保険です。',
      ),
      Question(
        id: 'q_insurance_009',
        category: QuizCategory.insurance,
        difficulty: QuizDifficulty.easy,
        question: '保険を選ぶとき、まず考えるべき順序として適切なものは？',
        options: [
          '保険料の安さから決める',
          '必要な保障（何に備えるか）から考える',
          'CMで有名な会社から選ぶ',
          '営業担当のおすすめで決める'
        ],
        correctAnswerIndex: 1,
        explanation: 'まず「何のリスクに備えるか」を明確にし、必要な保障を決めてから商品・保険料を比較するのが正しい順序です。',
      ),
      Question(
        id: 'q_insurance_010',
        category: QuizCategory.insurance,
        difficulty: QuizDifficulty.medium,
        question: '働けなくなったときの収入減に備える保険を何という？',
        options: ['就業不能保険（所得補償保険）', '火災保険', '学資保険', '旅行保険'],
        correctAnswerIndex: 0,
        explanation: '就業不能保険は、病気やケガで長期間働けなくなったときの収入を補う保険です。',
      ),
      Question(
        id: 'q_insurance_011',
        category: QuizCategory.insurance,
        difficulty: QuizDifficulty.easy,
        question: '子どもの教育資金準備を目的とした保険は？',
        options: ['学資保険', 'がん保険', '火災保険', '自動車保険'],
        correctAnswerIndex: 0,
        explanation: '学資保険は、満期時に教育資金を受け取れる貯蓄型の保険。契約者が亡くなると以後の保険料が免除される特徴もあります。',
      ),
      Question(
        id: 'q_insurance_012',
        category: QuizCategory.insurance,
        difficulty: QuizDifficulty.hard,
        question: '保険の「特約」とは何を指す？',
        options: [
          '主契約に付け加える追加の保障',
          '保険料の割引',
          '解約手数料',
          '保険会社の社名'
        ],
        correctAnswerIndex: 0,
        explanation: '特約は主契約にオプションで付ける保障。手厚くできる反面、不要な特約は保険料の無駄になります。',
      ),
      Question(
        id: 'q_insurance_013',
        category: QuizCategory.insurance,
        difficulty: QuizDifficulty.easy,
        question: '「火災保険」で一般的に補償される対象は？',
        options: [
          '火災だけでなく風災・水災など建物・家財の損害',
          '交通事故',
          '病気の治療費',
          '株の損失'
        ],
        correctAnswerIndex: 0,
        explanation: '火災保険は火災に限らず、台風・落雷・水漏れなど幅広い建物・家財の損害を補償します。',
      ),
      Question(
        id: 'q_insurance_014',
        category: QuizCategory.insurance,
        difficulty: QuizDifficulty.medium,
        question: '賃貸住宅で加入を求められることが多い保険は？',
        options: ['家財保険（借家人賠償責任付き）', 'がん保険', '学資保険', '自動車保険'],
        correctAnswerIndex: 0,
        explanation: '賃貸では、家財の損害や大家への賠償に備える家財保険への加入が一般的に求められます。',
      ),
      Question(
        id: 'q_insurance_015',
        category: QuizCategory.insurance,
        difficulty: QuizDifficulty.medium,
        question: '「定期保険」と「終身保険」の違いとして正しいものは？',
        options: [
          '定期は一定期間のみ保障、終身は一生涯保障',
          '両者は同じ',
          '定期は一生涯保障',
          '終身は掛け捨て'
        ],
        correctAnswerIndex: 0,
        explanation: '定期保険は保障が一定期間で保険料が安め、終身保険は一生涯保障で貯蓄性がある分割高です。',
      ),
      Question(
        id: 'q_insurance_016',
        category: QuizCategory.insurance,
        difficulty: QuizDifficulty.hard,
        question: '公的年金の一つ「遺族年金」はどんなときに支給される？',
        options: [
          '一家の生計を支える人が亡くなったとき',
          '定年退職したとき',
          '結婚したとき',
          '転職したとき'
        ],
        correctAnswerIndex: 0,
        explanation: '遺族年金は、生計維持者が亡くなった際に遺族へ支給される公的保障。民間の死亡保障を考える際の前提になります。',
      ),
      Question(
        id: 'q_insurance_017',
        category: QuizCategory.insurance,
        difficulty: QuizDifficulty.easy,
        question: '保険の「見直し」をするのに良いタイミングは？',
        options: [
          '結婚・出産・住宅購入などライフイベントの時',
          '毎日',
          '一度入ったら一生見直さない',
          '保険料が上がった時だけ'
        ],
        correctAnswerIndex: 0,
        explanation: 'ライフイベントで必要な保障は変化します。節目ごとに見直すと過不足のない保険に整えられます。',
      ),
      Question(
        id: 'q_insurance_018',
        category: QuizCategory.insurance,
        difficulty: QuizDifficulty.medium,
        question: '「がん保険」が一般の医療保険と別に用意されることが多い理由は？',
        options: [
          'がんは治療が長期化・高額化しやすく手厚い保障が想定されるため',
          'がんは軽い病気だから',
          '医療保険では一切カバーできないから',
          '法律で義務だから'
        ],
        correctAnswerIndex: 0,
        explanation: 'がんは通院・先進医療など費用が長期化しやすく、専用保障を用意する商品が多いですが、公的制度との重複に注意します。',
      ),
      Question(
        id: 'q_insurance_019',
        category: QuizCategory.insurance,
        difficulty: QuizDifficulty.easy,
        question: '「保険料」と「保険金」の違いとして正しいものは？',
        options: [
          '保険料は支払うお金、保険金は受け取るお金',
          '両方とも受け取るお金',
          '両方とも支払うお金',
          '同じ意味'
        ],
        correctAnswerIndex: 0,
        explanation: '保険料は毎月払う掛金、保険金は事故や入院などの際に受け取るお金。混同しやすいので要注意です。',
      ),
      Question(
        id: 'q_insurance_020',
        category: QuizCategory.insurance,
        difficulty: QuizDifficulty.hard,
        question: '「保険は貯蓄がわり」という考え方について、一般的に注意すべき点は？',
        options: [
          '貯蓄型は保障と運用が一体で手数料が見えにくく、割高になることがある',
          '貯蓄型は必ず得',
          '掛け捨ては損しかない',
          '保険で運用すれば絶対増える'
        ],
        correctAnswerIndex: 0,
        explanation: '貯蓄型保険は保障とコストが一体で割高になりがち。「保障は保険、運用は投資」と分けて考える人も増えています。',
      ),
    ];
