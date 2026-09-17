# Claude Code Configuration & Quick Reference

## 🔐 iOS Certificate & API Key Vault

**Location**: https://github.com/zka32101/ios-certs-vault

This private repository contains all iOS build credentials and secrets required for TestFlight distribution:
- **iOS Distribution Certificate** (p12 format) → `OKANE_KORE_IOS_DISTRIBUTION_CERT_BASE64`
- **Provisioning Profile** (mobileprovision) → `OKANE_KORE_IOS_PROVISIONING_PROFILE_BASE64`
- **App Store Connect API Key** (p8 format) → `APPSTORE_API_KEY_BASE64`
- **App Store Connect API Key ID** → `APPSTORE_API_KEY_ID`
- **App Store Connect Issuer ID** → `APPSTORE_ISSUER_ID`

### Setup Instructions
1. Access ios-certs-vault repository (requires GitHub account with access)
2. Extract base64-encoded certificate and profile files
3. Create GitHub Secrets in **okane_kore** repository settings:
   - `OKANE_KORE_IOS_DISTRIBUTION_CERT_BASE64`
   - `OKANE_KORE_IOS_DISTRIBUTION_CERT_PASSWORD`
   - `OKANE_KORE_IOS_PROVISIONING_PROFILE_BASE64`
   - `APPSTORE_API_KEY_BASE64`
   - `APPSTORE_API_KEY_ID`
   - `APPSTORE_ISSUER_ID`
   - `SLACK_WEBHOOK_URL` (for notifications)

### GitHub Actions Workflow
- **File**: `.github/workflows/ios-build.yml`
- **Auto-triggers**:
  - PR creation/update
  - Weekly Friday 10:00 UTC (schedule: '0 10 * * 5')
  - Push to main branch (signed build + TestFlight)
  - Manual trigger (workflow_dispatch)
- **macOS Cost Optimization**: Expensive jobs run only on schedule/PR/main, never on random push

## 🔑 Android Keystore & Release Signing Setup

**Status**: Ready for configuration | **Required for**: Google Play Console submission

### Required Secrets
Add these to GitHub repository secrets (Settings > Secrets and variables > Actions):
- `ANDROID_KEYSTORE_BASE64` — Base64-encoded .jks keystore file
- `ANDROID_KEYSTORE_STORE_PASSWORD` — Keystore password
- `ANDROID_KEYSTORE_PASSWORD` — Private key password
- `ANDROID_KEYSTORE_KEY_ALIAS` — Key alias (default: `release`)

### Setup Instructions

#### 1. Create or Obtain Android Keystore

**Option A: Generate new keystore (recommended for new apps)**
```bash
keytool -genkey -v -keystore okane_kore_release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias release \
  -storepass YOUR_KEYSTORE_PASSWORD \
  -keypass YOUR_KEY_PASSWORD
```

**Option B: Retrieve existing keystore from ios-certs-vault**
- Same repository structure as iOS certificates
- Extract `okane_kore_release.jks` from private vault

#### 2. Encode Keystore to Base64

```bash
base64 -i okane_kore_release.jks > keystore_base64.txt
cat keystore_base64.txt
```

#### 3. Create GitHub Secrets

1. Go to **okane_kore** repository → Settings → Secrets and variables → Actions
2. Create 4 new repository secrets:
   - **Secret name**: `ANDROID_KEYSTORE_BASE64`
     **Value**: Paste the entire base64 output from step 2
   
   - **Secret name**: `ANDROID_KEYSTORE_STORE_PASSWORD`
     **Value**: Your keystore password (from step 1)
   
   - **Secret name**: `ANDROID_KEYSTORE_PASSWORD`
     **Value**: Your private key password (from step 1)
   
   - **Secret name**: `ANDROID_KEYSTORE_KEY_ALIAS`
     **Value**: `release` (or your alias from step 1)

#### 4. Store Keystore Safely

- **DO NOT commit keystore to git** (already in .gitignore)
- Keep backup copy in ios-certs-vault repository (private)
- Never share passwords publicly

### GitHub Actions Workflow
- **File**: `.github/workflows/android-build.yml`
- **Auto-triggers for AAB build**:
  - Manual trigger (workflow_dispatch)
  - Push to main branch (builds & signs AAB for Google Play)
- **Graceful fallback**: If secrets not configured, build skips with informative message
- **Cost optimization**: AAB builds only on explicit triggers (not every PR)

### Local Development (Optional)

**For local testing without GitHub secrets**, add to `android/local.properties`:
```
KEYSTORE_PATH=/path/to/okane_kore_release.jks
KEYSTORE_STORE_PASSWORD=your_keystore_password
```

Then build locally:
```bash
flutter build appbundle --release
```

### Google Play Console Upload

Once AAB is generated and signed by GitHub Actions:
1. Go to **Google Play Console** → okane_kore app → Release → Production
2. Click "Create new release"
3. Upload the signed AAB artifact from GitHub Actions
4. Review app details and submit for review

### Troubleshooting

**Error: "APK/AAB signed with debug key"**
- Cause: Signing secrets not configured
- Solution: Follow setup instructions above, ensure all 4 secrets are added

**Error: "Invalid keystore password"**
- Cause: Secret value doesn't match keystore password
- Solution: Verify password in keystore, update secret with correct value

**Error: "Key alias not found"**
- Cause: `ANDROID_KEYSTORE_KEY_ALIAS` doesn't match keystore alias
- Solution: Verify alias: `keytool -list -v -keystore keystore.jks`

## 💳 RevenueCat Subscription Setup

**Status**: Implementation complete ✅ | **Requires**: API Key configuration

### Required Secrets
Add these to GitHub repository secrets (Settings > Secrets and variables > Actions):
- `REVENUECAT_ANDROID_API_KEY` — Google Play Public API Key from RevenueCat dashboard

Alternatively, add directly to `lib/core/subscription/subscription_service.dart`:
```dart
static const String _androidApiKey = 'YOUR_REVENUECAT_ANDROID_API_KEY';
```

### Configuration Steps
1. **Create RevenueCat Project**
   - Sign up at https://app.revenuecat.com
   - Create new Android app project
   - Get Public API Key from "Project Settings > API Keys"

2. **Create Premium Product**
   - In RevenueCat: Create new Entitlement with ID `premium`
   - Create subscription product (monthly/annual options)
   - Link to Google Play Console product

3. **Google Play Console Integration**
   - Add subscription product to Google Play Console
   - Create "premium" subscription (same as RevenueCat entitlement ID)
   - Configure pricing and availability

4. **Test Account Setup**
   - Create sandbox testing account in Google Play Console
   - Add to app's internal testing track
   - Test purchase flow before production launch

### Implementation Files
- **Service**: `lib/core/subscription/subscription_service.dart`
- **State Management**: `lib/core/subscription/subscription_provider.dart`
- **Paywall UI**: `lib/features/premium/presentation/pages/paywall_page.dart`

### Safety Features
- App runs without crashes if API key is missing (development mode)
- All subscription checks default to `false` if not initialized
- Error handling for network/RevenueCat API failures

## 🏗️ Recent Fixes (Aug 2026)

### Startup Crash Investigation
- **Root Cause**: Firebase initialization timing + Firestore access without completion confirmation
- **Solution**: Changed to ConsumerStatefulWidget + 500ms delay + explicit error handling
- **Files Modified**:
  - `lib/main.dart` - Comprehensive initialization with try-catch blocks
  - `lib/core/firebase/firebase_init.dart` - Connection testing before data load
  - `lib/core/services/notification_service.dart` - Explicit null checks for platform implementation
  - `.github/workflows/ios-build.yml` - Full CI/CD automation with Slack notifications

## 📋 Current Branch
- **Development Branch**: `claude/okane-col-crash-investigation-z0hh4m`
- Push all changes to this branch (protected by default)

## 🎯 KPI Targets
- Day7 リテンション: 24%+
- Day30 リテンション: 16%+
- コンバージョン率: 6%+
- 世帯チャーン率: 10%未満
