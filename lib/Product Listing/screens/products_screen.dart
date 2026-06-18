// ============================================================
// screens/products_screen.dart
// Product listing with DataTable, search, and filter
// ============================================================

import 'package:ecom_manager/utils/constants.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

import 'product_form_screen.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _productService = ProductService();
  final _searchController = TextEditingController();

  // Filter options: 'all', 'active', 'inactive'
  String _filter = 'all';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter + search the products list
  List<Product> _applyFilters(List<Product> products) {
    return products.where((p) {
      // Status filter
      if (_filter == 'active' && !p.isActive) return false;
      if (_filter == 'inactive' && p.isActive) return false;

      // Search by SKU or Product Name (case-insensitive)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = p.productName.toLowerCase().contains(q);
        final skuMatch = p.sku.toLowerCase().contains(q);
        return nameMatch || skuMatch;
      }

      return true;
    }).toList();
  }

  // Confirm and delete a product
  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Product',
      message:
          'Are you sure you want to delete "${product.productName}"?\nThis action cannot be undone.',
    );

    if (!confirmed) return;

    final error = await _productService.deleteProduct(product);
    if (mounted) {
      if (error == null) {
        showSnackBar(context, 'Product deleted successfully');
      } else {
        showSnackBar(context, error, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Products',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductFormScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Product',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Search + Filter Row ──
          Row(
            children: [
              // Search box
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by SKU or Product Name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 16),

              // Filter buttons
              _buildFilterButton('All', 'all'),
              const SizedBox(width: 8),
              _buildFilterButton('Active', 'active'),
              const SizedBox(width: 8),
              _buildFilterButton('Inactive', 'inactive'),
            ],
          ),
          const SizedBox(height: 20),

          // ── Product Table (real-time stream) ──
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productService.getProductsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: kErrorColor),
                    ),
                  );
                }

                final allProducts = snapshot.data ?? [];
                final products = _applyFilters(allProducts);

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          allProducts.isEmpty
                              ? 'No products yet. Click "Add Product" to get started.'
                              : 'No products match your search/filter.',
                          style: const TextStyle(color: kTextSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return _buildProductTable(products);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Toggle filter button UI
  Widget _buildFilterButton(String label, String value) {
    final isSelected = _filter == value;
    return OutlinedButton(
      onPressed: () => setState(() => _filter = value),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? kPrimaryColor : Colors.white,
        side: BorderSide(color: isSelected ? kPrimaryColor : Colors.grey),
      ),
      child: Text(
        label,
        style: TextStyle(color: isSelected ? Colors.white : kTextSecondary),
      ),
    );
  }

  // DataTable showing product rows
  Widget _buildProductTable(List<Product> products) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20,
            headingRowColor: WidgetStateProperty.all(kBgColor),
            columns: const [
              DataColumn(
                label: Text(
                  'Image',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'SKU',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Product Name',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Type',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Sizes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: products.map((product) => _buildProductRow(product)).toList(),
          ),
        ),
      ),
    );
  }

  // Single row in the DataTable
  DataRow _buildProductRow(Product product) {
    return DataRow(
      cells: [
        // Product Image thumbnail
        DataCell(
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.grey.shade100,
            ),
            clipBehavior: Clip.antiAlias,
            child: product.imageUrl.isNotEmpty
                ? Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, color: Colors.grey),
                  )
                : const Icon(Icons.image, color: Colors.grey),
          ),
        ),

        // SKU
        DataCell(
          Text(
            product.sku,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Product Name
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(product.productName, overflow: TextOverflow.ellipsis),
          ),
        ),

        // Type
        DataCell(Text(product.productType)),

        // Sizes
        DataCell(
          Text(
            product.sizes.join(', '),
            style: const TextStyle(color: kTextSecondary, fontSize: 13),
          ),
        ),

        // Status badge
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: product.isActive
                  ? kSuccessColor.withOpacity(0.1)
                  : kWarningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              product.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: product.isActive ? kSuccessColor : kWarningColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // Action buttons
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // View button
              IconButton(
                icon: const Icon(Icons.visibility, color: kAccentColor),
                tooltip: 'View',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product),
                    ),
                  );
                },
              ),

              // Edit button
              IconButton(
                icon: const Icon(Icons.edit, color: kPrimaryColor),
                tooltip: 'Edit',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductFormScreen(product: product),
                    ),
                  );
                },
              ),

              // Delete button
              IconButton(
                icon: const Icon(Icons.delete, color: kErrorColor),
                tooltip: 'Delete',
                onPressed: () => _deleteProduct(product),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
