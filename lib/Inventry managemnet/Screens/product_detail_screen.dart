// ============================================================
// screens/product_detail_screen.dart
// View-only page showing all product details
// Now includes a "Production History" tab with printing,
// production entries, and ready stock for that SKU
// ============================================================

import 'package:ecom_manager/Inventry%20managemnet/Data/printing_entry.dart';
import 'package:ecom_manager/Inventry%20managemnet/Data/production_entry.dart';
import 'package:ecom_manager/Inventry%20managemnet/Data/ready_stock.dart';
import 'package:ecom_manager/models/product.dart';
import 'package:ecom_manager/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/production_service.dart';


class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(product.productName),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Product Details'),
              Tab(text: 'Production History'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            // ── Tab 1: Product Details ──
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSection(),
                  const SizedBox(width: 32),
                  Expanded(child: _buildDetailsSection()),
                ],
              ),
            ),

            // ── Tab 2: Production History ──
            _ProductionHistoryTab(product: product),
          ],
        ),
      ),
    );
  }

  // ── Product Image Card ──────────────────────────────────
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          ),
        ],
      ),
    );
  }

  // ── Product Detail Fields ───────────────────────────────
  Widget _buildDetailsSection() {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Text(
          'SKU: ${product.sku}',
          style: const TextStyle(
            fontSize: 16,
            color: kTextSecondary,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 24),

        if (product.description.isNotEmpty) ...[
          _buildSection('Description', product.description),
          const SizedBox(height: 20),
        ],

        _buildSizesSection(),
        const SizedBox(height: 20),

        if (product.platformPrices.isNotEmpty) ...[
          _buildPlatformPricesSection(),
          const SizedBox(height: 20),
        ],

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

// ── Production History Tab ──────────────────────────────────
class _ProductionHistoryTab extends StatelessWidget {
  final Product product;
  final _service = ProductionService();

  _ProductionHistoryTab({required this.product});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: FutureBuilder(
        future: Future.wait([
          _service.getPrintingForProduct(product.productId),
          _service.getProductionForProduct(product.productId),
          _service.getReadyStockForProduct(product.productId),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final printingEntries =
              (snapshot.data?[0] as List<PrintingEntry>?) ?? [];
          final productionEntries =
              (snapshot.data?[1] as List<ProductionEntry>?) ?? [];
          final readyStock = snapshot.data?[2] as ReadyStock?;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Ready Stock Summary ──
              const Text(
                'Current Ready Stock',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (readyStock == null)
                const Text(
                  'No ready stock yet.',
                  style: TextStyle(color: kTextSecondary),
                )
              else
                _ReadyStockSummaryCard(stock: readyStock),

              const SizedBox(height: 28),

              // ── Printing Entries ──
              const Text(
                'Printing Entries',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (printingEntries.isEmpty)
                const Text(
                  'No printing entries for this product.',
                  style: TextStyle(color: kTextSecondary),
                )
              else
                Card(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(kBgColor),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Date',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Meter Used',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Remarks',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: printingEntries.map((e) {
                      return DataRow(
                        cells: [
                          DataCell(Text(fmt.format(e.printingDate))),
                          DataCell(
                            Text(
                              '${e.meterUsed.toStringAsFixed(1)} m',
                              style: const TextStyle(
                                color: kAccentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(e.remarks.isNotEmpty ? e.remarks : '-'),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 28),

              // ── Production Entries ──
              const Text(
                'Production Entries',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (productionEntries.isEmpty)
                const Text(
                  'No production entries for this product.',
                  style: TextStyle(color: kTextSecondary),
                )
              else
                Card(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(kBgColor),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Date',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'M',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'L',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'XL',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'XXL',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Remarks',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: productionEntries.map((e) {
                      return DataRow(
                        cells: [
                          DataCell(Text(fmt.format(e.productionDate))),
                          DataCell(Text('${e.qtyM}')),
                          DataCell(Text('${e.qtyL}')),
                          DataCell(Text('${e.qtyXL}')),
                          DataCell(Text('${e.qtyXXL}')),
                          DataCell(
                            Text(
                              '${e.totalPieces}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(e.remarks.isNotEmpty ? e.remarks : '-'),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// Ready stock summary card inside the Production History tab
class _ReadyStockSummaryCard extends StatelessWidget {
  final ReadyStock stock;

  const _ReadyStockSummaryCard({required this.stock});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSuccessColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kSuccessColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _sizeBox('M', stock.qtyM),
          _sizeBox('L', stock.qtyL),
          _sizeBox('XL', stock.qtyXL),
          _sizeBox('XXL', stock.qtyXXL),
          const SizedBox(width: 16),
          const VerticalDivider(width: 1),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total',
                style: TextStyle(color: kTextSecondary, fontSize: 12),
              ),
              Text(
                '${stock.total}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kSuccessColor,
                ),
              ),
              const Text(
                'pieces',
                style: TextStyle(color: kTextSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sizeBox(String size, int qty) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Text(
            size,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$qty',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── No Image Placeholder ────────────────────────────────────
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
