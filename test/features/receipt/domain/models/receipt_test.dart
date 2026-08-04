import 'package:flutter_test/flutter_test.dart';
import 'package:okane_kore/features/receipt/domain/models/receipt.dart';

void main() {
  group('Receipt', () {
    test('fromJson creates a valid receipt', () {
      final now = DateTime.now();
      final json = {
        'id': 'receipt1',
        'uid': 'user123',
        'imagePath': '/path/to/image.jpg',
        'date': now.toIso8601String(),
        'category': 0, // ReceiptCategory.convenience
        'amount': 5000,
        'createdAt': now.toIso8601String(),
      };

      final receipt = Receipt.fromJson(json);

      expect(receipt.id, equals('receipt1'));
      expect(receipt.uid, equals('user123'));
      expect(receipt.imagePath, equals('/path/to/image.jpg'));
      expect(receipt.category, equals(ReceiptCategory.convenience));
      expect(receipt.amount, equals(5000));
    });

    test('toJson serializes correctly', () {
      final now = DateTime.now();
      final receipt = Receipt(
        id: 'receipt1',
        uid: 'user123',
        imagePath: '/path/to/image.jpg',
        date: now,
        category: ReceiptCategory.dining,
        amount: 3000,
        createdAt: now,
      );

      final json = receipt.toJson();

      expect(json['id'], equals('receipt1'));
      expect(json['uid'], equals('user123'));
      expect(json['amount'], equals(3000));
      expect(json['category'], equals(ReceiptCategory.dining.index));
    });

    test('category display names are correct', () {
      expect(
        ReceiptCategoryInfo.displayNames[ReceiptCategory.convenience],
        equals('コンビニ'),
      );
      expect(
        ReceiptCategoryInfo.displayNames[ReceiptCategory.grocery],
        equals('食料品'),
      );
      expect(
        ReceiptCategoryInfo.displayNames[ReceiptCategory.dining],
        equals('外食'),
      );
    });
  });
}
