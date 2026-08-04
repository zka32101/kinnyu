enum ReceiptCategory { convenience, grocery, dining, entertainment, other }

class Receipt {
  final String id;
  final String uid;
  final String? imagePath;
  final DateTime date;
  final ReceiptCategory category;
  final int amount;
  final DateTime createdAt;

  Receipt({
    required this.id,
    required this.uid,
    this.imagePath,
    required this.date,
    required this.category,
    required this.amount,
    required this.createdAt,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] as String,
      uid: json['uid'] as String,
      imagePath: json['imagePath'] as String?,
      date: DateTime.parse(json['date'] as String),
      category: ReceiptCategory.values[json['category'] as int],
      amount: json['amount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'imagePath': imagePath,
      'date': date.toIso8601String(),
      'category': category.index,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ReceiptCategoryInfo {
  static const Map<ReceiptCategory, String> displayNames = {
    ReceiptCategory.convenience: 'コンビニ',
    ReceiptCategory.grocery: '食料品',
    ReceiptCategory.dining: '外食',
    ReceiptCategory.entertainment: '娯楽',
    ReceiptCategory.other: 'その他',
  };
}
