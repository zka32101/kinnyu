/// 家計診断専用の質問（クイズと異なり「正解」はなく、傾向を測る）
class DiagnosisQuestion {
  final String id;
  final String question;
  final List<String> options;

  const DiagnosisQuestion({
    required this.id,
    required this.question,
    required this.options,
  });
}

/// 節約タイプ診断の質問セット（3問・各3択）
class DiagnosisQuestions {
  static const List<DiagnosisQuestion> questions = [
    DiagnosisQuestion(
      id: 'dq_spending_habit',
      question: '普段のお金の使い方に一番近いのは？',
      options: [
        'コンビニやカフェなど、こまめな出費が多い',
        '外食やレジャーなど、まとまった出費が多い',
        '固定費（サブスク・保険など）が気づけば増えている',
      ],
    ),
    DiagnosisQuestion(
      id: 'dq_money_management',
      question: 'お金の管理について、当てはまるのは？',
      options: [
        '収支をあまり把握できていない',
        'ざっくりは把握しているが改善はこれから',
        'ある程度管理できており、次の一手を探している',
      ],
    ),
    DiagnosisQuestion(
      id: 'dq_goal',
      question: 'いま一番興味があるお金のテーマは？',
      options: [
        '日々の支出を減らして貯蓄を増やしたい',
        '税金の仕組み（ふるさと納税・控除）を知りたい',
        '投資や資産運用を始めたい',
      ],
    ),
  ];
}
