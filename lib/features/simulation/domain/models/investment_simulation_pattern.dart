import '../../../investment/domain/models/investment.dart';

/// 投資シミュレーションのプリセットパターン。
/// ライフステージやリスク志向に応じたテンプレートを選ぶだけで
/// すぐにシミュレーションを試せるようにする。
class InvestmentSimulationPattern {
  final String id;
  final String title;
  final String description;
  final int monthlyAmount;
  final InvestmentType investmentType;
  final int years;

  const InvestmentSimulationPattern({
    required this.id,
    required this.title,
    required this.description,
    required this.monthlyAmount,
    required this.investmentType,
    required this.years,
  });
}

class InvestmentSimulationPatterns {
  static const List<InvestmentSimulationPattern> patterns = [
    InvestmentSimulationPattern(
      id: 'p_first_step',
      title: 'はじめての積立',
      description: '少額から気軽にスタート。まずは投資に慣れてみよう',
      monthlyAmount: 1000,
      investmentType: InvestmentType.allCountry,
      years: 10,
    ),
    InvestmentSimulationPattern(
      id: 'p_student',
      title: '学生のこづかい投資',
      description: 'お小遣いの一部を将来のために積み立てる',
      monthlyAmount: 3000,
      investmentType: InvestmentType.allCountry,
      years: 10,
    ),
    InvestmentSimulationPattern(
      id: 'p_new_grad',
      title: '新社会人スタート',
      description: '初任給から無理のない範囲でコツコツ積立',
      monthlyAmount: 10000,
      investmentType: InvestmentType.sp500,
      years: 20,
    ),
    InvestmentSimulationPattern(
      id: 'p_nisa_max',
      title: '新NISAつみたて満額',
      description: '新NISAつみたて投資枠（年120万円）を満額で活用するプラン',
      monthlyAmount: 100000,
      investmentType: InvestmentType.allCountry,
      years: 20,
    ),
    InvestmentSimulationPattern(
      id: 'p_stable',
      title: '安定志向プラン',
      description: '値動きを抑えたい人向け。債券中心の堅実な運用',
      monthlyAmount: 20000,
      investmentType: InvestmentType.bond,
      years: 20,
    ),
    InvestmentSimulationPattern(
      id: 'p_aggressive',
      title: '積極運用プラン',
      description: '値動きが大きくても高いリターンを狙いたい人向け',
      monthlyAmount: 30000,
      investmentType: InvestmentType.nasdaq,
      years: 15,
    ),
    InvestmentSimulationPattern(
      id: 'p_retirement',
      title: '老後資金準備',
      description: '「老後2000万円問題」を意識した長期積立プラン',
      monthlyAmount: 33000,
      investmentType: InvestmentType.allCountry,
      years: 30,
    ),
    InvestmentSimulationPattern(
      id: 'p_education',
      title: '子どもの教育資金',
      description: '進学費用を見据えて、子どもの誕生から計画的に積立',
      monthlyAmount: 15000,
      investmentType: InvestmentType.sp500,
      years: 18,
    ),
  ];
}
