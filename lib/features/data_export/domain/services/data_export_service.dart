import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import '../../../subscription_audit/domain/models/subscription.dart';
import '../../../savings_goal/domain/models/savings_goal.dart';
import '../../../furusato_gift/domain/models/furusato_gift.dart';

/// 各機能で記録したデータをExcel（.xlsx）ファイルとして出力する。
/// サブスク・貯金目標・ふるさと納税の記録を、それぞれ別シートにまとめる。
class DataExportService {
  static Future<File> export({
    required List<Subscription> subscriptions,
    required List<SavingsGoal> savingsGoals,
    required List<FurusatoGift> furusatoGifts,
    String fileNamePrefix = 'okane_kore_export',
  }) async {
    final bytes = buildBytes(
      subscriptions: subscriptions,
      savingsGoals: savingsGoals,
      furusatoGifts: furusatoGifts,
    );

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/${fileNamePrefix}_$timestamp.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// テスト容易性のため、ファイルI/Oと切り離してバイト列を構築する部分を分離。
  static List<int> buildBytes({
    required List<Subscription> subscriptions,
    required List<SavingsGoal> savingsGoals,
    required List<FurusatoGift> furusatoGifts,
  }) {
    final workbook = xl.Excel.createExcel();

    _writeSubscriptionsSheet(workbook, subscriptions);
    _writeSavingsGoalsSheet(workbook, savingsGoals);
    _writeFurusatoGiftsSheet(workbook, furusatoGifts);

    // デフォルトで作られる 'Sheet1' を削除
    if (workbook.sheets.containsKey('Sheet1')) {
      workbook.delete('Sheet1');
    }

    final encoded = workbook.encode();
    if (encoded == null) {
      throw Exception('Excelファイルのエンコードに失敗しました');
    }
    return encoded;
  }

  static void _writeSubscriptionsSheet(
      xl.Excel workbook, List<Subscription> subscriptions) {
    final sheet = workbook['サブスク'];
    const headers = ['サービス名', '金額', '請求サイクル', 'カテゴリ', '契約中', '登録日'];
    _writeHeaderRow(sheet, headers);

    for (var i = 0; i < subscriptions.length; i++) {
      final s = subscriptions[i];
      _writeRow(sheet, i + 1, [
        xl.TextCellValue(s.name),
        xl.IntCellValue(s.amount),
        xl.TextCellValue(s.billingCycle.displayName),
        xl.TextCellValue(s.category.displayName),
        xl.TextCellValue(s.isActive ? '契約中' : '解約済み'),
        xl.TextCellValue(_formatDate(s.createdAt)),
      ]);
    }
  }

  static void _writeSavingsGoalsSheet(
      xl.Excel workbook, List<SavingsGoal> savingsGoals) {
    final sheet = workbook['貯金目標'];
    const headers = ['目標名', '目標金額', '現在の積立額', '達成期限', '達成済み'];
    _writeHeaderRow(sheet, headers);

    for (var i = 0; i < savingsGoals.length; i++) {
      final g = savingsGoals[i];
      _writeRow(sheet, i + 1, [
        xl.TextCellValue(g.name),
        xl.IntCellValue(g.targetAmount),
        xl.IntCellValue(g.currentAmount),
        xl.TextCellValue(_formatDate(g.deadline)),
        xl.TextCellValue(g.isAchieved ? '達成' : '未達成'),
      ]);
    }
  }

  static void _writeFurusatoGiftsSheet(
      xl.Excel workbook, List<FurusatoGift> furusatoGifts) {
    final sheet = workbook['ふるさと納税'];
    const headers = ['寄付先自治体', '返礼品名', '寄付金額', '対象年', '寄付日', '手続き済み'];
    _writeHeaderRow(sheet, headers);

    for (var i = 0; i < furusatoGifts.length; i++) {
      final g = furusatoGifts[i];
      _writeRow(sheet, i + 1, [
        xl.TextCellValue(g.municipality),
        xl.TextCellValue(g.itemName),
        xl.IntCellValue(g.donationAmount),
        xl.IntCellValue(g.taxYear),
        xl.TextCellValue(_formatDate(g.donatedDate)),
        xl.TextCellValue(g.isReceiptSubmitted ? '済み' : '未了'),
      ]);
    }
  }

  static void _writeHeaderRow(xl.Sheet sheet, List<String> headers) {
    for (var col = 0; col < headers.length; col++) {
      sheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .value = xl.TextCellValue(headers[col]);
    }
  }

  static void _writeRow(xl.Sheet sheet, int row, List<xl.CellValue> values) {
    for (var col = 0; col < values.length; col++) {
      sheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .value = values[col];
    }
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
