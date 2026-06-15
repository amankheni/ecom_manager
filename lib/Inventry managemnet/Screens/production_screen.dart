// ============================================================
// screens/production_screen.dart
// Stitching / Production entries — select product, enter size-wise qty
// Automatically updates ready_stock
// ============================================================

import 'package:ecom_manager/Inventry%20managemnet/Data/production_entry.dart';
import 'package:ecom_manager/models/product.dart';
import 'package:ecom_manager/services/product_service.dart';
import 'package:ecom_manager/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/production_service.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  final _productService = ProductService();
  final _productionService = ProductionService();

  // ── ADD PRODUCTION DIALOG ────────────────────────────────

  void _showAddDialog(List<Product> products) {
    final formKey = GlobalKey<FormState>();
    final mCtrl = TextEditingController();
    final lCtrl = TextEditingController();
    final xlCtrl = TextEditingController();
    final xxlCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    Product? selectedProduct;
    DateTime selectedDate = DateTime.now();
    bool saving = false;

    int _parseQty(String text) => int.tryParse(text.trim()) ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Add Production Entry'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product dropdown
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

                    // Production Date
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
                    const SizedBox(height: 12),

                    // Size-wise quantity (M, L, XL, XXL)
                    const Text(
                      'Size-Wise Quantity',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _sizeField('M', mCtrl),
                        const SizedBox(width: 10),
                        _sizeField('L', lCtrl),
                        const SizedBox(width: 10),
                        _sizeField('XL', xlCtrl),
                        const SizedBox(width: 10),
                        _sizeField('XXL', xxlCtrl),
                      ],
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

                      final qtyM = _parseQty(mCtrl.text);
                      final qtyL = _parseQty(lCtrl.text);
                      final qtyXL = _parseQty(xlCtrl.text);
                      final qtyXXL = _parseQty(xxlCtrl.text);
                      final total = qtyM + qtyL + qtyXL + qtyXXL;

                      if (total == 0) {
                        showSnackBar(
                          ctx,
                          'Enter quantity for at least one size',
                          isError: true,
                        );
                        return;
                      }

                      setDlgState(() => saving = true);

                      final entry = ProductionEntry(
                        productionId: '',
                        productId: selectedProduct!.productId,
                        productName: selectedProduct!.productName,
                        sku: selectedProduct!.sku,
                        qtyM: qtyM,
                        qtyL: qtyL,
                        qtyXL: qtyXL,
                        qtyXXL: qtyXXL,
                        totalPieces: total,
                        productionDate: selectedDate,
                        remarks: remarksCtrl.text.trim(),
                        createdAt: DateTime.now(),
                      );

                      final error = await _productionService.addProductionEntry(
                        entry,
                      );

                      // Sync image to ready_stock if needed
                      if (error == null &&
                          selectedProduct!.imageUrl.isNotEmpty) {
                        await _productionService.syncReadyStockImage(
                          selectedProduct!.productId,
                          selectedProduct!.imageUrl,
                        );
                      }

                      if (mounted) {
                        Navigator.pop(ctx);
                        if (error == null) {
                          showSnackBar(
                            context,
                            'Production entry saved successfully',
                          );
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

  // Small size qty input field
  Widget _sizeField(String label, TextEditingController ctrl) {
    return Expanded(
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          hintText: '0',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 12,
          ),
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
            future: _productService.getProductsStream().first,
            builder: (context, productSnap) {
              final products = productSnap.data ?? [];
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Production (Stitching)',
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
                      'Add Production Entry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Each entry automatically updates Ready Stock.',
            style: TextStyle(color: kTextSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // ── Production History ──
          Expanded(
            child: StreamBuilder<List<ProductionEntry>>(
              stream: _productionService.getProductionStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = snapshot.data ?? [];
                if (entries.isEmpty) {
                  return const Center(
                    child: Text(
                      'No production entries yet.',
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

  Widget _buildTable(List<ProductionEntry> entries) {
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
              label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text(
                'Product',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text('M', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('L', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('XL', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('XXL', style: TextStyle(fontWeight: FontWeight.bold)),
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
          rows: entries.map((e) {
            return DataRow(
              cells: [
                DataCell(Text(fmt.format(e.productionDate))),
                DataCell(
                  Text(
                    e.sku,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(e.productName, overflow: TextOverflow.ellipsis),
                  ),
                ),
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
