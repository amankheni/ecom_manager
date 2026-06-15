// ============================================================
// models/ready_stock.dart
// Represents cumulative ready stock per product/SKU
// Updated automatically when production entry is added
// ============================================================

class ReadyStock {
  final String productId;
  final String productName;
  final String sku;
  final String imageUrl;
  final int qtyM;
  final int qtyL;
  final int qtyXL;
  final int qtyXXL;
  final int total;
  final DateTime updatedAt;

  ReadyStock({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.imageUrl,
    this.qtyM = 0,
    this.qtyL = 0,
    this.qtyXL = 0,
    this.qtyXXL = 0,
    required this.total,
    required this.updatedAt,
  });

  factory ReadyStock.fromMap(Map<String, dynamic> map, String id) {
    return ReadyStock(
      productId: id,
      productName: map['productName'] ?? '',
      sku: map['sku'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      qtyM: (map['M'] as num?)?.toInt() ?? 0,
      qtyL: (map['L'] as num?)?.toInt() ?? 0,
      qtyXL: (map['XL'] as num?)?.toInt() ?? 0,
      qtyXXL: (map['XXL'] as num?)?.toInt() ?? 0,
      total: (map['total'] as num?)?.toInt() ?? 0,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'sku': sku,
      'imageUrl': imageUrl,
      'M': qtyM,
      'L': qtyL,
      'XL': qtyXL,
      'XXL': qtyXXL,
      'total': total,
      'updatedAt': updatedAt,
    };
  }
}
