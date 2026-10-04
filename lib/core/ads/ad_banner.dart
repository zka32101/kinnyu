import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../subscription/subscription_provider.dart';
import 'ad_config.dart';
import 'ad_service.dart';

/// 画面下部のバナー広告。プレミアム購読中・同意未取得・非対応端末では何も表示しない。
class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key});

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    AdService().canRequestAds.addListener(_maybeLoad);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoad());
  }

  void _maybeLoad() {
    if (!mounted || _ad != null) return;
    final service = AdService();
    final show = AdConfig.shouldShowAds(
      isPremium: ref.read(isPremiumProvider),
      canRequestAds: service.canRequestAds.value,
    );
    if (!show || !service.isSupportedPlatform) return;
    final ad = BannerAd(
      adUnitId: AdConfig.androidBannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    AdService().canRequestAds.removeListener(_maybeLoad);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 購読が始まったら即座に広告を片付ける。
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium) {
      _ad?.dispose();
      _ad = null;
      _loaded = false;
      return const SizedBox.shrink();
    }
    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
