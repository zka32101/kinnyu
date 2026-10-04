import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 広告SDKの初期化と、EEA/UK 等での同意取得（UMP）を担当する。
///
/// 初期化に失敗しても、アプリ本体は動作を続ける（広告が出ないだけ）。
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  /// 広告をリクエストしてよいか（同意の取得状況を反映）。
  final ValueNotifier<bool> canRequestAds = ValueNotifier<bool>(false);

  bool _initialized = false;

  /// 現在対応しているのは Android のみ（iOS は広告ユニット未発行のため無効）。
  bool get isSupportedPlatform => !kIsWeb && Platform.isAndroid;

  Future<void> initialize() async {
    if (_initialized || !isSupportedPlatform) return;
    _initialized = true;
    try {
      await _gatherConsent();
      canRequestAds.value = await ConsentInformation.instance.canRequestAds();
      if (canRequestAds.value) {
        await MobileAds.instance.initialize();
      }
    } catch (e, stack) {
      debugPrint('[AdService] initialize failed: $e\n$stack');
    }
  }

  Future<void> _gatherConsent() {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((formError) {
          if (formError != null) {
            debugPrint('[AdService] consent form: ${formError.message}');
          }
          if (!completer.isCompleted) completer.complete();
        });
      },
      (formError) {
        debugPrint('[AdService] consent info: ${formError.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {},
    );
  }
}
