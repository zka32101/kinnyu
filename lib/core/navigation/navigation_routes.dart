import 'package:flutter/material.dart';
import '../../features/household/presentation/pages/financial_health_detail_page.dart';
import '../../features/household/presentation/pages/insights_detail_page.dart';
import '../../features/household/presentation/pages/expense_list_page.dart';

/// アプリ全体のナビゲーション定義
class NavigationRoutes {
  /// 財務健全性スコア詳細ページへナビゲート
  static Future<void> navigateToFinancialHealthDetail(
    BuildContext context,
    String groupId,
  ) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FinancialHealthDetailPage(groupId: groupId),
      ),
    );
  }

  /// AI インサイト詳細ページへナビゲート
  static Future<void> navigateToInsightsDetail(
    BuildContext context,
    String groupId, {
    String locale = 'ja',
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InsightsDetailPage(groupId: groupId, locale: locale),
      ),
    );
  }

  /// 支出一覧ページへナビゲート
  static Future<void> navigateToExpenseList(
    BuildContext context,
    String groupId,
    String userId,
  ) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseListPage(groupId: groupId, userId: userId),
      ),
    );
  }
}
