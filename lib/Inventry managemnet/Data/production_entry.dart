// ============================================================
// models/production_entry.dart
// Represents a stitching/production entry (pieces produced per SKU)
// ============================================================

class ProductionEntry {
  final String productionId;
  final String productId;
  final String productName;
  final String sku;
  final int qtyM;
  final int qtyL;
  final int qtyXL;
  final int qtyXXL;
  final int totalPieces;
  final DateTime productionDate;
  final String remarks;
  final DateTime createdAt;

  ProductionEntry({
    required this.productionId,
    required this.productId,
    required this.productName,
    required this.sku,
    this.qtyM = 0,
    this.qtyL = 0,
    this.qtyXL = 0,
    this.qtyXXL = 0,
    required this.totalPieces,
    required this.productionDate,
    this.remarks = '',
    required this.createdAt,
  });

  factory ProductionEntry.fromMap(Map<String, dynamic> map, String id) {
    return ProductionEntry(
      productionId: id,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      sku: map['sku'] ?? '',
      qtyM: (map['M'] as num?)?.toInt() ?? 0,
      qtyL: (map['L'] as num?)?.toInt() ?? 0,
      qtyXL: (map['XL'] as num?)?.toInt() ?? 0,
      qtyXXL: (map['XXL'] as num?)?.toInt() ?? 0,
      totalPieces: (map['totalPieces'] as num?)?.toInt() ?? 0,
      productionDate: map['productionDate'] != null
          ? (map['productionDate'] as dynamic).toDate()
          : DateTime.now(),
      remarks: map['remarks'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'M': qtyM,
      'L': qtyL,
      'XL': qtyXL,
      'XXL': qtyXXL,
      'totalPieces': totalPieces,
      'productionDate': productionDate,
      'remarks': remarks,
      'createdAt': createdAt,
    };
  }
}
