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
