// ============================================================
// screens/printing_screen.dart
// Digital Printing entries — select product, enter meters used
// Shows printed stock per SKU below the form
// ============================================================

import 'package:ecom_manager/Inventry%20managemnet/Data/printing_entry.dart';
import 'package:ecom_manager/models/product.dart';
import 'package:ecom_manager/services/product_service.dart';
import 'package:ecom_manager/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/production_service.dart';


class PrintingScreen extends StatefulWidget {
  const PrintingScreen({super.key});

  @override
  State<PrintingScreen> createState() => _PrintingScreenState();
}

class _PrintingScreenState extends State<PrintingScreen> {
  final _productService = ProductService();
  final _productionService = ProductionService();

  // ── ADD PRINTING DIALOG ──────────────────────────────────

  void _showAddDialog(List<Product> products) {
    final formKey = GlobalKey<FormState>();
    final meterCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    Product? selectedProduct;
    DateTime selectedDate = DateTime.now();
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Add Printing Entry'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product dropdown with image
                    DropdownButtonFormField<Product>(
                      value: selectedProduct,
                      decoration: const InputDecoration(
                        labelText: 'Select Product *',
                      ),
                      hint: const Text('Choose product'),
                      items: products.map((p) {
                        return DropdownMenuItem<Product>(
                          value: p,
                          child: Row(
                            children: [
                              // Thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: p.imageUrl.isNotEmpty
                                    ? Image.network(
                                        p.imageUrl,
                                        width: 32,
                                        height: 32,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.image,
                                              size: 32,
                                              color: Colors.grey,
                                            ),
                                      )
                                    : const Icon(
                                        Icons.image,
                                        size: 32,
                                        color: Colors.grey,
                                      ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    p.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    p.sku,
                                    style: const TextStyle(
                                      color: kTextSecondary,
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (p) => setDlgState(() => selectedProduct = p),
                      validator: (v) =>
                          v == null ? 'Please select a product' : null,
                    ),
                    const SizedBox(height: 16),

                    // Printing Date
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_today,
                        color: kPrimaryColor,
                      ),
                      title: Text(
                        'Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDlgState(() => selectedDate = picked);
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Meter used
                    TextFormField(
                      controller: meterCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Meter Used *',
                        suffixText: 'm',
                        hintText: '0.0',
                      ),
                      validator: (v) {
                        if (v!.trim().isEmpty) return 'Required';
                        if (double.tryParse(v) == null ||
                            double.parse(v) <= 0) {
                          return 'Enter a valid positive number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Remarks
                    TextFormField(
                      controller: remarksCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Remarks (Optional)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDlgState(() => saving = true);

                      final entry = PrintingEntry(
                        printingId: '',
                        productId: selectedProduct!.productId,
                        productName: selectedProduct!.productName,
                        sku: selectedProduct!.sku,
                        imageUrl: selectedProduct!.imageUrl,
                        meterUsed: double.parse(meterCtrl.text),
                        printingDate: selectedDate,
                        remarks: remarksCtrl.text.trim(),
                        createdAt: DateTime.now(),
                      );

                      final error = await _productionService.addPrintingEntry(
                        entry,
                      );

                      if (mounted) {
                        Navigator.pop(ctx);
                        if (error == null) {
                          showSnackBar(context, 'Printing entry saved');
                        } else {
                          showSnackBar(context, error, isError: true);
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          FutureBuilder<List<Product>>(
            // Load products for the add button
            future: _productService.getProductsStream().first,
            builder: (context, productSnap) {
              final products = productSnap.data ?? [];
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Digital Printing',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: products.isEmpty
                        ? null
                        : () => _showAddDialog(products),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Add Printing Entry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Printed Stock Summary (meter per SKU) ──
          const Text(
            'Printed Stock per SKU',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<Map<String, double>>(
            future: _productionService.getPrintedMeterPerSku(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final skuMap = snap.data!;
              if (skuMap.isEmpty) {
                return const Text(
                  'No printing done yet.',
                  style: TextStyle(color: kTextSecondary),
                );
              }
              return Wrap(
                spacing: 12,
                runSpacing: 8,
                children: skuMap.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: kAccentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kAccentColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: kAccentColor,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${e.value.toStringAsFixed(1)} m',
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Printing History Table ──
          const Text(
            'Printing History',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<PrintingEntry>>(
              stream: _productionService.getPrintingStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = snapshot.data ?? [];
                if (entries.isEmpty) {
                  return const Center(
                    child: Text(
                      'No printing entries yet.',
                      style: TextStyle(color: kTextSecondary),
                    ),
                  );
                }
                return _buildTable(entries);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<PrintingEntry> entries) {
    final fmt = DateFormat('dd MMM yyyy');
    return Card(
      child: SingleChildScrollView(
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
                'Image',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text(
                'Product',
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
          rows: entries.map((e) {
            return DataRow(
              cells: [
                DataCell(Text(fmt.format(e.printingDate))),
                DataCell(
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey.shade100,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: e.imageUrl.isNotEmpty
                        ? Image.network(
                            e.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
                DataCell(
                  Text(
                    e.sku,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                DataCell(Text(e.productName)),
                DataCell(
                  Text(
                    '${e.meterUsed.toStringAsFixed(1)} m',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: kAccentColor,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    e.remarks.isNotEmpty ? e.remarks : '-',
                    style: const TextStyle(color: kTextSecondary),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
