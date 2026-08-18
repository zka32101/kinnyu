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
import 'features/procedures/presentation/providers/procedures_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 以下の初期化は意図的に「順番に」await している。
  // Firebase.initializeApp() が完了して初めて、Firestore に依存する
  // NotificationService / SubscriptionService / FirebaseInitializer が
  // 安全に動作できるため、並列化はせずこの順序を維持すること。

  // Firebase 初期化（エラーハンドリング付き）
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('[main] Firebase initialization failed: $e');
  }

  // 通知サービス初期化
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('[main] NotificationService initialization failed: $e');
  }

  // サブスクリプション初期化
  try {
    await SubscriptionService().initialize();
  } catch (e) {
    debugPrint('[main] SubscriptionService initialization failed: $e');
  }

  // Firestore 初期化（Firebaseの完全初期化後）
  try {
    // Firebase.initializeApp() は上で await 済みなので、それ自体が
    // Firebase の準備完了の合図であり、追加の待機は本来不要。
    // 念のためごく短い安全マージンだけ残す（不安定な環境向けの保険）。
    await Future.delayed(const Duration(milliseconds: 100));
    await FirebaseInitializer().initializeTestData();
  } catch (e) {
    debugPrint('[main] FirebaseInitializer.initializeTestData() failed: $e');
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
    Future.microtask(() async {
      if (!_initializedPremium) {
        try {
          await ref.read(isPremiumProvider.notifier).refresh();
        } catch (e) {
          debugPrint('[OkaneKoreApp] isPremiumProvider.refresh() failed: $e');
        } finally {
          _initializedPremium = true;
        }
      }
    });

    // 保存済みのライフステージがあれば、制度リマインダーを起動のたびに
    // 再スケジュールする（通知プラグインが年次繰り返しをサポートしないため）。
    Future.microtask(() async {
      try {
        await ref
            .read(lifeStageProvider.notifier)
            .rescheduleRemindersForSavedLifeStage();
      } catch (e) {
        debugPrint('[OkaneKoreApp] rescheduleRemindersForSavedLifeStage() failed: $e');
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
        error: (error, stack) {
          debugPrint('[OkaneKoreApp] onboardingCompletedProvider error: $error\n$stack');
          // エラー画面で行き止まりにせず、オンボーディングへ安全にフォールバックする
          return const OnboardingPage();
        },
      ),
    );
  }
}
