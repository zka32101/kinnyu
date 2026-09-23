/// 教育段階
enum EducationStage { kindergarten, elementary, juniorHigh, highSchool, university }

extension EducationStageInfo on EducationStage {
  String get displayName {
    switch (this) {
      case EducationStage.kindergarten:
        return '幼稚園';
      case EducationStage.elementary:
        return '小学校';
      case EducationStage.juniorHigh:
        return '中学校';
      case EducationStage.highSchool:
        return '高校';
      case EducationStage.university:
        return '大学';
    }
  }

  /// 標準的な就学年数
  int get durationYears {
    switch (this) {
      case EducationStage.kindergarten:
        return 3;
      case EducationStage.elementary:
        return 6;
      case EducationStage.juniorHigh:
        return 3;
      case EducationStage.highSchool:
        return 3;
      case EducationStage.university:
        return 4;
    }
  }

  /// 標準的な就学開始年齢
  int get startAge {
    switch (this) {
      case EducationStage.kindergarten:
        return 3;
      case EducationStage.elementary:
        return 6;
      case EducationStage.juniorHigh:
        return 12;
      case EducationStage.highSchool:
        return 15;
      case EducationStage.university:
        return 18;
    }
  }
}

/// 進路（公立/私立）
enum SchoolTrack { public, private }

extension SchoolTrackInfo on SchoolTrack {
  String get displayName => this == SchoolTrack.public ? '公立' : '私立';
}

/// 段階別・進路別の教育費の目安（教育目的の概算値）。
/// 文部科学省「子供の学習費調査」等で公表されている平均額を参考にした近似値であり、
/// 通学形態（自宅/下宿）や学部により実際の金額は変動する。
class EducationCostReference {
  static const Map<EducationStage, Map<SchoolTrack, int>> totalCostByStage = {
    EducationStage.kindergarten: {
      SchoolTrack.public: 700000,
      SchoolTrack.private: 1580000,
    },
    EducationStage.elementary: {
      SchoolTrack.public: 1920000,
      SchoolTrack.private: 9600000,
    },
    EducationStage.juniorHigh: {
      SchoolTrack.public: 1460000,
      SchoolTrack.private: 4050000,
    },
    EducationStage.highSchool: {
      SchoolTrack.public: 1370000,
      SchoolTrack.private: 2900000,
    },
    EducationStage.university: {
      SchoolTrack.public: 2550000,
      SchoolTrack.private: 4750000,
    },
  };
}

class EducationCostInput {
  final int childCurrentAge;
  final Map<EducationStage, SchoolTrack> tracks;
  final int currentSavings; // 教育費として既に準備している金額

  const EducationCostInput({
    required this.childCurrentAge,
    required this.tracks,
    this.currentSavings = 0,
  });
}

class EducationStageCost {
  final EducationStage stage;
  final SchoolTrack track;
  final int totalCost;
  final int yearsUntilStart; // 現在からその段階が始まるまでの年数

  const EducationStageCost({
    required this.stage,
    required this.track,
    required this.totalCost,
    required this.yearsUntilStart,
  });
}

class EducationCostResult {
  final List<EducationStageCost> stageCosts;
  final int totalCost; // 幼稚園〜大学の生涯教育費total（参考表示用）
  final int remainingCost; // 大学費用 - currentSavings（下限0）。幼稚園〜高校は都度の家計から
  // 支出される想定のため、事前にまとまった積立が必要な大学費用のみを対象とする。
  final int yearsUntilUniversity;
  final int requiredMonthlySavings; // 大学入学までに準備すべき月々の積立額の目安

  const EducationCostResult({
    required this.stageCosts,
    required this.totalCost,
    required this.remainingCost,
    required this.yearsUntilUniversity,
    required this.requiredMonthlySavings,
  });
}

/// 進学プランに応じた教育費の総額と、必要な積立額を試算する（教育目的の概算）。
class EducationCostPlanner {
  static EducationCostResult calculate(EducationCostInput input) {
    final stageCosts = <EducationStageCost>[];
    var totalCost = 0;

    for (final stage in EducationStage.values) {
      final track = input.tracks[stage] ?? SchoolTrack.public;
      final cost = EducationCostReference.totalCostByStage[stage]![track]!;
      totalCost += cost;

      stageCosts.add(EducationStageCost(
        stage: stage,
        track: track,
        totalCost: cost,
        yearsUntilStart: (stage.startAge - input.childCurrentAge).clamp(0, 100),
      ));
    }

    final universityTrack = input.tracks[EducationStage.university] ?? SchoolTrack.public;
    final universityCost =
        EducationCostReference.totalCostByStage[EducationStage.university]![universityTrack]!;
    final remainingCost =
        (universityCost - input.currentSavings).clamp(0, universityCost);
    final yearsUntilUniversity =
        (EducationStage.university.startAge - input.childCurrentAge).clamp(0, 100);
    final monthsUntilUniversity = yearsUntilUniversity * 12;
    final requiredMonthlySavings = monthsUntilUniversity > 0
        ? (remainingCost / monthsUntilUniversity).ceil()
        : remainingCost;

    return EducationCostResult(
      stageCosts: stageCosts,
      totalCost: totalCost,
      remainingCost: remainingCost,
      yearsUntilUniversity: yearsUntilUniversity,
      requiredMonthlySavings: requiredMonthlySavings,
    );
  }
}
