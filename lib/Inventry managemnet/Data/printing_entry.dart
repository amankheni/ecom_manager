// ============================================================
// models/printing_entry.dart
// Represents a digital printing entry (fabric used per SKU)
// ============================================================

class PrintingEntry {
  final String printingId;
  final String productId;
  final String productName;
  final String sku;
  final String imageUrl;
  final double meterUsed;
  final DateTime printingDate;
  final String remarks;
  final DateTime createdAt;

  PrintingEntry({
    required this.printingId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.imageUrl,
    required this.meterUsed,
    required this.printingDate,
    this.remarks = '',
    required this.createdAt,
  });

  factory PrintingEntry.fromMap(Map<String, dynamic> map, String id) {
    return PrintingEntry(
      printingId: id,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      sku: map['sku'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      meterUsed: (map['meterUsed'] as num?)?.toDouble() ?? 0,
      printingDate: map['printingDate'] != null
          ? (map['printingDate'] as dynamic).toDate()
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
      'imageUrl': imageUrl,
      'meterUsed': meterUsed,
      'printingDate': printingDate,
      'remarks': remarks,
      'createdAt': createdAt,
    };
  }
}
