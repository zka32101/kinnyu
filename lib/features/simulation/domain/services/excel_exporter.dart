import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import '../models/household_simulator.dart';

/// 家計シミュレーション結果をExcel（.xlsx）ファイルとして出力する。
class HouseholdExcelExporter {
  static const _sheetName = '家計シミュレーション';

  /// DetailedYearResult のリストからワークブックを構築し、
  /// アプリの一時ディレクトリにファイルとして保存してそのパスを返す。
  static Future<File> export(
    List<DetailedYearResult> results, {
    String fileNamePrefix = 'okane_kore_simulation',
  }) async {
    final bytes = buildBytes(results);

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/${fileNamePrefix}_$timestamp.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// テスト容易性のため、ファイルI/Oと切り離してバイト列を構築する部分を分離。
  static List<int> buildBytes(List<DetailedYearResult> results) {
    final workbook = xl.Excel.createExcel();
    final sheet = workbook[_sheetName];

    // デフォルトで作られる 'Sheet1' を削除
    if (workbook.sheets.containsKey('Sheet1')) {
      workbook.delete('Sheet1');
    }

    const headers = ['年', '月収', '月支出', '毎月貯蓄', '累計元本', '評価額', '運用益'];
    for (var col = 0; col < headers.length; col++) {
      sheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .value = xl.TextCellValue(headers[col]);
    }

    for (var i = 0; i < results.length; i++) {
      final r = results[i];
      final row = i + 1;
      final values = <xl.CellValue>[
        xl.IntCellValue(r.year),
        xl.IntCellValue(r.monthlyIncome),
        xl.IntCellValue(r.monthlyExpense),
        xl.IntCellValue(r.monthlySavings),
        xl.IntCellValue(r.principal),
        xl.DoubleCellValue(r.balance),
        xl.DoubleCellValue(r.profit),
      ];
      for (var col = 0; col < values.length; col++) {
        sheet
            .cell(xl.CellIndex.indexByColumnRow(
                columnIndex: col, rowIndex: row))
            .value = values[col];
      }
    }

    final encoded = workbook.encode();
    if (encoded == null) {
      throw Exception('Excelファイルのエンコードに失敗しました');
    }
    return encoded;
  }
}
