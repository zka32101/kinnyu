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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initialize();
  await SubscriptionService().initialize();
  // クイズ問題データを Firestore に投入（初回のみ）
  await FirebaseInitializer().initializeTestData();
  runApp(const ProviderScope(child: OkaneKoreApp()));
}

class OkaneKoreApp extends ConsumerWidget {
  const OkaneKoreApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(isPremiumProvider.notifier).refresh();
    });
    return MaterialApp(
      title: 'お金コレ！',
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
