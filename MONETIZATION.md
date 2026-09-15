# Monetization Implementation Guide

**お金コレ！** uses a freemium model with the following structure:
- **Free Tier**: Ad-supported, limited features
- **Premium Tier**: ¥200/month subscription, full feature access, no ads

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

### 3. Ad System (Google Mobile Ads)

**Service**: `lib/core/ads/ad_service.dart`
- Singleton service managing banner and interstitial ads
- Gracefully degrades if MobileAds not initialized
- Test ad unit IDs (replace with production IDs before release)

**Initialization**: Called in `lib/main.dart` after subscription service

**Ad Types**:
1. **Banner Ads** - Bottom of free tier screens (constantly loaded)
2. **Interstitial Ads** - Full-screen ads on major navigation (preloaded, shown on demand)

**Provider**: `lib/core/ads/ad_provider.dart`
- `shouldShowAdsProvider`: Checks if user is free tier
- `interstitialAdProvider`: Auto-preloads full-screen ads
- `bannerAdProvider`: Manages banner ad lifecycle

### 4. UI Integration

#### AdScaffold (Recommended)

Replace `Scaffold` with `AdScaffold` to auto-add banner ads:
```dart
AdScaffold(
  appBar: AppBar(title: const Text('Dashboard')),
  body: const DashboardPage(),
)
```

#### Manual Ad Display

For custom layouts:
```dart
AdBannerWidget(adService: ref.watch(adServiceProvider))
```

#### Showing Interstitial Ads

Call before navigation to important pages:
```dart
final adService = ref.read(adServiceProvider);
if (ref.read(shouldShowAdsProvider)) {
  await adService.showInterstitialAd();
}
Navigator.push(context, MaterialPageRoute(...));
```

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
- No ads 🔒

## Ad Unit IDs (Test → Production)

**Current Test IDs**:
- Banner: `ca-app-pub-3940256099942544/6300978111`
- Interstitial: `ca-app-pub-3940256099942544/1033173712`

**To Update Production IDs**:
1. Get IDs from Google AdMob dashboard
2. Update `lib/core/ads/ad_service.dart` lines 23-24
3. Rebuild and submit to Play Store

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
