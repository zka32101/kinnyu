import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/social_contribution.dart';

/// 社会貢献機能のサービス
/// カーボンフットプリント・寄付記録・ESGスコア管理
class SocialContributionService {
  final FirebaseFirestore _firestore;

  SocialContributionService(this._firestore);

  /// コレクション参照
  CollectionReference<Map<String, dynamic>> _carbonFootprintCollection(
      String groupId) =>
      _firestore
          .collection('household_groups')
          .doc(groupId)
          .collection('carbon_footprints');

  CollectionReference<Map<String, dynamic>> _donationRecordsCollection(
      String groupId) =>
      _firestore
          .collection('household_groups')
          .doc(groupId)
          .collection('donation_records');

  /// カーボンフットプリント記録を追加
  Future<void> recordCarbonFootprint(
    String groupId,
    String userId,
    String category,
    int expenseAmount,
    String description,
    bool isSaved,
  ) async {
    final factor = CarbonEmissionFactor.defaultFactors[category] ??
        CarbonEmissionFactor.defaultFactors['その他']!;

    final record = CarbonFootprintRecord(
      id: _firestore.collection('dummy').doc().id,
      userId: userId,
      groupId: groupId,
      date: DateTime.now(),
      category: category,
      expenseAmount: expenseAmount,
      carbonEmission: factor.calculateEmission(expenseAmount),
      description: description,
      isSaved: isSaved,
    );

    await _carbonFootprintCollection(groupId).doc(record.id).set(record.toJson());
  }

  /// 指定期間のカーボンフットプリント記録を取得
  Future<List<CarbonFootprintRecord>> getCarbonFootprints(
    String groupId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query<Map<String, dynamic>> query = _carbonFootprintCollection(groupId);

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: endDate);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => CarbonFootprintRecord.fromJson(doc.data()))
        .toList();
  }

  /// グループのカーボンフットプリント削減量を計算
  Future<double> getTotalCarbonSaved(String groupId) async {
    final records = await getCarbonFootprints(groupId);
    return records.where((r) => r.isSaved).fold<double>(
        0, (sum, record) => sum + record.carbonEmission);
  }

  /// カテゴリ別のカーボンフットプリント削減量
  Future<Map<String, double>> getCarbonBySavingCategory(String groupId) async {
    final records = await getCarbonFootprints(groupId);
    final result = <String, double>{};

    for (final record in records.where((r) => r.isSaved)) {
      result.update(
        record.category,
        (value) => value + record.carbonEmission,
        ifAbsent: () => record.carbonEmission,
      );
    }

    return result;
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
    final record = UserDonationRecord(
      id: _firestore.collection('dummy').doc().id,
      userId: userId,
      groupId: groupId,
      charityId: charityId,
      charityName: charityName,
      donationAmount: donationAmount,
      date: DateTime.now(),
      source: source,
    );

    await _donationRecordsCollection(groupId).doc(record.id).set(record.toJson());
  }

  /// グループの寄付総額を計算
  Future<int> getTotalDonations(String groupId) async {
    final snapshot = await _donationRecordsCollection(groupId).get();
    return snapshot.docs.fold<int>(
      0,
      (sum, doc) => sum + (doc.data()['donationAmount'] as int? ?? 0),
    );
  }

  /// 慈善団体別の寄付額
  Future<Map<String, int>> getDonationsByCharity(String groupId) async {
    final snapshot = await _donationRecordsCollection(groupId).get();
    final result = <String, int>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final charityName = data['charityName'] as String;
      final amount = data['donationAmount'] as int? ?? 0;

      result.update(
        charityName,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
    }

    return result;
  }

  /// 社会貢献インパクトダッシュボードを生成
  Future<SocialImpactDashboard> generateImpactDashboard(
      String groupId) async {
    final totalCarbonSaved = await getTotalCarbonSaved(groupId);
    final totalDonations = await getTotalDonations(groupId);
    final carbonByCategory = await getCarbonBySavingCategory(groupId);
    final donationByCharity = await getDonationsByCharity(groupId);

    // 支援世帯数の推計（寄付額 / 3000円 = 1世帯）
    final familiesHelped = (totalDonations / 3000).toInt();

    // トップカテゴリ（CO2削減が多い順）
    final topCategories = carbonByCategory.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(3)
        .map((e) => e.key)
        .toList();

    return SocialImpactDashboard(
      groupId: groupId,
      totalCarbonSaved: totalCarbonSaved,
      totalDonationsAmount: totalDonations,
      familiesHelped: familiesHelped,
      impactByCharity: Map<String, double>.fromEntries(
        donationByCharity.entries.map((e) => MapEntry(e.key, e.value.toDouble())),
      ),
      topCategories: topCategories,
    );
  }

  /// カテゴリのESGスコアを取得
  ESGScore getESGScore(String category) {
    return ESGScore.defaultScores[category] ??
        ESGScore(
          categoryName: category,
          environmentScore: 50,
          socialScore: 50,
          governanceScore: 50,
        );
  }

  /// ユーザーの平均ESGスコアを計算
  Future<ESGScore> getUserAverageESGScore(String groupId) async {
    final records = await getCarbonFootprints(groupId);
    if (records.isEmpty) {
      return ESGScore(
        categoryName: 'Average',
        environmentScore: 0,
        socialScore: 0,
        governanceScore: 0,
      );
    }

    double avgEnvironment = 0;
    double avgSocial = 0;
    double avgGovernance = 0;

    for (final record in records) {
      final score = getESGScore(record.category);
      avgEnvironment += score.environmentScore;
      avgSocial += score.socialScore;
      avgGovernance += score.governanceScore;
    }

    final count = records.length;
    return ESGScore(
      categoryName: 'Average',
      environmentScore: avgEnvironment / count,
      socialScore: avgSocial / count,
      governanceScore: avgGovernance / count,
    );
  }

  /// ストリームでカーボンフットプリント記録を監視
  Stream<List<CarbonFootprintRecord>> watchCarbonFootprints(String groupId) {
    return _carbonFootprintCollection(groupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CarbonFootprintRecord.fromJson(doc.data()))
            .toList());
  }

  /// ストリームで寄付記録を監視
  Stream<List<UserDonationRecord>> watchDonationRecords(String groupId) {
    return _donationRecordsCollection(groupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserDonationRecord.fromJson(doc.data()))
            .toList());
  }
}
