// ============================================================
// models/product.dart
// Represents a product stored in Firestore 'products' collection
// ============================================================

class Product {
  final String productId;
  final String productName;
  final String sku;
  final String productType;
  final String description;
  final String imageUrl;
  final List<String> sizes;

  // Platform prices structure:
  // {
  //   "Flipkart": { "M": 299.0, "L": 299.0 },
  //   "Meesho": { "M": 199.0 }
  // }
  final Map<String, Map<String, double>> platformPrices;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── NEW: Production fields ────────────────────────────────
  // Average cloth consumption in meters per piece (required)
  final double? avgConsumption;

  // Size-wise cloth consumption in meters, e.g. { "M": 0.90, "L": 0.95 }
  // Optional — null if not specified
  final Map<String, double>? sizeConsumption;

  // Minimum ready stock alert threshold in pieces (optional)
  final int? minStockAlert;

  Product({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.productType,
    this.description = '',
    required this.imageUrl,
    required this.sizes,
    this.platformPrices = const {},
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    // ── NEW ──
    this.avgConsumption,
    this.sizeConsumption,
    this.minStockAlert,
  });

  // Convert Firestore document → Product object
  factory Product.fromMap(Map<String, dynamic> map, String id) {
    // Parse platformPrices from Firestore (nested map)
    Map<String, Map<String, double>> parsedPrices = {};
    if (map['platformPrices'] != null) {
      final pricesMap = map['platformPrices'] as Map<String, dynamic>;
      pricesMap.forEach((platform, sizeMap) {
        if (sizeMap is Map) {
          parsedPrices[platform] = {};
          sizeMap.forEach((size, price) {
            parsedPrices[platform]![size] = (price as num).toDouble();
          });
        }
      });
    }

    // ── NEW: Parse sizeConsumption ──
    Map<String, double>? parsedSizeConsumption;
    if (map['sizeConsumption'] != null) {
      final rawMap = map['sizeConsumption'] as Map<String, dynamic>;
      parsedSizeConsumption = {};
      rawMap.forEach((size, value) {
        parsedSizeConsumption![size] = (value as num).toDouble();
      });
    }

    return Product(
      productId: id,
      productName: map['productName'] ?? '',
      sku: map['sku'] ?? '',
      productType: map['productType'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      sizes: List<String>.from(map['sizes'] ?? []),
      platformPrices: parsedPrices,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : DateTime.now(),
      // ── NEW ──
      avgConsumption: map['avgConsumption'] != null
          ? (map['avgConsumption'] as num).toDouble()
          : null,
      sizeConsumption: parsedSizeConsumption,
      minStockAlert: map['minStockAlert'] != null
          ? (map['minStockAlert'] as num).toInt()
          : null,
    );
  }

  // Convert Product object → Firestore document
  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'productName': productName,
      'sku': sku,
      'productType': productType,
      'description': description,
      'imageUrl': imageUrl,
      'sizes': sizes,
      'platformPrices': platformPrices,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };

    // ── NEW: Only write production fields if they have values ──
    if (avgConsumption != null) {
      data['avgConsumption'] = avgConsumption;
    }
    if (sizeConsumption != null && sizeConsumption!.isNotEmpty) {
      data['sizeConsumption'] = sizeConsumption;
    }
    if (minStockAlert != null) {
      data['minStockAlert'] = minStockAlert;
    }

    return data;
  }

  // Create a copy with some fields changed (useful for editing)
  Product copyWith({
    String? productId,
    String? productName,
    String? sku,
    String? productType,
    String? description,
    String? imageUrl,
    List<String>? sizes,
    Map<String, Map<String, double>>? platformPrices,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    // ── NEW ──
    double? avgConsumption,
    Map<String, double>? sizeConsumption,
    int? minStockAlert,
  }) {
    return Product(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      productType: productType ?? this.productType,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      sizes: sizes ?? this.sizes,
      platformPrices: platformPrices ?? this.platformPrices,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // ── NEW ──
      avgConsumption: avgConsumption ?? this.avgConsumption,
      sizeConsumption: sizeConsumption ?? this.sizeConsumption,
      minStockAlert: minStockAlert ?? this.minStockAlert,
    );
  }
}

// All available product types — add more here as needed
const List<String> kProductTypes = [
  'Shirt',
  'Crop Top',
  'Kurti',
  'Tshirt',
  'Dress',
  'Top',
  'Jeans',
  'Other',
];

// All available platforms for pricing
const List<String> kPlatforms = [
  'Flipkart',
  'Meesho',
  'Snapdeal',
  'Ajio',
  'Myntra',
];

// Default sizes shown when adding a new product
const List<String> kDefaultSizes = ['M', 'L', 'XL', 'XXL'];
