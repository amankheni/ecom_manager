// ============================================================
// services/production_service.dart
// Firestore operations for:
//   ClothPurchase, PrintJob, StitchJob, Inventory
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom_manager/Inventory%20Managment/Model/production.dart';

class ProductionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── COLLECTION REFS ──────────────────────────────────────
  CollectionReference get _purchases => _db.collection('cloth_purchases');
  CollectionReference get _printJobs => _db.collection('print_jobs');
  CollectionReference get _stitchJobs => _db.collection('stitch_jobs');
  CollectionReference get _inventory => _db.collection('inventory');

  // ════════════════════════════════════════════════════════
  // CLOTH PURCHASE
  // ════════════════════════════════════════════════════════

  Future<String?> addClothPurchase(ClothPurchase purchase) async {
    try {
      await _purchases.add(purchase.toMap());
      return null; // null = success
    } catch (e) {
      return 'Failed to add purchase: $e';
    }
  }

  Stream<List<ClothPurchase>> getPurchasesStream() {
    return _purchases
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => ClothPurchase.fromMap(
                  d.data() as Map<String, dynamic>,
                  d.id,
                ),
              )
              .toList(),
        );
  }

  Future<List<ClothPurchase>> getPurchasesWithStock() async {
    // Returns purchases that still have remaining meters > 0
    final snap = await _purchases
        .orderBy('purchaseDate', descending: true)
        .get();
    return snap.docs
        .map(
          (d) => ClothPurchase.fromMap(d.data() as Map<String, dynamic>, d.id),
        )
        .where((p) => p.remainingMeters > 0)
        .toList();
  }

  // ════════════════════════════════════════════════════════
  // PRINT JOB
  // ════════════════════════════════════════════════════════

  /// Adds a print job and decrements remaining meters on the purchase.
  /// Both writes happen in a Firestore transaction for consistency.
  Future<String?> addPrintJob(PrintJob job) async {
    try {
      await _db.runTransaction((txn) async {
        // 1. Fetch the purchase to check remaining meters
        final purchaseRef = _purchases.doc(job.purchaseId);
        final purchaseSnap = await txn.get(purchaseRef);
        if (!purchaseSnap.exists) throw Exception('Purchase not found');

        final purchase = ClothPurchase.fromMap(
          purchaseSnap.data() as Map<String, dynamic>,
          purchaseSnap.id,
        );

        if (purchase.remainingMeters < job.metersUsed) {
          throw Exception(
            'Not enough remaining meters. Available: ${purchase.remainingMeters.toStringAsFixed(1)}m',
          );
        }

        // 2. Create the print job
        final jobRef = _printJobs.doc();
        txn.set(jobRef, job.toMap());

        // 3. Decrement remaining meters
        txn.update(purchaseRef, {
          'remainingMeters': FieldValue.increment(-job.metersUsed),
        });
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updatePrintJobStatus(String jobId, JobStatus status) async {
    try {
      final update = <String, dynamic>{'status': status.value};
      if (status == JobStatus.inProgress) {
        update['startedAt'] = FieldValue.serverTimestamp();
      } else if (status == JobStatus.completed) {
        update['completedAt'] = FieldValue.serverTimestamp();
      }
      await _printJobs.doc(jobId).update(update);
      return null;
    } catch (e) {
      return 'Failed to update status: $e';
    }
  }

  Stream<List<PrintJob>> getPrintJobsStream() {
    return _printJobs
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => PrintJob.fromMap(d.data() as Map<String, dynamic>, d.id),
              )
              .toList(),
        );
  }

  /// Returns print jobs that are completed but not yet stitched
  Future<List<PrintJob>> getAvailableForStitching() async {
    try {
      // NOTE: No orderBy here — avoids Firestore composite index requirement.
      // Sorting is done client-side below.
      final printSnap = await _printJobs
          .where('status', isEqualTo: 'completed')
          .get();

      final printJobs = printSnap.docs
          .map((d) => PrintJob.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();

      // Client-side sort by completedAt descending
      printJobs.sort((a, b) {
        final aDate = a.completedAt ?? DateTime(2000);
        final bDate = b.completedAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      // Filter out jobs that already have a stitch job
      final stitchSnap = await _stitchJobs.get();
      final usedPrintIds = stitchSnap.docs
          .map(
            (d) => (d.data() as Map<String, dynamic>)['printJobId'] as String,
          )
          .toSet();

      return printJobs.where((j) => !usedPrintIds.contains(j.id)).toList();
    } catch (e) {
      return [];
    }
  }

  // ════════════════════════════════════════════════════════
  // STITCH JOB
  // ════════════════════════════════════════════════════════

  Future<String?> addStitchJob(StitchJob job) async {
    try {
      await _stitchJobs.add(job.toMap());
      return null;
    } catch (e) {
      return 'Failed to add stitch job: $e';
    }
  }

  Future<String?> updateStitchJobStatus(String jobId, JobStatus status) async {
    try {
      final update = <String, dynamic>{'status': status.value};
      if (status == JobStatus.inProgress) {
        update['startedAt'] = FieldValue.serverTimestamp();
      } else if (status == JobStatus.completed) {
        update['completedAt'] = FieldValue.serverTimestamp();
      }
      await _stitchJobs.doc(jobId).update(update);
      return null;
    } catch (e) {
      return 'Failed to update status: $e';
    }
  }

  Stream<List<StitchJob>> getStitchJobsStream() {
    return _stitchJobs
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) =>
                    StitchJob.fromMap(d.data() as Map<String, dynamic>, d.id),
              )
              .toList(),
        );
  }

  // ════════════════════════════════════════════════════════
  // INVENTORY
  // When a stitch job is marked complete, call this to add
  // finished pieces to ready stock.
  // ════════════════════════════════════════════════════════

  /// Merges stitched pieces into inventory.
  /// If inventory doc for product exists: increment each size qty.
  /// If it doesn't exist: create it.
  Future<String?> addToInventory({
    required String productId,
    required String productName,
    required String productSku,
    required Map<String, int> piecesBySize,
    int? minStockAlert,
  }) async {
    try {
      // Use productId as the inventory document ID (one doc per product)
      final inventoryRef = _inventory.doc(productId);
      final snap = await inventoryRef.get();

      if (snap.exists) {
        // Increment existing quantities
        final incrementMap = piecesBySize.map(
          (size, qty) => MapEntry('qtBySize.$size', FieldValue.increment(qty)),
        );
        await inventoryRef.update({
          ...incrementMap,
          'lastUpdated': FieldValue.serverTimestamp(),
          if (minStockAlert != null) 'minStockAlert': minStockAlert,
        });
      } else {
        // Create new inventory entry
        await inventoryRef.set({
          'productId': productId,
          'productName': productName,
          'productSku': productSku,
          'qtBySize': piecesBySize,
          if (minStockAlert != null) 'minStockAlert': minStockAlert,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      return null;
    } catch (e) {
      return 'Failed to update inventory: $e';
    }
  }

  Stream<List<InventoryItem>> getInventoryStream() {
    return _inventory.snapshots().map(
      (snap) => snap.docs
          .map(
            (d) =>
                InventoryItem.fromMap(d.data() as Map<String, dynamic>, d.id),
          )
          .toList(),
    );
  }

  /// Returns only items below their minStockAlert threshold
  Stream<List<InventoryItem>> getLowStockStream() {
    return getInventoryStream().map(
      (items) => items.where((i) => i.isLowStock).toList(),
    );
  }

  // ════════════════════════════════════════════════════════
  // DASHBOARD STATS for production
  // ════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getProductionStats() async {
    try {
      final purchases = await _purchases.get();
      final printJobs = await _printJobs.get();
      final stitchJobs = await _stitchJobs.get();
      final inventory = await _inventory.get();

      int pendingPrint = printJobs.docs
          .where((d) => (d.data() as Map)['status'] == 'pending')
          .length;
      int inProgressPrint = printJobs.docs
          .where((d) => (d.data() as Map)['status'] == 'in_progress')
          .length;

      int pendingStitch = stitchJobs.docs
          .where((d) => (d.data() as Map)['status'] == 'pending')
          .length;
      int inProgressStitch = stitchJobs.docs
          .where((d) => (d.data() as Map)['status'] == 'in_progress')
          .length;

      int lowStockCount = inventory.docs.where((d) {
        final data = d.data() as Map<String, dynamic>;
        final inv = InventoryItem.fromMap(data, d.id);
        return inv.isLowStock;
      }).length;

      return {
        'totalPurchases': purchases.docs.length,
        'pendingPrintJobs': pendingPrint,
        'inProgressPrintJobs': inProgressPrint,
        'pendingStitchJobs': pendingStitch,
        'inProgressStitchJobs': inProgressStitch,
        'lowStockAlerts': lowStockCount,
      };
    } catch (e) {
      return {};
    }
  }
}
