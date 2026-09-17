import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/receipt_service.dart';
import '../pages/expense_list_page.dart';

// Import the ReceiptService from the receipt feature
// Note: In the actual project, adjust the import path accordingly

/// レシートサービスプロバイダー
final expenseServiceProvider = Provider((ref) {
  return ReceiptService();
});

/// 月間支出一覧プロバイダー
/// パラメータ: (userId, year, month)
final monthlyExpenseListProvider = FutureProvider.autoDispose
    .family<List<ExpenseRecord>, (String, int, int)>((ref, params) async {
  final (userId, year, month) = params;
  final service = ref.watch(expenseServiceProvider);

  try {
    final receipts = await service.getMonthlyReceipts(
      userId,
      year: year,
      month: month,
    );

    // Convert Receipt to ExpenseRecord
    return receipts.map((receipt) {
      final categoryDisplay = _formatCategoryName(receipt.category.toString());
      return ExpenseRecord(
        id: receipt.id,
        category: receipt.category.toString(),
        categoryDisplay: categoryDisplay,
        amount: receipt.amount,
        date: receipt.date,
        userNickname: null, // Can be populated from household member data
      );
    }).toList();
  } catch (e) {
    throw Exception('Failed to fetch monthly expenses: $e');
  }
});

/// カテゴリ別支出プロバイダー
final expensesByCategoryProvider = FutureProvider.autoDispose
    .family<List<ExpenseRecord>, (String, String)>((ref, params) async {
  final (userId, category) = params;
  final service = ref.watch(expenseServiceProvider);

  try {
    // Parse category string back to enum
    final categoryEnum = _parseCategoryEnum(category);
    final receipts = await service.getReceiptsByCategory(
      userId,
      category: categoryEnum,
    );

    return receipts.map((receipt) {
      final categoryDisplay = _formatCategoryName(receipt.category.toString());
      return ExpenseRecord(
        id: receipt.id,
        category: receipt.category.toString(),
        categoryDisplay: categoryDisplay,
        amount: receipt.amount,
        date: receipt.date,
        userNickname: null,
      );
    }).toList();
  } catch (e) {
    throw Exception('Failed to fetch expenses by category: $e');
  }
});

// ===== Helper Functions =====

String _formatCategoryName(String category) {
  const names = {
    'ReceiptCategory.convenience': '便利店',
    'ReceiptCategory.grocery': '食料品',
    'ReceiptCategory.dining': '飲食',
    'ReceiptCategory.entertainment': '娯楽',
    'ReceiptCategory.other': 'その他',
  };
  return names[category] ?? category;
}

// Parse category string back to enum
// This is a placeholder - adjust based on actual ReceiptCategory enum values
ReceiptCategory _parseCategoryEnum(String categoryString) {
  // Assuming the enum values are available
  // This is a simplified version - adjust as needed
  return ReceiptCategory.other;
}

// Import ReceiptCategory enum (adjust path as needed)
// For now, this is a minimal implementation
enum ReceiptCategory {
  convenience,
  grocery,
  dining,
  entertainment,
  other,
}
