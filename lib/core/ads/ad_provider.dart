import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ad_service.dart';
import '../subscription/subscription_provider.dart';

final adServiceProvider = Provider<AdService>((ref) {
  return AdService();
});

/// 広告表示の可否を判定する。
/// 無料ユーザー（!isPremium）のみ true を返す。
final shouldShowAdsProvider = Provider<bool>((ref) {
  final isPremium = ref.watch(isPremiumProvider);
  return !isPremium;
});

/// 広告サービスの初期化を管理する FutureProvider。
final adServiceInitProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(adServiceProvider);
  await service.initialize();
});

/// インタースティシャル広告のセットアップと管理。
/// 画面遷移時などに表示するための広告を常に準備する。
final interstitialAdProvider = Provider<void>((ref) {
  final service = ref.watch(adServiceProvider);
  final shouldShowAds = ref.watch(shouldShowAdsProvider);

  if (shouldShowAds && service.isInitialized) {
    // fire-and-forget で背景で広告を読み込む
    // (既に読み込み中の場合はスキップ)
    if (!service.isInterstitialAdReady) {
      service.loadInterstitialAd();
    }
  }
});

/// バナー広告のセットアップと管理。
/// 画面下部に常時表示する小さな広告。
final bannerAdProvider = FutureProvider.autoDispose<bool>((ref) async {
  final service = ref.watch(adServiceProvider);
  final shouldShowAds = ref.watch(shouldShowAdsProvider);

  if (shouldShowAds && service.isInitialized) {
    final ad = await service.loadBannerAd();
    return ad != null;
  }
  return false;
});
