import 'dart:async';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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

/// アプリ全体で捕捉できなかった例外がプロセスごとクラッシュするのを防ぐための
/// グローバルなエラーハンドリング。
/// - FlutterError.onError: ウィジェットのbuild/layout/paint中の例外
/// - PlatformDispatcher.onError: async/Zone境界をまたいだ未捕捉例外
/// - runZonedGuarded の onError: 上記2つでも拾いきれない、mainの外側の例外
/// いずれも「ログに残して処理を続行する」ことを優先し、可能な限りFirebase
/// Crashlyticsへ記録する（Crashlytics自体が未初期化/失敗していてもアプリを
/// 巻き込まないよう二重にtry-catchする）。
void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 以下の初期化は意図的に「順番に」await している。
    // Firebase.initializeApp() が完了して初めて、Firestore に依存する
    // NotificationService / SubscriptionService / FirebaseInitializer が
    // 安全に動作できるため、並列化はせずこの順序を維持すること。

    // Firebase 初期化（エラーハンドリング付き）
    bool firebaseInitialized = false;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      firebaseInitialized = true;
    } catch (e, stack) {
      debugPrint('[main] Firebase initialization failed: $e\n$stack');
    }

    // Crashlyticsが使えるようになった時点で、以後のFlutter側の未捕捉例外を
    // すべてCrashlyticsへ送るようにする（Firebase初期化に失敗した場合は
    // スキップし、デバッグログのみに留める）。
    if (firebaseInitialized) {
      try {
        FlutterError.onError = (FlutterErrorDetails details) {
          // 既存の挙動（コンソール出力・デバッグ時の赤画面表示）は維持しつつ、
          // 追加でCrashlyticsにも記録する。
          FlutterError.presentError(details);
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        };
        PlatformDispatcher.instance.onError = (error, stack) {
          debugPrint('[main] Uncaught platform error: $error\n$stack');
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      } catch (e, stack) {
        debugPrint('[main] Failed to wire up Crashlytics error handlers: $e\n$stack');
      }
    }

    // 通知サービス初期化
    try {
      await NotificationService().initialize();
    } catch (e, stack) {
      debugPrint('[main] NotificationService initialization failed: $e\n$stack');
    }

    // サブスクリプション初期化
    try {
      await SubscriptionService().initialize();
    } catch (e, stack) {
      debugPrint('[main] SubscriptionService initialization failed: $e\n$stack');
    }

    // Firestore 初期化（Firebaseの完全初期化後）
    try {
      // Firebase.initializeApp() は上で await 済みなので、それ自体が
      // Firebase の準備完了の合図であり、追加の待機は本来不要。
      // 念のためごく短い安全マージンだけ残す（不安定な環境向けの保険）。
      await Future.delayed(const Duration(milliseconds: 100));
      await FirebaseInitializer().initializeTestData();
    } catch (e, stack) {
      debugPrint('[main] FirebaseInitializer.initializeTestData() failed: $e\n$stack');
      // クイズデータ初期化失敗時もアプリは起動可能にする
    }

    // build/layout/paint中の例外でアプリ全体が落ちるのを防ぎ、代わりに
    // 最低限の復旧可能なエラー画面を表示する（release/profileビルドでは
    // デフォルトのErrorWidgetはほぼ何も表示しないグレー画面になるため）。
    ErrorWidget.builder = (FlutterErrorDetails details) {
      debugPrint('[ErrorWidget] ${details.exception}\n${details.stack}');
      return Material(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                SizedBox(height: 12),
                Text(
                  '予期しないエラーが発生しました。\nアプリを再起動してみてください。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      );
    };

    runApp(const ProviderScope(child: OkaneKoreApp()));
  }, (error, stack) {
    // Flutter/Firebaseの初期化より前、あるいはZoneをまたいだ箇所で発生した
    // 未捕捉例外の最終防衛ライン。ここに到達した時点でCrashlyticsが使える
    // 保証はないため、必ずtry-catchで包む。
    debugPrint('[main] Uncaught zone error: $error\n$stack');
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (_) {
      // Crashlytics自体が使えない場合は握りつぶす（ログ出力のみで十分）。
    }
  });
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
