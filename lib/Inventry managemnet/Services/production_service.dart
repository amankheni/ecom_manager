// ============================================================
// services/production_service.dart
// All Firestore operations for Production & Inventory module
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom_manager/Inventry%20managemnet/Data/fabric_purchase.dart';
import 'package:ecom_manager/Inventry%20managemnet/Data/printing_entry.dart';
import 'package:ecom_manager/Inventry%20managemnet/Data/production_entry.dart';
import 'package:ecom_manager/Inventry%20managemnet/Data/ready_stock.dart';


class ProductionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── FABRIC PURCHASE ──────────────────────────────────────

  // Add a new gray fabric purchase
  Future<String?> addFabricPurchase(FabricPurchase purchase) async {
    try {
      await _db.collection('fabric_purchase').add(purchase.toMap());
      return null; // null = success
    } catch (e) {
      return 'Failed to save purchase: $e';
    }
  }

  // Real-time stream of all purchases, newest first
  Stream<List<FabricPurchase>> getFabricPurchasesStream() {
    return _db
        .collection('fabric_purchase')
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => FabricPurchase.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  // Get total purchased meters (sum of all purchases)
  Future<double> getTotalPurchasedMeter() async {
    final snap = await _db.collection('fabric_purchase').get();
    return snap.docs.fold<double>(
      0,
      (sum, d) => sum + ((d.data()['meter'] as num?)?.toDouble() ?? 0),
    );
  }

  // ── PRINTING ─────────────────────────────────────────────

  // Get total meters already printed (all entries)
  Future<double> getTotalPrintedMeter() async {
    final snap = await _db.collection('printing').get();
    return snap.docs.fold<double>(
      0,
      (sum, d) => sum + ((d.data()['meterUsed'] as num?)?.toDouble() ?? 0),
    );
  }

  // Get available raw fabric = purchased - printed
  Future<double> getAvailableRawMeter() async {
    final purchased = await getTotalPurchasedMeter();
    final printed = await getTotalPrintedMeter();
    return purchased - printed;
  }

  // Add printing entry with stock validation
  // Returns null on success, error string on failure
  Future<String?> addPrintingEntry(PrintingEntry entry) async {
    try {
      // Check available raw stock before saving
      final available = await getAvailableRawMeter();
      if (entry.meterUsed > available) {
        return 'Not enough raw fabric stock!\n'
            'Available: ${available.toStringAsFixed(1)} m\n'
            'Requested: ${entry.meterUsed.toStringAsFixed(1)} m';
      }
      await _db.collection('printing').add(entry.toMap());
      return null;
    } catch (e) {
      return 'Failed to save printing entry: $e';
    }
  }

  // Real-time stream of printing entries
  Stream<List<PrintingEntry>> getPrintingStream() {
    return _db
        .collection('printing')
        .orderBy('printingDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => PrintingEntry.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  // Get printing entries for a specific product
  Future<List<PrintingEntry>> getPrintingForProduct(String productId) async {
    final snap = await _db
        .collection('printing')
        .where('productId', isEqualTo: productId)
        .orderBy('printingDate', descending: true)
        .get();
    return snap.docs.map((d) => PrintingEntry.fromMap(d.data(), d.id)).toList();
  }

  // Get total printed meters per SKU (for printed stock display)
  // Returns { "SKU001": 120.0, "SKU002": 80.0 }
  Future<Map<String, double>> getPrintedMeterPerSku() async {
    final snap = await _db.collection('printing').get();
    final Map<String, double> result = {};
    for (final doc in snap.docs) {
      final sku = doc.data()['sku'] as String? ?? '';
      final meter = (doc.data()['meterUsed'] as num?)?.toDouble() ?? 0;
      result[sku] = (result[sku] ?? 0) + meter;
    }
    return result;
  }

  // ── PRODUCTION (STITCHING) ───────────────────────────────

  // Add production entry + update ready_stock (using transaction)
  Future<String?> addProductionEntry(ProductionEntry entry) async {
    try {
      final stockRef = _db.collection('ready_stock').doc(entry.productId);

      await _db.runTransaction((tx) async {
        final stockSnap = await tx.get(stockRef);

        // New production doc
        final prodRef = _db.collection('production').doc();
        tx.set(prodRef, entry.toMap());

        if (stockSnap.exists) {
          // Increment existing stock
          final data = stockSnap.data()!;
          tx.update(stockRef, {
            'M': (data['M'] as num? ?? 0) + entry.qtyM,
            'L': (data['L'] as num? ?? 0) + entry.qtyL,
            'XL': (data['XL'] as num? ?? 0) + entry.qtyXL,
            'XXL': (data['XXL'] as num? ?? 0) + entry.qtyXXL,
            'total': (data['total'] as num? ?? 0) + entry.totalPieces,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Create new stock document
          tx.set(stockRef, {
            'productId': entry.productId,
            'productName': entry.productName,
            'sku': entry.sku,
            'imageUrl': '', // Updated below outside transaction
            'M': entry.qtyM,
            'L': entry.qtyL,
            'XL': entry.qtyXL,
            'XXL': entry.qtyXXL,
            'total': entry.totalPieces,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      return null;
    } catch (e) {
      return 'Failed to save production entry: $e';
    }
  }

  // Real-time stream of production entries
  Stream<List<ProductionEntry>> getProductionStream() {
    return _db
        .collection('production')
        .orderBy('productionDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ProductionEntry.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  // Get production entries for a specific product
  Future<List<ProductionEntry>> getProductionForProduct(
    String productId,
  ) async {
    final snap = await _db
        .collection('production')
        .where('productId', isEqualTo: productId)
        .orderBy('productionDate', descending: true)
        .get();
    return snap.docs
        .map((d) => ProductionEntry.fromMap(d.data(), d.id))
        .toList();
  }

  // ── READY STOCK ──────────────────────────────────────────

  // Real-time stream of all ready stock
  Stream<List<ReadyStock>> getReadyStockStream() {
    return _db
        .collection('ready_stock')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ReadyStock.fromMap(d.data(), d.id)).toList(),
        );
  }

  // Get ready stock for one product
  Future<ReadyStock?> getReadyStockForProduct(String productId) async {
    try {
      final doc = await _db.collection('ready_stock').doc(productId).get();
      if (doc.exists) return ReadyStock.fromMap(doc.data()!, doc.id);
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update imageUrl on ready_stock (called after product image is available)
  Future<void> syncReadyStockImage(String productId, String imageUrl) async {
    try {
      final doc = await _db.collection('ready_stock').doc(productId).get();
      if (doc.exists && (doc.data()!['imageUrl'] ?? '').isEmpty) {
        await _db.collection('ready_stock').doc(productId).update({
          'imageUrl': imageUrl,
        });
      }
    } catch (_) {}
  }

  // ── INVENTORY DASHBOARD STATS ────────────────────────────

  // Returns all numbers needed for the inventory dashboard
  Future<Map<String, dynamic>> getInventoryStats() async {
    try {
      final purchased = await getTotalPurchasedMeter();
      final printed = await getTotalPrintedMeter();
      final available = purchased - printed;

      // Total ready pieces
      final stockSnap = await _db.collection('ready_stock').get();
      final totalReady = stockSnap.docs.fold<int>(
        0,
        (sum, d) => sum + ((d.data()['total'] as num?)?.toInt() ?? 0),
      );

      // Today's production
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todaySnap = await _db
          .collection('production')
          .where(
            'productionDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
          )
          .get();
      final todayPieces = todaySnap.docs.fold<int>(
        0,
        (sum, d) => sum + ((d.data()['totalPieces'] as num?)?.toInt() ?? 0),
      );

      return {
        'rawFabric': available, // available raw meters
        'printedFabric': printed, // total printed meters
        'readyPieces': totalReady,
        'todayProduction': todayPieces,
      };
    } catch (e) {
      return {
        'rawFabric': 0.0,
        'printedFabric': 0.0,
        'readyPieces': 0,
        'todayProduction': 0,
      };
    }
  }
}
