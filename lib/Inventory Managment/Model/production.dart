// ============================================================
// models/production.dart
// Data models for the full production pipeline:
// ClothPurchase → PrintJob → StitchJob → Inventory
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

// ── STATUS ENUM ──────────────────────────────────────────────
enum JobStatus { pending, inProgress, completed }

extension JobStatusExt on JobStatus {
  String get label {
    switch (this) {
      case JobStatus.pending:
        return 'Pending';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.completed:
        return 'Completed';
    }
  }

  String get value {
    switch (this) {
      case JobStatus.pending:
        return 'pending';
      case JobStatus.inProgress:
        return 'in_progress';
      case JobStatus.completed:
        return 'completed';
    }
  }

  static JobStatus fromString(String s) {
    switch (s) {
      case 'in_progress':
        return JobStatus.inProgress;
      case 'completed':
        return JobStatus.completed;
      default:
        return JobStatus.pending;
    }
  }
}

// ════════════════════════════════════════════════════════════
// 1. CLOTH PURCHASE
//    Collection: cloth_purchases
//    Entry when raw cloth arrives from supplier
// ════════════════════════════════════════════════════════════
class ClothPurchase {
  final String id;
  final String invoiceNo; // Supplier invoice number
  final String partyName; // Supplier / party name
  final DateTime purchaseDate;
  final double totalMeters; // Total meters purchased
  final double remainingMeters; // Decremented as print jobs consume cloth
  final String? notes;
  final DateTime createdAt;

  ClothPurchase({
    required this.id,
    required this.invoiceNo,
    required this.partyName,
    required this.purchaseDate,
    required this.totalMeters,
    required this.remainingMeters,
    this.notes,
    required this.createdAt,
  });

  factory ClothPurchase.fromMap(Map<String, dynamic> map, String id) {
    return ClothPurchase(
      id: id,
      invoiceNo: map['invoiceNo'] ?? '',
      partyName: map['partyName'] ?? '',
      purchaseDate: (map['purchaseDate'] as Timestamp).toDate(),
      totalMeters: (map['totalMeters'] as num).toDouble(),
      remainingMeters: (map['remainingMeters'] as num).toDouble(),
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'invoiceNo': invoiceNo,
    'partyName': partyName,
    'purchaseDate': Timestamp.fromDate(purchaseDate),
    'totalMeters': totalMeters,
    'remainingMeters': remainingMeters,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
    'createdAt': FieldValue.serverTimestamp(),
  };

  ClothPurchase copyWith({
    String? invoiceNo,
    String? partyName,
    DateTime? purchaseDate,
    double? totalMeters,
    double? remainingMeters,
    String? notes,
  }) => ClothPurchase(
    id: id,
    invoiceNo: invoiceNo ?? this.invoiceNo,
    partyName: partyName ?? this.partyName,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    totalMeters: totalMeters ?? this.totalMeters,
    remainingMeters: remainingMeters ?? this.remainingMeters,
    notes: notes ?? this.notes,
    createdAt: createdAt,
  );
}

// ════════════════════════════════════════════════════════════
// 2. PRINT JOB
//    Collection: print_jobs
//    Created when cloth is sent to digital printing
// ════════════════════════════════════════════════════════════
class PrintJob {
  final String id;
  final String purchaseId; // References cloth_purchases document
  final String productId; // References products document (for SKU/name)
  final String productName; // Denormalised for display speed
  final String productSku; // Denormalised for display speed
  final String designName; // Design / print name
  final double metersUsed; // Meters of cloth used from the purchase
  final JobStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final String? notes;

  // Avg consumption pulled from Product — shown as expected-pieces hint
  final double? avgConsumption;

  PrintJob({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.designName,
    required this.metersUsed,
    required this.status,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    this.notes,
    this.avgConsumption,
  });

  /// Expected pieces = metersUsed / avgConsumption
  int? get expectedPieces {
    if (avgConsumption == null || avgConsumption! <= 0) return null;
    return (metersUsed / avgConsumption!).floor();
  }

  factory PrintJob.fromMap(Map<String, dynamic> map, String id) {
    return PrintJob(
      id: id,
      purchaseId: map['purchaseId'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productSku: map['productSku'] ?? '',
      designName: map['designName'] ?? '',
      metersUsed: (map['metersUsed'] as num).toDouble(),
      status: JobStatusExt.fromString(map['status'] ?? 'pending'),
      startedAt: map['startedAt'] != null
          ? (map['startedAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      notes: map['notes'],
      avgConsumption: map['avgConsumption'] != null
          ? (map['avgConsumption'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'purchaseId': purchaseId,
    'productId': productId,
    'productName': productName,
    'productSku': productSku,
    'designName': designName,
    'metersUsed': metersUsed,
    'status': status.value,
    if (startedAt != null) 'startedAt': Timestamp.fromDate(startedAt!),
    if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
    'createdAt': FieldValue.serverTimestamp(),
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
    if (avgConsumption != null) 'avgConsumption': avgConsumption,
  };
}

// ════════════════════════════════════════════════════════════
// 3. STITCH JOB
//    Collection: stitch_jobs
//    Created when printed cloth moves to stitching
// ════════════════════════════════════════════════════════════
class StitchJob {
  final String id;
  final String printJobId; // References print_jobs document
  final String productId; // References products
  final String productName; // Denormalised
  final String productSku; // Denormalised

  // Pieces distributed by size, e.g. { "M": 50, "L": 40, "XL": 30 }
  final Map<String, int> piecesBySize;

  final JobStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final String? notes;

  StitchJob({
    required this.id,
    required this.printJobId,
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.piecesBySize,
    required this.status,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    this.notes,
  });

  int get totalPieces => piecesBySize.values.fold(0, (a, b) => a + b);

  factory StitchJob.fromMap(Map<String, dynamic> map, String id) {
    final raw = map['piecesBySize'] as Map<String, dynamic>? ?? {};
    final pieces = raw.map((k, v) => MapEntry(k, (v as num).toInt()));

    return StitchJob(
      id: id,
      printJobId: map['printJobId'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productSku: map['productSku'] ?? '',
      piecesBySize: pieces,
      status: JobStatusExt.fromString(map['status'] ?? 'pending'),
      startedAt: map['startedAt'] != null
          ? (map['startedAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() => {
    'printJobId': printJobId,
    'productId': productId,
    'productName': productName,
    'productSku': productSku,
    'piecesBySize': piecesBySize,
    'status': status.value,
    if (startedAt != null) 'startedAt': Timestamp.fromDate(startedAt!),
    if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
    'createdAt': FieldValue.serverTimestamp(),
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
  };
}

// ════════════════════════════════════════════════════════════
// 4. INVENTORY ITEM
//    Collection: inventory
//    One document per product — updated when stitch job completes
//    qty map is incremented, never overwritten
// ════════════════════════════════════════════════════════════
class InventoryItem {
  final String id;
  final String productId;
  final String productName; // Denormalised
  final String productSku; // Denormalised

  // Current ready-stock per size, e.g. { "M": 120, "L": 95, "XL": 60 }
  final Map<String, int> qtBySize;

  final int? minStockAlert; // Pulled from Product — total alert threshold
  final DateTime lastUpdated;

  InventoryItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.qtBySize,
    this.minStockAlert,
    required this.lastUpdated,
  });

  int get totalQty => qtBySize.values.fold(0, (a, b) => a + b);

  bool get isLowStock => minStockAlert != null && totalQty < minStockAlert!;

  factory InventoryItem.fromMap(Map<String, dynamic> map, String id) {
    final raw = map['qtBySize'] as Map<String, dynamic>? ?? {};
    final qty = raw.map((k, v) => MapEntry(k, (v as num).toInt()));

    return InventoryItem(
      id: id,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productSku: map['productSku'] ?? '',
      qtBySize: qty,
      minStockAlert: map['minStockAlert'] != null
          ? (map['minStockAlert'] as num).toInt()
          : null,
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': productName,
    'productSku': productSku,
    'qtBySize': qtBySize,
    if (minStockAlert != null) 'minStockAlert': minStockAlert,
    'lastUpdated': FieldValue.serverTimestamp(),
  };
}
