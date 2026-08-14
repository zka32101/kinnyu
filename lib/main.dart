import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/onboarding/presentation/providers/onboarding_provider.dart';
import 'features/user_profile/presentation/providers/user_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/firebase/firebase_init.dart';
import 'core/subscription/subscription_service.dart';
import 'core/subscription/subscription_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 初期化（エラーハンドリング付き）
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  // 通知サービス初期化
  try {
    await NotificationService().initialize();
  } catch (e) {
    print('NotificationService initialization failed: $e');
  }

  // サブスクリプション初期化
  try {
    await SubscriptionService().initialize();
  } catch (e) {
    print('SubscriptionService initialization failed: $e');
  }

  // Firestore 初期化（Firebaseの完全初期化後）
  try {
    // Firebase.initializeApp() 完了後に少し待機してから Firestore にアクセス
    await Future.delayed(const Duration(milliseconds: 500));
    await FirebaseInitializer().initializeTestData();
  } catch (e) {
    print('FirebaseInitializer.initializeTestData() failed: $e');
    // クイズデータ初期化失敗時もアプリは起動可能にする
  }

  runApp(const ProviderScope(child: OkaneKoreApp()));
}

class OkaneKoreApp extends ConsumerStatefulWidget {
  const OkaneKoreApp({Key? key}) : super(key: key);

  @override
  ConsumerState<OkaneKoreApp> createState() => _OkaneKoreAppState();
}

class _OkaneKoreAppState extends ConsumerState<OkaneKoreApp> {
  bool _initializedPremium = false;

  @override
  void initState() {
    super.initState();
    // 一度だけプレミアム状態を取得（initState で一度実行）
    Future.microtask(() {
      if (!_initializedPremium) {
        ref.read(isPremiumProvider.notifier).refresh();
        _initializedPremium = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '金融オンライン大学',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
      home: ref.watch(onboardingCompletedProvider).when(
        data: (onboardingCompleted) {
          // Firebase 一時削除中 — APK テスト版用
          return onboardingCompleted ? const HomePage() : const OnboardingPage();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          body: Center(child: Text('エラー: $error')),
        ),
      ),
    );
  }
}
