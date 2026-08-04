import '../../../quiz/domain/models/question.dart';
import 'receipt.dart';

/// レシートの支出額から「実支出連動クイズ」を生成する。
/// 支出額に応じて複数の切り口（投資・年間換算・複利）からランダムに1問生成し、
/// 「この出費が長期でどんな意味を持つか」を体感させる。
class ReceiptQuizGenerator {
  /// レシートIDのハッシュでクイズタイプを決定的に選ぶ（同じレシートは同じ問題）
  static Question generate(Receipt receipt) {
    final variant = receipt.id.hashCode.abs() % 3;
    switch (variant) {
      case 0:
        return generateInvestmentQuiz(receipt);
      case 1:
        return generateAnnualQuiz(receipt);
      default:
        return generateCompoundQuiz(receipt);
    }
  }

  /// 10年投資したらいくら？（年利5%複利）
  static Question generateInvestmentQuiz(Receipt receipt) {
    final categoryName = ReceiptCategoryInfo.displayNames[receipt.category]!;
    const annualRate = 0.05;
    final tenYearValue = (receipt.amount * _compound(annualRate, 10)).round();
    final wrongAnswer1 = (receipt.amount * 1.1).round();
    final wrongAnswer2 = (receipt.amount * _compound(annualRate, 5)).round();
    final wrongAnswer3 = receipt.amount * 2;

    final options = [tenYearValue, wrongAnswer1, wrongAnswer2, wrongAnswer3]
        .map((v) => '¥$v')
        .toList()
      ..shuffle();
    final correctIndex = options.indexOf('¥$tenYearValue');

    return Question(
      id: 'receipt_quiz_inv_${receipt.id}',
      category: QuizCategory.invest,
      difficulty: QuizDifficulty.medium,
      question:
          'この$categoryName支出¥${receipt.amount}を年利5%で10年間投資に回すと、いくらになるでしょう？',
      options: options,
      correctAnswerIndex: correctIndex,
      explanation:
          '¥${receipt.amount} × (1.05)^10 ≈ ¥$tenYearValue。複利効果で長期投資は大きく育ちます（教育目的シミュレーションです）。',
    );
  }

  /// 毎週この出費を1年続けたら年間いくら？
  static Question generateAnnualQuiz(Receipt receipt) {
    final categoryName = ReceiptCategoryInfo.displayNames[receipt.category]!;
    final annual = receipt.amount * 52; // 週1回×52週
    final wrong1 = receipt.amount * 12;
    final wrong2 = receipt.amount * 30;
    final wrong3 = receipt.amount * 100;

    final options = [annual, wrong1, wrong2, wrong3].map((v) => '¥$v').toList()
      ..shuffle();
    final correctIndex = options.indexOf('¥$annual');

    return Question(
      id: 'receipt_quiz_annual_${receipt.id}',
      category: QuizCategory.savings,
      difficulty: QuizDifficulty.easy,
      question:
          'この$categoryName支出¥${receipt.amount}を毎週続けると、1年間（52週）でいくらになる？',
      options: options,
      correctAnswerIndex: correctIndex,
      explanation:
          '¥${receipt.amount} × 52週 = ¥$annual。小さな出費も1年で大きな額に。「ちりつも」を意識しましょう。',
    );
  }

  /// この額を毎月積立投資したら20年でいくら？（年利3%・概算）
  static Question generateCompoundQuiz(Receipt receipt) {
    final categoryName = ReceiptCategoryInfo.displayNames[receipt.category]!;
    // 毎月 amount を年利3%で20年積立（月複利の概算）
    final monthly = receipt.amount;
    const months = 240;
    const monthlyRate = 0.03 / 12;
    // 積立終価係数: ((1+r)^n - 1) / r
    var factor = 1.0;
    var pow = 1.0;
    for (var i = 0; i < months; i++) {
      pow *= (1 + monthlyRate);
    }
    factor = (pow - 1) / monthlyRate;
    final future = (monthly * factor).round();
    final principal = monthly * months;

    final wrong1 = principal; // 元本のみ（利息無視）
    final wrong2 = (future * 1.5).round();
    final wrong3 = (principal * 0.8).round();

    final options = [future, wrong1, wrong2, wrong3].map((v) => '¥$v').toList()
      ..shuffle();
    final correctIndex = options.indexOf('¥$future');

    return Question(
      id: 'receipt_quiz_compound_${receipt.id}',
      category: QuizCategory.invest,
      difficulty: QuizDifficulty.hard,
      question:
          'この$categoryName支出¥$monthlyを毎月積立投資（年利3%）に回すと、20年後およそいくら？',
      options: options,
      correctAnswerIndex: correctIndex,
      explanation:
          '元本¥$principalが、複利運用でおよそ¥$futureに。毎月の小さな積立が20年で大きく育ちます（教育目的の概算です）。',
    );
  }

  static double _compound(double rate, int years) {
    double result = 1.0;
    for (var i = 0; i < years; i++) {
      result *= (1 + rate);
    }
    return result;
  }
}
