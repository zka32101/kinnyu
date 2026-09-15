import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_service.dart';

/// 無料ユーザー向けバナー広告ウィジェット。
/// AdService から BannerAd を取得して画面下部に表示する。
/// プレミアムユーザーの場合は何も表示しない（親側で shouldShowAdsProvider を確認すること）。
class AdBannerWidget extends StatefulWidget {
  final AdService adService;

  const AdBannerWidget({
    Key? key,
    required this.adService,
  }) : super(key: key);

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final ad = await widget.adService.loadBannerAd();
    if (mounted && ad != null) {
      setState(() {
        _bannerAd = ad;
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.grey[200],
      child: SizedBox(
        height: _bannerAd!.size.height.toDouble(),
        width: _bannerAd!.size.width.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
