import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/glossary/domain/models/glossary_term.dart';

void main() {
  group('GlossaryData', () {
    test('has at least 25 terms', () {
      expect(GlossaryData.terms.length, greaterThanOrEqualTo(25));
    });

    test('all term IDs are unique', () {
      final ids = GlossaryData.terms.map((t) => t.id).toSet();
      expect(ids.length, equals(GlossaryData.terms.length));
    });

    test('every term has non-empty term, reading and definition', () {
      for (final t in GlossaryData.terms) {
        expect(t.term.trim(), isNotEmpty, reason: '${t.id}: term が空');
        expect(t.reading.trim(), isNotEmpty, reason: '${t.id}: reading が空');
        expect(t.definition.trim(), isNotEmpty,
            reason: '${t.id}: definition が空');
      }
    });

    test('every category has at least one term', () {
      for (final c in GlossaryCategory.values) {
        expect(GlossaryData.byCategory(c), isNotEmpty,
            reason: '$c のカテゴリに用語がない');
      }
    });

    test('search finds terms by term name', () {
      final result = GlossaryData.search('複利');
      expect(result.any((t) => t.term == '複利'), isTrue);
    });

    test('search finds terms by reading', () {
      final result = GlossaryData.search('にーさ');
      expect(result.any((t) => t.term == 'NISA'), isTrue);
    });

    test('search with empty keyword returns all terms', () {
      expect(GlossaryData.search('').length, equals(GlossaryData.terms.length));
    });

    test('search with no match returns empty', () {
      expect(GlossaryData.search('存在しない用語xyz'), isEmpty);
    });
  });
}
