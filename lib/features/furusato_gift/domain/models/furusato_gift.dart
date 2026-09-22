class FurusatoGift {
  final String id;
  final String uid;
  final String municipality; // 寄付先自治体
  final String itemName; // 返礼品名
  final int donationAmount; // 寄付額
  final int taxYear; // 控除の対象となる年（寄付をした年）
  final DateTime donatedDate;
  final bool isReceiptSubmitted; // ワンストップ特例・確定申告の手続き済みか
  final DateTime createdAt;

  const FurusatoGift({
    required this.id,
    required this.uid,
    required this.municipality,
    required this.itemName,
    required this.donationAmount,
    required this.taxYear,
    required this.donatedDate,
    this.isReceiptSubmitted = false,
    required this.createdAt,
  });

  factory FurusatoGift.fromJson(Map<String, dynamic> json) {
    return FurusatoGift(
      id: json['id'] as String,
      uid: json['uid'] as String,
      municipality: json['municipality'] as String,
      itemName: json['itemName'] as String,
      donationAmount: json['donationAmount'] as int,
      taxYear: json['taxYear'] as int,
      donatedDate: DateTime.parse(json['donatedDate'] as String),
      isReceiptSubmitted: json['isReceiptSubmitted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'municipality': municipality,
      'itemName': itemName,
      'donationAmount': donationAmount,
      'taxYear': taxYear,
      'donatedDate': donatedDate.toIso8601String(),
      'isReceiptSubmitted': isReceiptSubmitted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  FurusatoGift copyWith({
    String? municipality,
    String? itemName,
    int? donationAmount,
    int? taxYear,
    DateTime? donatedDate,
    bool? isReceiptSubmitted,
  }) {
    return FurusatoGift(
      id: id,
      uid: uid,
      municipality: municipality ?? this.municipality,
      itemName: itemName ?? this.itemName,
      donationAmount: donationAmount ?? this.donationAmount,
      taxYear: taxYear ?? this.taxYear,
      donatedDate: donatedDate ?? this.donatedDate,
      isReceiptSubmitted: isReceiptSubmitted ?? this.isReceiptSubmitted,
      createdAt: createdAt,
    );
  }
}
