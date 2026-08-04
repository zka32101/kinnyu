import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat の Entitlement 識別子。RevenueCat ダッシュボードで
/// 同名の Entitlement を作成し、Google Play Console の商品と紐付けること。
const String premiumEntitlementId = 'premium';

/// お金コレ！のプレミアム課金（RevenueCat）を管理するサービス。
/// API キー未設定時は課金機能を無効化した状態で安全に動作する
/// （開発中・審査待ちでもアプリ本体はクラッシュしない）。
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  bool _initialized = false;
  bool get isConfigured => _initialized;

  /// TODO: RevenueCat ダッシュボード（Project Settings > API keys）で
  /// 取得した Google Play 用 Public API Key に置き換えること。
  static const String _androidApiKey = 'REPLACE_WITH_REVENUECAT_ANDROID_KEY';

  Future<void> initialize() async {
    if (_androidApiKey.startsWith('REPLACE_WITH')) {
      // API キー未設定 → 課金機能はオフのまま、アプリは通常通り動作する
      debugPrint('SubscriptionService: RevenueCat APIキー未設定のためスキップ');
      return;
    }
    try {
      await Purchases.setLogLevel(LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(_androidApiKey));
      _initialized = true;
    } catch (e) {
      debugPrint('SubscriptionService: 初期化失敗 $e');
    }
  }

  Future<bool> isPremium() async {
    if (!_initialized) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(premiumEntitlementId);
    } catch (e) {
      debugPrint('SubscriptionService: isPremium取得失敗 $e');
      return false;
    }
  }

  Future<Offerings?> getOfferings() async {
    if (!_initialized) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('SubscriptionService: getOfferings失敗 $e');
      return null;
    }
  }

  Future<PurchaseResult?> purchasePackage(Package package) async {
    if (!_initialized) return null;
    try {
      return await Purchases.purchasePackage(package);
    } catch (e) {
      debugPrint('SubscriptionService: 購入失敗 $e');
      rethrow;
    }
  }

  Future<bool> restorePurchases() async {
    if (!_initialized) return false;
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey(premiumEntitlementId);
    } catch (e) {
      debugPrint('SubscriptionService: 復元失敗 $e');
      return false;
    }
  }
}
