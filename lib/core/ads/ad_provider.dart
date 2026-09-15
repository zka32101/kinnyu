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
final bannerAdProvider = StateNotifierProvider<BannerAdNotifier, bool>((ref) {
  final service = ref.watch(adServiceProvider);
  final shouldShowAds = ref.watch(shouldShowAdsProvider);
  return BannerAdNotifier(service, shouldShowAds);
});

class BannerAdNotifier extends StateNotifier<bool> {
  final AdService _adService;
  final bool _shouldShowAds;

  BannerAdNotifier(this._adService, this._shouldShowAds) : super(false) {
    if (_shouldShowAds && _adService.isInitialized) {
      _loadBanner();
    }
  }

  Future<void> _loadBanner() async {
    final ad = await _adService.loadBannerAd();
    state = ad != null;
  }

  void dispose() {
    _adService.disposeBannerAd();
  }
}
