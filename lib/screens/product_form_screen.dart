// ============================================================
// screens/product_form_screen.dart
// Used for both Add Product and Edit Product
// If [product] is null → Add mode, else → Edit mode
// ============================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../utils/constants.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product; // null = Add mode, non-null = Edit mode

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();

  // Form controllers
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _newSizeController = TextEditingController();

  // ── NEW: Production field controllers ──
  final _avgConsumptionController = TextEditingController();
  final _minStockAlertController = TextEditingController();

  // Size-wise consumption controllers (fixed sizes M, L, XL, XXL)
  final _consumptionM = TextEditingController();
  final _consumptionL = TextEditingController();
  final _consumptionXL = TextEditingController();
  final _consumptionXXL = TextEditingController();

  // Form state
  String? _selectedType;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isEditMode = false;

  // Sizes list (user can add/remove)
  List<String> _sizes = List.from(kDefaultSizes);

  // Platform prices: { "Flipkart": { "M": 299.0 } }
  Map<String, Map<String, TextEditingController>> _priceControllers = {};

  // Image
  Uint8List? _selectedImageBytes;
  String? _existingImageUrl; // Only used in edit mode

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.product != null;

    if (_isEditMode) {
      // Pre-fill form with existing product data
      final p = widget.product!;
      _nameController.text = p.productName;
      _skuController.text = p.sku;
      _descriptionController.text = p.description;
      _selectedType = p.productType;
      _isActive = p.isActive;
      _sizes = List.from(p.sizes);
      _existingImageUrl = p.imageUrl;

      // ── NEW: Pre-fill production fields ──
      if (p.avgConsumption != null) {
        _avgConsumptionController.text = p.avgConsumption!.toString();
      }
      if (p.minStockAlert != null) {
        _minStockAlertController.text = p.minStockAlert!.toString();
      }
      if (p.sizeConsumption != null) {
        _consumptionM.text = p.sizeConsumption!['M']?.toString() ?? '';
        _consumptionL.text = p.sizeConsumption!['L']?.toString() ?? '';
        _consumptionXL.text = p.sizeConsumption!['XL']?.toString() ?? '';
        _consumptionXXL.text = p.sizeConsumption!['XXL']?.toString() ?? '';
      }

      // Setup price controllers for each platform and size
      _initPriceControllers(p.sizes, existingPrices: p.platformPrices);
    } else {
      // Default: setup price controllers with default sizes
      _initPriceControllers(kDefaultSizes);
    }
  }

  // Create TextEditingControllers for platform × size grid
  void _initPriceControllers(
    List<String> sizes, {
    Map<String, Map<String, double>>? existingPrices,
  }) {
    _priceControllers = {};
    for (final platform in kPlatforms) {
      _priceControllers[platform] = {};
      for (final size in sizes) {
        final existing = existingPrices?[platform]?[size];
        _priceControllers[platform]![size] = TextEditingController(
          text: existing != null ? existing.toStringAsFixed(0) : '',
        );
      }
    }
  }

  // When sizes change, rebuild price controllers while preserving existing values
  void _rebuildPriceControllers() {
    final Map<String, Map<String, TextEditingController>> newControllers = {};
    for (final platform in kPlatforms) {
      newControllers[platform] = {};
      for (final size in _sizes) {
        // Preserve existing value if controller already exists
        final existing = _priceControllers[platform]?[size];
        newControllers[platform]![size] = TextEditingController(
          text: existing?.text ?? '',
        );
      }
    }
    // Dispose old controllers
    for (final platform in _priceControllers.keys) {
      for (final ctrl in _priceControllers[platform]!.values) {
        ctrl.dispose();
      }
    }
    _priceControllers = newControllers;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _newSizeController.dispose();
    // ── NEW: Dispose production controllers ──
    _avgConsumptionController.dispose();
    _minStockAlertController.dispose();
    _consumptionM.dispose();
    _consumptionL.dispose();
    _consumptionXL.dispose();
    _consumptionXXL.dispose();
    for (final platform in _priceControllers.keys) {
      for (final ctrl in _priceControllers[platform]!.values) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  // ── PICK IMAGE FROM DEVICE ───────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _selectedImageBytes = bytes);
    }
  }

  // ── ADD A NEW SIZE ───────────────────────────────────────
  void _addSize() {
    final size = _newSizeController.text.trim().toUpperCase();
    if (size.isEmpty) return;
    if (_sizes.contains(size)) {
      showSnackBar(context, 'Size "$size" already exists', isError: true);
      return;
    }
    setState(() {
      _sizes.add(size);
      _newSizeController.clear();
      _rebuildPriceControllers();
    });
  }

  // ── REMOVE A SIZE ────────────────────────────────────────
  void _removeSize(String size) {
    if (_sizes.length <= 1) {
      showSnackBar(context, 'At least one size is required', isError: true);
      return;
    }
    setState(() {
      _sizes.remove(size);
      _rebuildPriceControllers();
    });
  }

  // ── BUILD PLATFORM PRICES FROM CONTROLLERS ───────────────
  Map<String, Map<String, double>> _buildPlatformPrices() {
    final Map<String, Map<String, double>> result = {};
    for (final platform in kPlatforms) {
      final Map<String, double> sizePrices = {};
      for (final size in _sizes) {
        final text = _priceControllers[platform]?[size]?.text.trim() ?? '';
        if (text.isNotEmpty) {
          final price = double.tryParse(text);
          if (price != null && price > 0) {
            sizePrices[size] = price;
          }
        }
      }
      if (sizePrices.isNotEmpty) {
        result[platform] = sizePrices;
      }
    }
    return result;
  }

  // ── NEW: Build size-wise consumption map ─────────────────
  Map<String, double>? _buildSizeConsumption() {
    final Map<String, double> result = {};
    final entries = {
      'M': _consumptionM.text.trim(),
      'L': _consumptionL.text.trim(),
      'XL': _consumptionXL.text.trim(),
      'XXL': _consumptionXXL.text.trim(),
    };
    for (final entry in entries.entries) {
      if (entry.value.isNotEmpty) {
        final val = double.tryParse(entry.value);
        if (val != null && val > 0) {
          result[entry.key] = val;
        }
      }
    }
    return result.isEmpty ? null : result;
  }

  // ── SAVE PRODUCT ─────────────────────────────────────────
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // Image required for new products
    if (!_isEditMode && _selectedImageBytes == null) {
      showSnackBar(context, 'Please select a product image', isError: true);
      return;
    }

    // At least one size required
    if (_sizes.isEmpty) {
      showSnackBar(context, 'Please add at least one size', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check SKU uniqueness
      final skuUnique = await _productService.isSkuUnique(
        _skuController.text,
        excludeProductId: _isEditMode ? widget.product!.productId : null,
      );

      if (!skuUnique) {
        showSnackBar(
          context,
          'This SKU is already used by another product',
          isError: true,
        );
        setState(() => _isLoading = false);
        return;
      }

      // Upload new image if selected
      String imageUrl = _existingImageUrl ?? '';
      if (_selectedImageBytes != null) {
        imageUrl = await _productService.uploadImage(
          _selectedImageBytes!,
          '${_skuController.text}_image.jpg',
        );
      }

      // Build product prices
      final platformPrices = _buildPlatformPrices();

      // ── NEW: Build production fields ──
      final avgConsumption = double.tryParse(
        _avgConsumptionController.text.trim(),
      );
      final minStockAlert = int.tryParse(_minStockAlertController.text.trim());
      final sizeConsumption = _buildSizeConsumption();

      final now = DateTime.now();

      String? error;

      if (_isEditMode) {
        // Update existing product
        final updatedProduct = widget.product!.copyWith(
          productName: _nameController.text.trim(),
          sku: _skuController.text.trim(),
          productType: _selectedType!,
          description: _descriptionController.text.trim(),
          imageUrl: imageUrl,
          sizes: _sizes,
          platformPrices: platformPrices,
          isActive: _isActive,
          updatedAt: now,
          // ── NEW fields ──
          avgConsumption: avgConsumption,
          minStockAlert: minStockAlert,
          sizeConsumption: sizeConsumption,
        );
        error = await _productService.updateProduct(updatedProduct);
      } else {
        // Create new product
        final newProduct = Product(
          productId: '',
          productName: _nameController.text.trim(),
          sku: _skuController.text.trim(),
          productType: _selectedType!,
          description: _descriptionController.text.trim(),
          imageUrl: imageUrl,
          sizes: _sizes,
          platformPrices: platformPrices,
          isActive: _isActive,
          createdAt: now,
          updatedAt: now,
          // ── NEW fields ──
          avgConsumption: avgConsumption,
          minStockAlert: minStockAlert,
          sizeConsumption: sizeConsumption,
        );
        error = await _productService.addProduct(newProduct);
      }

      if (mounted) {
        if (error == null) {
          showSnackBar(
            context,
            _isEditMode
                ? 'Product updated successfully!'
                : 'Product added successfully!',
          );
          Navigator.pop(context);
        } else {
          showSnackBar(context, error, isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Product' : 'Add Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveProduct,
              icon: _isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                _isEditMode ? 'Update Product' : 'Save Product',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left Column: Image + Status ──
            Container(
              width: 280,
              margin: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildImageSection(),
                  const SizedBox(height: 16),
                  _buildStatusCard(),
                ],
              ),
            ),

            // ── Right Column: All other fields (scrollable) ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildBasicInfoCard(),
                    const SizedBox(height: 16),
                    _buildSizesCard(),
                    const SizedBox(height: 16),
                    _buildPlatformPricesCard(),
                    const SizedBox(height: 16),
                    // ── NEW: Production Info Card ──
                    _buildProductionInfoCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Image Picker Section ─────────────────────────────────
  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Image',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Required',
              style: TextStyle(color: kErrorColor, fontSize: 12),
            ),
            const SizedBox(height: 12),

            // Image preview
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: _buildImagePreview(),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload),
                label: const Text('Choose Image'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shows selected image, existing image, or upload prompt
  Widget _buildImagePreview() {
    if (_selectedImageBytes != null) {
      // New image selected by user
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
      );
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      // Existing image from Firestore (edit mode)
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          _existingImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildUploadPrompt(),
        ),
      );
    } else {
      return _buildUploadPrompt();
    }
  }

  Widget _buildUploadPrompt() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
        SizedBox(height: 8),
        Text('Click to upload image', style: TextStyle(color: Colors.grey)),
        Text(
          'JPG, PNG recommended',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  // ── Status Toggle Card ───────────────────────────────────
  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Switch(
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  activeColor: kSuccessColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: _isActive ? kSuccessColor : kWarningColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Basic Info: Name, SKU, Type, Description ─────────────
  Widget _buildBasicInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),

            // Product Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                hintText: 'e.g. Cotton Floral Kurti',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Product name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // SKU
            TextFormField(
              controller: _skuController,
              decoration: const InputDecoration(
                labelText: 'SKU *',
                hintText: 'e.g. KRT-001',
                helperText: 'SKU will be saved in UPPERCASE. Must be unique.',
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'SKU is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Product Type dropdown
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Product Type *'),
              hint: const Text('Select product type'),
              items: kProductTypes
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedType = value),
              validator: (value) {
                if (value == null) return 'Please select product type';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description (optional)
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter product description...',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sizes Card ───────────────────────────────────────────
  Widget _buildSizesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Sizes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Text(
              'At least one size is required',
              style: TextStyle(color: kTextSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Display existing sizes as chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sizes.map((size) {
                return Chip(
                  label: Text(size),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeSize(size),
                  backgroundColor: kPrimaryColor.withOpacity(0.1),
                  labelStyle: const TextStyle(color: kPrimaryColor),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Add new size
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _newSizeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Add Size',
                      hintText: 'e.g. XS, 3XL, 4XL',
                    ),
                    onFieldSubmitted: (_) => _addSize(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _addSize, child: const Text('Add')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Platform Prices Card ─────────────────────────────────
  // Each platform shows a grid of size × price input fields
  Widget _buildPlatformPricesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Platform Prices',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Text(
              'Optional — leave blank if not selling on that platform',
              style: TextStyle(color: kTextSecondary, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // One block per platform
            ...kPlatforms.map((platform) => _buildPlatformBlock(platform)),
          ],
        ),
      ),
    );
  }

  // Builds a price input grid for one platform
  Widget _buildPlatformBlock(String platform) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            platform,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: kPrimaryColor,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          // Size × Price input grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _sizes.map((size) {
              return SizedBox(
                width: 120,
                child: TextFormField(
                  controller: _priceControllers[platform]?[size],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: size,
                    prefixText: '₹ ',
                    hintText: '0',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── NEW: Production Info Card ────────────────────────────
  Widget _buildProductionInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kAccentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.straighten_rounded,
                    color: kAccentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Production Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Cloth consumption & stock alert settings',
                      style: TextStyle(color: kTextSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── 1. Average Cloth Consumption (Required) ──
            TextFormField(
              controller: _avgConsumptionController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Average Cloth Consumption (Meter per Piece) *',
                hintText: 'e.g. 0.95',
                suffixText: 'm',
                helperText: 'Average fabric needed per piece across all sizes',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Average cloth consumption is required';
                }
                final parsed = double.tryParse(value.trim());
                if (parsed == null) {
                  return 'Please enter a valid decimal number';
                }
                if (parsed <= 0) {
                  return 'Value must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── 2. Size-wise Cloth Consumption (Optional) ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kBgColor,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Size-wise Cloth Consumption',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Optional — enter if consumption differs per size',
                    style: TextStyle(color: kTextSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // 2×2 grid of size consumption fields
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildSizeConsumptionField('M', _consumptionM, '0.90'),
                      _buildSizeConsumptionField('L', _consumptionL, '0.95'),
                      _buildSizeConsumptionField('XL', _consumptionXL, '1.00'),
                      _buildSizeConsumptionField(
                        'XXL',
                        _consumptionXXL,
                        '1.05',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 3. Minimum Stock Alert (Optional) ──
            TextFormField(
              controller: _minStockAlertController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minimum Stock Alert (Pieces)',
                hintText: 'e.g. 20',
                suffixText: 'pcs',
                helperText:
                    'Optional — get alerted when ready stock falls below this',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return null; // Optional
                final parsed = int.tryParse(value.trim());
                if (parsed == null) {
                  return 'Please enter a whole number';
                }
                if (parsed < 0) {
                  return 'Value cannot be negative';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper: builds one size consumption input field
  Widget _buildSizeConsumptionField(
    String size,
    TextEditingController controller,
    String hint,
  ) {
    return SizedBox(
      width: 130,
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: '$size Consumption (m)',
          hintText: hint,
          suffixText: 'm',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return null; // Optional
          final parsed = double.tryParse(value.trim());
          if (parsed == null) {
            return 'Invalid number';
          }
          if (parsed <= 0) {
            return 'Must be > 0';
          }
          return null;
        },
      ),
    );
  }
}
