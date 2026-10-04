import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/core/ads/ad_config.dart';

void main() {
  group('AdConfig.shouldShowAds', () {
    test('無料ユーザーで広告リクエストが許可されていれば表示する', () {
      expect(AdConfig.shouldShowAds(isPremium: false, canRequestAds: true), isTrue);
    });

    test('プレミアム購読中は常に非表示', () {
      expect(AdConfig.shouldShowAds(isPremium: true, canRequestAds: true), isFalse);
      expect(AdConfig.shouldShowAds(isPremium: true, canRequestAds: false), isFalse);
    });

    test('同意が得られず広告リクエスト不可なら非表示', () {
      expect(AdConfig.shouldShowAds(isPremium: false, canRequestAds: false), isFalse);
    });
  });

  test('広告ユニットID未指定時はGoogle公式テストIDを使う', () {
    expect(AdConfig.isUsingTestIds, isTrue);
    expect(AdConfig.androidBannerId, AdConfig.testAndroidBannerId);
  });
}
