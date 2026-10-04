# Monetization Implementation Guide

**お金コレ！** uses a freemium model with the following structure:
- **Free Tier**: 広告つき（画面下部のバナー広告）・一部機能に制限
- **Premium Tier**: **月額1米ドル**。広告なし＋出力などの全機能。実際の請求額・表示価格は Google Play の商品設定（RevenueCat 経由）が正

## Architecture Overview

### 1. Subscription Management (RevenueCat)

**Service**: `lib/core/subscription/subscription_service.dart`
- Handles RevenueCat SDK initialization
- Manages premium status checking and purchase handling
- Gracefully handles missing API keys (development mode)

**Provider**: `lib/core/subscription/subscription_provider.dart`
- State management via Riverpod `NotifierProvider`
- Tracks `isPremiumProvider` state
- Auto-refreshes on user authentication changes
- Safe initialization even if RevenueCat not configured

**Setup Required**:
```
1. Go to https://app.revenuecat.com
2. Create a new project and get Public API Key
3. Set as GitHub Secret: REVENUECAT_ANDROID_API_KEY
4. Or update lib/core/subscription/subscription_service.dart line 21
```

### 2. Feature Gating

**System**: `lib/core/subscription/feature_gate.dart`

Defines all premium features:
```dart
enum PremiumFeature {
  investmentSimulationFull,     // プレミアムのみ
  excelExport,                  // プレミアムのみ  
  governmentBenefitsUnlimited,  // プレミアムのみ
  advancedAnalytics,            // プレミアムのみ
  investmentSimulationBasic,    // 無料/プレミアムで利用可能
}
```

**Usage in UI**:
```dart
// Check if feature is available
if (canAccessFeature(ref, PremiumFeature.excelExport)) {
  // Show export button
} else {
  // Disabled, or show paywall
}

// Show paywall dialog when locked feature accessed
PremiumFeatureDialog.show(
  context,
  feature: PremiumFeature.excelExport,
  onUpgradeTap: () => Navigator.push(...PaywallPage...),
);
```

### 3. Ad System (Google Mobile Ads 9.0.0)

> `google_mobile_ads` は **9.0.0 固定**（9.1.0 は iOS の Release ビルドで非モジュラーヘッダーのエラーが出た実績あり）。

**Files** (`lib/core/ads/`):
- `ad_config.dart` — 広告ユニットID・表示判定 `AdConfig.shouldShowAds`（プレミアム購読中は常に非表示）
- `ad_service.dart` — SDK 初期化と UMP 同意取得（失敗しても広告が出ないだけでアプリは動く）
- `ad_banner.dart` — `AdBanner` ウィジェット。購読中・同意未取得・非対応端末では何も描画しない

**対応範囲**: 現在は **Android のバナー広告のみ**（iOS は広告ユニット未発行のため無効）。インタースティシャルは未実装。

**組み込み**: `lib/main.dart` で `AdService().initialize()`（非ブロッキング）、`HomePage` の `bottomNavigationBar` に `AdBanner`。他の画面にも広げる場合は同じウィジェットを置く。

## Ad Unit IDs (Test → Production)

未指定のときは Google 公式のテスト用ID（収益なし）で動く。**公開前に必ず本番IDを渡すこと。**

| 種類 | 渡し方 | テスト用既定値 |
|---|---|---|
| バナー広告ユニットID | `--dart-define=ADMOB_ANDROID_BANNER_ID=ca-app-pub-xxx/yyy` | `ca-app-pub-3940256099942544/6300978111` |
| AdMob アプリID | 環境変数 `ADMOB_APP_ID`（`android/app/build.gradle.kts` の manifestPlaceholders） | `ca-app-pub-3940256099942544~3347511713` |

`AdConfig.isUsingTestIds` で、テストIDのままかどうかを確認できる。

## Feature Gate Mapping

### Free Tier Features
- Investment simulation (2 patterns only) ✅
- Basic dashboard overview ✅
- Savings goals tracking ✅
- Expense category breakdown ✅
- Basic financial health score ✅
- Limited government program info (3 programs)

### Premium-Only Features
- Full investment simulation (8 patterns) 🔒
- Excel/report export functionality 🔒
- Complete government programs database (22 programs) 🔒
- Custom analysis reports 🔒
- 広告なし 🔒

## RevenueCat Setup Steps

### 1. Create App in RevenueCat Dashboard
```
Dashboard → New Project → Select Android
```

### 2. Create Entitlements
```
Project Settings → Entitlements
Create: "premium" (ID must match subscription_service.dart line 6)
```

### 3. Link to Google Play Console
```
RevenueCat Project Settings → App Store Configuration
- Google Play Console: Add your package name
- Add service account JSON
```

### 4. Create Subscription Products
```
RevenueCat Dashboard → Products
Create subscription:
  - ID: premium_monthly
  - Name: お金コレ！プレミアム - 月額
  - Base Plan: Standard
  - Link to Google Play product
```

### 5. Add GitHub Secrets
```
Repository Settings → Secrets and variables → Actions

REVENUECAT_ANDROID_API_KEY: [from RevenueCat Dashboard → API keys]
```

## Testing

### Test RevenueCat Flow Locally
```dart
// In subscription_service.dart, temporarily set:
static const String _androidApiKey = 'YOUR_TEST_KEY';

// Use a test Google Play account to make purchases
```

### Test Ad Display
```dart
// Ads will show with Google's test unit IDs
// No real ad impressions will be charged
// Production IDs will start serving real ads
```

### Test Feature Gating
```dart
// In subscription_provider.dart, modify build() to:
return true;  // Force premium for testing
return false; // Force free tier for testing
```

## Monitoring & Analytics

### RevenueCat Dashboard
- Revenue tracking
- Subscription conversions
- Churn rate monitoring
- MRR (Monthly Recurring Revenue)

### Firebase Analytics
- Feature usage patterns
- Paywall view → conversion tracking
- Ad impression tracking

## Important Notes

⚠️ **Development Mode**: 
- If API keys are not configured, app runs with monetization disabled
- No crashes, all features available free
- Useful for local development and CI/CD testing

⚠️ **Ad Serving**:
- Test unit IDs return test ads only
- Production IDs must be configured before App Store release
- No fill rate during testing is normal behavior

⚠️ **Subscription Testing**:
- Use Google Play internal testing track
- Sandbox account purchases won't affect revenue
- RevenueCat automatically handles testing purchases

## Future Enhancements

1. **Annual Subscription**: ¥1,800/year (save 25%)
2. **Free Trial**: 7-day free trial before charging
3. **Family Plan**: Shareable premium across family members
4. **Milestone Notifications**: "Upgrade benefits" push notifications
5. **Premium Onboarding**: Guided tour of premium features on first purchase

---

**Last Updated**: 2026-09-15  
**Current State**: Basic freemium model operational, ready for monetization testing
