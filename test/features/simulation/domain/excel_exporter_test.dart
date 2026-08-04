import 'package:excel/excel.dart' as xl;
import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/simulation/domain/models/household_simulator.dart';
import 'package:okane_kore/features/simulation/domain/services/excel_exporter.dart';

void main() {
  group('HouseholdExcelExporter.buildBytes', () {
    late List<DetailedYearResult> results;

    setUp(() {
      final plans = [
        const YearlyPlan(year: 1, monthlyIncome: 300000, monthlyExpense: 220000),
        const YearlyPlan(year: 2, monthlyIncome: 320000, monthlyExpense: 230000),
        const YearlyPlan(year: 3, monthlyIncome: 340000, monthlyExpense: 240000),
      ];
      results = HouseholdSimulator.simulateDetailed(
        plans: plans,
        investmentReturnPercent: 3,
      );
    });

    test('produces non-empty, decodable xlsx bytes', () {
      final bytes = HouseholdExcelExporter.buildBytes(results);
      expect(bytes, isNotEmpty);

      final decoded = xl.Excel.decodeBytes(bytes);
      expect(decoded.tables.containsKey('家計シミュレーション'), isTrue);
    });

    test('header row matches expected columns', () {
      final bytes = HouseholdExcelExporter.buildBytes(results);
      final decoded = xl.Excel.decodeBytes(bytes);
      final sheet = decoded.tables['家計シミュレーション']!;

      final headerRow = sheet.row(0);
      final headerTexts = headerRow.map((c) => c?.value.toString()).toList();

      expect(headerTexts, containsAll(['年', '月収', '月支出', '毎月貯蓄', '累計元本', '評価額', '運用益']));
    });

    test('data rows count matches results length', () {
      final bytes = HouseholdExcelExporter.buildBytes(results);
      final decoded = xl.Excel.decodeBytes(bytes);
      final sheet = decoded.tables['家計シミュレーション']!;

      // ヘッダー行 + データ行数
      expect(sheet.maxRows, equals(results.length + 1));
    });

    test('year values in sheet match input results in order', () {
      final bytes = HouseholdExcelExporter.buildBytes(results);
      final decoded = xl.Excel.decodeBytes(bytes);
      final sheet = decoded.tables['家計シミュレーション']!;

      for (var i = 0; i < results.length; i++) {
        final cell = sheet.cell(
          xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1),
        );
        expect(cell.value.toString(), equals(results[i].year.toString()));
      }
    });

    test('does not throw for empty results', () {
      expect(() => HouseholdExcelExporter.buildBytes([]), returnsNormally);
    });
  });
}
