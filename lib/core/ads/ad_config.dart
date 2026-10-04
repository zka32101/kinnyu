/// 広告まわりの設定と表示判定（UI・SDKに依存しない純粋なロジック）。
///
/// 本番の広告ユニットIDは `--dart-define=ADMOB_ANDROID_BANNER_ID=ca-app-pub-.../...` で渡す。
/// 未指定の場合は Google 公式のテスト用IDを使う（収益は発生しない）。
/// アプリIDは android/app/build.gradle.kts の `ADMOB_APP_ID` 環境変数で渡す。
class AdConfig {
  AdConfig._();

  /// Google 公式のテスト用バナー広告ユニットID（Android）。
  static const String testAndroidBannerId =
      'ca-app-pub-3940256099942544/6300978111';

  static const String androidBannerId = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_ID',
    defaultValue: testAndroidBannerId,
  );

  /// テスト用IDのままか。リリース前の確認に使う。
  static bool get isUsingTestIds => androidBannerId == testAndroidBannerId;

  /// 広告を表示すべきか。プレミアム購読中は常に非表示。
  /// 同意取得の結果、広告リクエストが許可されない場合も非表示。
  static bool shouldShowAds({
    required bool isPremium,
    required bool canRequestAds,
  }) =>
      !isPremium && canRequestAds;
}
