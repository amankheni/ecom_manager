// ============================================================
// services/product_service.dart
// Handles all Firestore + Firebase Storage operations for products
// ============================================================

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // ── UPLOAD IMAGE ─────────────────────────────────────────
  // Uploads image bytes to Firebase Storage and returns the download URL
  Future<String> uploadImage(Uint8List imageBytes, String fileName) async {
    // Store all product images inside products/product_images/ folder
    final ref = _storage.ref().child(
      'products/product_images/${_uuid.v4()}_$fileName',
    );

    final uploadTask = await ref.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  // ── DELETE IMAGE FROM STORAGE ────────────────────────────
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // If image deletion fails, we still proceed (don't block product deletion)
      print('Image deletion failed: $e');
    }
  }

  // ── CHECK SKU UNIQUE ─────────────────────────────────────
  // Returns true if SKU is available, false if already taken
  Future<bool> isSkuUnique(String sku, {String? excludeProductId}) async {
    final query = await _firestore
        .collection('products')
        .where('sku', isEqualTo: sku.trim().toUpperCase())
        .get();

    if (query.docs.isEmpty) return true;

    // When editing, exclude the current product's own SKU
    if (excludeProductId != null) {
      return query.docs.every((doc) => doc.id == excludeProductId);
    }

    return false;
  }

  // ── ADD PRODUCT ──────────────────────────────────────────
  Future<String?> addProduct(Product product) async {
    try {
      // Always store SKU in uppercase for consistency
      final docRef = _firestore.collection('products').doc();
      await docRef.set({...product.toMap(), 'sku': product.sku.toUpperCase()});
      return null; // null means success
    } catch (e) {
      return 'Failed to add product: $e';
    }
  }

  // ── UPDATE PRODUCT ───────────────────────────────────────
  Future<String?> updateProduct(Product product) async {
    try {
      await _firestore.collection('products').doc(product.productId).update({
        ...product.toMap(),
        'sku': product.sku.toUpperCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null; // null means success
    } catch (e) {
      return 'Failed to update product: $e';
    }
  }

  // ── DELETE PRODUCT ───────────────────────────────────────
  Future<String?> deleteProduct(Product product) async {
    try {
      // Delete image from storage first
      if (product.imageUrl.isNotEmpty) {
        await deleteImage(product.imageUrl);
      }
      // Delete Firestore document
      await _firestore.collection('products').doc(product.productId).delete();
      return null; // null means success
    } catch (e) {
      return 'Failed to delete product: $e';
    }
  }

  // ── GET ALL PRODUCTS (real-time stream) ──────────────────
  Stream<List<Product>> getProductsStream() {
    return _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Product.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // ── GET SINGLE PRODUCT ───────────────────────────────────
  Future<Product?> getProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        return Product.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ── GET DASHBOARD STATS ──────────────────────────────────
  // Returns { total, active, inactive } product counts
  Future<Map<String, int>> getDashboardStats() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      int total = snapshot.docs.length;
      int active = snapshot.docs
          .where((doc) => doc.data()['isActive'] == true)
          .length;
      int inactive = total - active;

      return {'total': total, 'active': active, 'inactive': inactive};
    } catch (e) {
      return {'total': 0, 'active': 0, 'inactive': 0};
    }
  }
}
