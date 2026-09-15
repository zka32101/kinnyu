import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google Mobile Ads の初期化と広告管理を行うサービス。
/// 無料ユーザーに対して全画面広告（インタースティシャル）とバナー広告を配信する。
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _initialized = false;
  InterstitialAd? _interstitialAd;
  BannerAd? _bannerAd;

  bool get isInitialized => _initialized;

  // TODO: AdMob ダッシュボードから取得した実際の広告ユニットIDに置き換えること
  /// バナー広告ユニットID（Android: ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy）
  static const String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // テスト用

  /// インタースティシャル広告ユニットID（Android: ca-app-pub-xxxxxxxxxxxxxxxx/zzzzzzzzzz）
  static const String _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712'; // テスト用

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('AdService: 初期化完了');
    } catch (e) {
      debugPrint('AdService: 初期化失敗 $e');
    }
  }

  /// バナー広告を読み込む。
  /// 無料ユーザーの画面下部に常時表示するために使用。
  Future<BannerAd?> loadBannerAd() async {
    if (!_initialized) return null;
    try {
      final bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            debugPrint('AdService: バナー広告読み込み成功');
            _bannerAd = ad as BannerAd;
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            debugPrint('AdService: バナー広告読み込み失敗 $error');
            ad.dispose();
          },
        ),
      );
      await bannerAd.load();
      return bannerAd;
    } catch (e) {
      debugPrint('AdService: バナー広告読み込み例外 $e');
      return null;
    }
  }

  /// インタースティシャル広告を読み込む。
  /// 主要なナビゲーション時（ダッシュボード → 詳細画面など）に表示。
  Future<void> loadInterstitialAd() async {
    if (!_initialized) return;
    try {
      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            debugPrint('AdService: インタースティシャル広告読み込み成功');
            _interstitialAd = ad;
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('AdService: インタースティシャル広告読み込み失敗 $error');
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('AdService: インタースティシャル広告読み込み例外 $e');
    }
  }

  /// インタースティシャル広告を表示する。
  /// 既に読み込まれているのであればすぐに表示し、読み込み完了後に新しい広告を預読み込みする。
  Future<void> showInterstitialAd() async {
    if (_interstitialAd == null) {
      debugPrint('AdService: インタースティシャル広告が利用不可（まだ読み込み中）');
      return;
    }

    try {
      await _interstitialAd!.show();
      _interstitialAd = null;
      // 表示完了したので新しい広告を預読み込みする
      unawaited(loadInterstitialAd());
    } catch (e) {
      debugPrint('AdService: インタースティシャル広告表示失敗 $e');
    }
  }

  /// バナー広告を破棄する。
  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  /// インタースティシャル広告を破棄する。
  void disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  /// すべての広告を破棄する。
  void disposeAll() {
    disposeBannerAd();
    disposeInterstitialAd();
  }

  /// バナー広告が利用可能かを確認する。
  bool get isBannerAdReady => _bannerAd != null;

  /// インタースティシャル広告が利用可能かを確認する。
  bool get isInterstitialAdReady => _interstitialAd != null;
}
