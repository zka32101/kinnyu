import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'subscription_provider.dart';

/// 課金機能の種類定義。
/// プレミアム機能とそのグループを指定する際に使用。
enum PremiumFeature {
  /// 投資シミュレーション（全8パターンの制限なし利用）
  investmentSimulationFull('投資シミュレーション（全パターン）'),

  /// Excel エクスポート機能
  excelExport('ダッシュボード・レポート出力'),

  /// 全政策・制度・補助金情報（22制度の詳細表示）
  governmentBenefitsUnlimited('政策・制度・補助金（全22制度）'),

  /// 高度な分析・カスタムレポート
  advancedAnalytics('カスタム分析レポート'),

  /// 無料ユーザーは各シミュレーション2パターンに制限、プレミアムは無制限
  investmentSimulationBasic('投資シミュレーション（基本）');

  final String displayName;
  const PremiumFeature(this.displayName);
}

/// プレミアム機能の可用性をチェックするプロバイダー。
/// 無料ユーザーが premium 機能にアクセスしようとした場合、
/// canAccessPremiumFeature(ref, feature) で false が返る。
/// その場合、UI は PaywallPage へのナビゲーションを提案すべき。
final featureAvailabilityProvider = Provider.family<bool, PremiumFeature>(
  (ref, feature) {
    final isPremium = ref.watch(isPremiumProvider);

    // プレミアムユーザーは全機能にアクセス可能
    if (isPremium) return true;

    // 無料ユーザーがアクセスできる機能のホワイトリスト
    switch (feature) {
      // 無料ユーザーが制限付きで使える機能
      case PremiumFeature.investmentSimulationBasic:
        return true; // 基本シミュレーションは無料で利用可能

      // 無料ユーザーは利用不可
      case PremiumFeature.investmentSimulationFull:
      case PremiumFeature.excelExport:
      case PremiumFeature.governmentBenefitsUnlimited:
      case PremiumFeature.advancedAnalytics:
        return false;
    }
  },
);

/// フィーチャーゲートを確認し、無料ユーザーが制限機能にアクセスしようとした場合は
/// false を返す便利なヘルパー。
///
/// 使用例:
/// ```dart
/// if (canAccessFeature(ref, PremiumFeature.excelExport)) {
///   // エクスポートボタンを表示
/// } else {
///   // ペイウォール誘導
/// }
/// ```
bool canAccessFeature(WidgetRef ref, PremiumFeature feature) {
  return ref.read(featureAvailabilityProvider(feature));
}

/// 無料ユーザーが premium 機能へのアクセスをリクエストした際のコールバック型。
/// UI側で「ペイウォール画面へ移動」などの処理を決められるようにするため、
/// この typedef を使う。
typedef OnFeatureLocked = void Function(PremiumFeature feature);
