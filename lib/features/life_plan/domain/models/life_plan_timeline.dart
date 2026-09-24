import '../../../simulation/domain/models/education_cost_planner.dart';
import '../../../simulation/domain/models/pension_estimator.dart';

/// ライフプランタイムライン上の1つのイベント（年齢順に並べて表示する）。
class LifePlanEvent {
  final int age; // ユーザーの年齢（このイベントが発生する年齢の目安）
  final String emoji;
  final String title;
  final String description;
  final int amount; // 円（費用・収入いずれも正の値で保持し、isIncomeで区別）
  final bool isIncome;

  const LifePlanEvent({
    required this.age,
    required this.emoji,
    required this.title,
    required this.description,
    required this.amount,
    required this.isIncome,
  });
}

class LifePlanTimelineInput {
  final int currentAge;
  final int? childCurrentAge; // 子どもがいない場合はnull
  final int retirementAge;
  final int averageAnnualIncome;

  const LifePlanTimelineInput({
    required this.currentAge,
    this.childCurrentAge,
    required this.retirementAge,
    required this.averageAnnualIncome,
  });
}

/// 既存の教育費プランナー・年金シミュレーターの試算結果を年齢順に並べ、
/// 人生全体のお金の出来事を1つのタイムラインとして構築する。
/// 新しい金額計算式は導入せず、既存の計算ロジックをそのまま再利用する。
class LifePlanTimelineBuilder {
  static List<LifePlanEvent> build(LifePlanTimelineInput input) {
    final events = <LifePlanEvent>[];

    if (input.childCurrentAge != null) {
      final educationResult = EducationCostPlanner.calculate(
        EducationCostInput(
          childCurrentAge: input.childCurrentAge!,
          tracks: {
            for (final stage in EducationStage.values) stage: SchoolTrack.public,
          },
        ),
      );
      for (final stageCost in educationResult.stageCosts) {
        events.add(LifePlanEvent(
          age: input.currentAge + stageCost.yearsUntilStart,
          emoji: '🎓',
          title: '子どもが${stageCost.stage.displayName}に入学',
          description:
              '概算費用 ¥${stageCost.totalCost}（${stageCost.track.displayName}・全国平均の目安）',
          amount: stageCost.totalCost,
          isIncome: false,
        ));
      }
    }

    final assumedWorkingYears = (input.retirementAge - 22).clamp(0, 45);
    final pensionResult = PensionEstimator.calculate(
      PensionEstimatorInput(
        currentAge: input.currentAge,
        retirementAge: input.retirementAge,
        averageAnnualIncome: input.averageAnnualIncome,
        pensionEnrollmentYears: assumedWorkingYears,
        companySize: CompanySize.medium,
        yearsOfService: assumedWorkingYears,
      ),
    );

    events.add(LifePlanEvent(
      age: input.retirementAge,
      emoji: '🏢',
      title: '退職',
      description: '退職金の目安 ¥${pensionResult.estimatedRetirementLumpSum}',
      amount: pensionResult.estimatedRetirementLumpSum,
      isIncome: true,
    ));
    events.add(LifePlanEvent(
      age: input.retirementAge,
      emoji: '👴',
      title: '年金の受給開始',
      description: '年金受給額（年額）の目安 ¥${pensionResult.annualTotalPension}',
      amount: pensionResult.annualTotalPension,
      isIncome: true,
    ));

    events.sort((a, b) => a.age.compareTo(b.age));
    return events;
  }
}
