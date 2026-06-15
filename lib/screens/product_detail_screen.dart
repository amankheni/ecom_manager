// ============================================================
// screens/product_detail_screen.dart
// View-only page showing all product details
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../utils/constants.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left: Product Image ──
            _buildImageSection(),
            const SizedBox(width: 32),

            // ── Right: Product Details ──
            Expanded(child: _buildDetailsSection()),
          ],
        ),
      ),
    );
  }

  // Product image card
  Widget _buildImageSection() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: product.imageUrl.isNotEmpty
                ? Image.network(
                    product.imageUrl,
                    width: 300,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _NoImagePlaceholder(),
                  )
                : const _NoImagePlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: product.isActive
                        ? kSuccessColor.withOpacity(0.1)
                        : kWarningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    product.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: product.isActive ? kSuccessColor : kWarningColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // All detail fields
  Widget _buildDetailsSection() {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product name & type badge
        Row(
          children: [
            Expanded(
              child: Text(
                product.productName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                product.productType,
                style: const TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // SKU
        Text(
          'SKU: ${product.sku}',
          style: const TextStyle(
            fontSize: 16,
            color: kTextSecondary,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 24),

        // Description
        if (product.description.isNotEmpty) ...[
          _buildSection('Description', product.description),
          const SizedBox(height: 20),
        ],

        // Sizes
        _buildSizesSection(),
        const SizedBox(height: 20),

        // Platform Prices
        if (product.platformPrices.isNotEmpty) ...[
          _buildPlatformPricesSection(),
          const SizedBox(height: 20),
        ],

        // Timestamps
        _buildInfoRow('Created', dateFormat.format(product.createdAt)),
        const SizedBox(height: 8),
        _buildInfoRow('Last Updated', dateFormat.format(product.updatedAt)),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(color: kTextSecondary, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildSizesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Sizes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: product.sizes.map((size) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: kPrimaryColor),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                size,
                style: const TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlatformPricesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Platform Prices',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        ...product.platformPrices.entries.map((platformEntry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platformEntry.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: platformEntry.value.entries.map((sizeEntry) {
                    return Text(
                      '${sizeEntry.key}: ₹${sizeEntry.value.toStringAsFixed(0)}',
                      style: const TextStyle(color: kTextSecondary),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: kTextPrimary,
          ),
        ),
        Text(value, style: const TextStyle(color: kTextSecondary)),
      ],
    );
  }
}

// Shown when product has no image or image fails to load
class _NoImagePlaceholder extends StatelessWidget {
  const _NoImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      color: Colors.grey.shade100,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('No Image', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
