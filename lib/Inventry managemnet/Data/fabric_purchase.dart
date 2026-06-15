// ============================================================
// models/fabric_purchase.dart
// Represents a gray fabric purchase entry
// ============================================================

class FabricPurchase {
  final String purchaseId;
  final DateTime purchaseDate;
  final String partyName;
  final String fabricType;
  final String color;
  final double meter;
  final double rate;
  final double totalAmount;
  final String remarks;
  final String invoiceNumber;
  final DateTime createdAt;

  FabricPurchase({
    required this.purchaseId,
    required this.purchaseDate,
    required this.partyName,
    required this.fabricType,
    required this.color,
    required this.meter,
    required this.rate,
    required this.totalAmount,
    this.remarks = '',
    this.invoiceNumber = '',
    required this.createdAt,
  });

  factory FabricPurchase.fromMap(Map<String, dynamic> map, String id) {
    return FabricPurchase(
      purchaseId: id,
      purchaseDate: map['purchaseDate'] != null
          ? (map['purchaseDate'] as dynamic).toDate()
          : DateTime.now(),
      partyName: map['partyName'] ?? '',
      fabricType: map['fabricType'] ?? '',
      color: map['color'] ?? '',
      meter: (map['meter'] as num?)?.toDouble() ?? 0,
      rate: (map['rate'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      remarks: map['remarks'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'purchaseDate': purchaseDate,
      'partyName': partyName,
      'fabricType': fabricType,
      'color': color,
      'meter': meter,
      'rate': rate,
      'totalAmount': totalAmount,
      'remarks': remarks,
      'invoiceNumber': invoiceNumber,
      'createdAt': createdAt,
    };
  }
}
