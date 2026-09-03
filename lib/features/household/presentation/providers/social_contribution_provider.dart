import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/social_contribution_service.dart';
import '../../domain/models/social_contribution.dart';

/// SocialContributionService プロバイダー
final socialContributionServiceProvider = Provider((ref) {
  return SocialContributionService(FirebaseFirestore.instance);
});

/// グループのカーボンフットプリント削減量
final totalCarbonSavedProvider = FutureProvider.family<double, String>(
  (ref, groupId) async {
    final service = ref.watch(socialContributionServiceProvider);
    return await service.getTotalCarbonSaved(groupId);
  },
);

/// グループの寄付総額
final totalDonationsProvider = FutureProvider.family<int, String>(
  (ref, groupId) async {
    final service = ref.watch(socialContributionServiceProvider);
    return await service.getTotalDonations(groupId);
  },
);

/// 社会貢献インパクトダッシュボード
final socialImpactDashboardProvider =
    FutureProvider.family<SocialImpactDashboard, String>(
  (ref, groupId) async {
    final service = ref.watch(socialContributionServiceProvider);
    return await service.generateImpactDashboard(groupId);
  },
);

/// グループのカーボンフットプリント記録をストリームで監視
final watchCarbonFootprintsProvider =
    StreamProvider.family<List<CarbonFootprintRecord>, String>(
  (ref, groupId) {
    final service = ref.watch(socialContributionServiceProvider);
    return service.watchCarbonFootprints(groupId);
  },
);

/// グループの寄付記録をストリームで監視
final watchDonationRecordsProvider =
    StreamProvider.family<List<UserDonationRecord>, String>(
  (ref, groupId) {
    final service = ref.watch(socialContributionServiceProvider);
    return service.watchDonationRecords(groupId);
  },
);

/// ユーザーの平均ESGスコア
final averageESGScoreProvider = FutureProvider.family<ESGScore, String>(
  (ref, groupId) async {
    final service = ref.watch(socialContributionServiceProvider);
    return await service.getUserAverageESGScore(groupId);
  },
);

/// カテゴリ別のカーボンフットプリント削減量
final carbonByCategoryProvider = FutureProvider.family<Map<String, double>, String>(
  (ref, groupId) async {
    final service = ref.watch(socialContributionServiceProvider);
    return await service.getCarbonBySavingCategory(groupId);
  },
);

/// 慈善団体別の寄付額
final donationByCharityProvider = FutureProvider.family<Map<String, int>, String>(
  (ref, groupId) async {
    final service = ref.watch(socialContributionServiceProvider);
    return await service.getDonationsByCharity(groupId);
  },
);

/// 社会貢献操作のミューテーター
class SocialContributionMutator {
  final SocialContributionService _service;

  SocialContributionMutator(this._service);

  /// カーボンフットプリント記録を追加
  Future<void> recordCarbonFootprint(
    String groupId,
    String userId,
    String category,
    int expenseAmount,
    String description,
    bool isSaved,
  ) async {
    await _service.recordCarbonFootprint(
      groupId,
      userId,
      category,
      expenseAmount,
      description,
      isSaved,
    );
  }

  /// 寄付記録を追加
  Future<void> recordDonation(
    String groupId,
    String userId,
    String charityId,
    String charityName,
    int donationAmount,
    String source,
  ) async {
    await _service.recordDonation(
      groupId,
      userId,
      charityId,
      charityName,
      donationAmount,
      source,
    );
  }
}

/// 社会貢献ミューテーター プロバイダー
final socialContributionMutatorProvider = Provider((ref) {
  return SocialContributionMutator(
    ref.watch(socialContributionServiceProvider),
  );
});

/// デフォルトのチャリティ一覧プロバイダー
final defaultCharitiesProvider = Provider((ref) {
  return CharityDonation.defaultCharities;
});

/// デフォルトのESGスコア一覧プロバイダー
final defaultESGScoresProvider = Provider((ref) {
  return ESGScore.defaultScores;
});

/// カーボン削減リーダーボード（グループメンバー別）
final carbonLeaderboardProvider = FutureProvider.family<List<(String, double)>, String>(
  (ref, groupId) async {
    final carbonRecords = await ref.watch(
      watchCarbonFootprintsProvider(groupId).future,
    );

    final carbonByUser = <String, double>{};
    for (final record in carbonRecords.where((r) => r.isSaved)) {
      carbonByUser.update(
        record.userId,
        (value) => value + record.carbonEmission,
        ifAbsent: () => record.carbonEmission,
      );
    }

    // ソートして返す
    final leaderboard = carbonByUser.entries
        .map((e) => (e.key, e.value))
        .toList()
        ..sort((a, b) => b.$2.compareTo(a.$2));

    return leaderboard;
  },
);

/// 社会インパクトレベルプロバイダー
final socialImpactLevelProvider = FutureProvider.family<int, String>(
  (ref, groupId) async {
    final dashboard = await ref.watch(
      socialImpactDashboardProvider(groupId).future,
    );
    return dashboard.impactLevel;
  },
);

/// 社会インパクトレベルの説明プロバイダー
final socialImpactLevelDescriptionProvider = FutureProvider.family<String, String>(
  (ref, groupId) async {
    final dashboard = await ref.watch(
      socialImpactDashboardProvider(groupId).future,
    );
    return dashboard.impactLevelDescription;
  },
);
