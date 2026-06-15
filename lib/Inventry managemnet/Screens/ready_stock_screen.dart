// ============================================================
// screens/ready_stock_screen.dart
// Shows current ready stock per product/SKU with search & sort
// ============================================================

import 'package:ecom_manager/Inventry%20managemnet/Data/ready_stock.dart';
import 'package:ecom_manager/utils/constants.dart';
import 'package:flutter/material.dart';

import '../services/production_service.dart';

class ReadyStockScreen extends StatefulWidget {
  const ReadyStockScreen({super.key});

  @override
  State<ReadyStockScreen> createState() => _ReadyStockScreenState();
}

class _ReadyStockScreenState extends State<ReadyStockScreen> {
  final _service = ProductionService();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'total'; // 'total', 'sku', 'name'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ReadyStock> _applyFilters(List<ReadyStock> stocks) {
    var list = stocks.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.sku.toLowerCase().contains(q) ||
          s.productName.toLowerCase().contains(q);
    }).toList();

    // Sort
    list.sort((a, b) {
      if (_sortBy == 'total') return b.total.compareTo(a.total);
      if (_sortBy == 'sku') return a.sku.compareTo(b.sku);
      return a.productName.compareTo(b.productName);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          const Text(
            'Ready Stock',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Automatically updated when production entry is added.',
            style: TextStyle(color: kTextSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // ── Search + Sort Row ──
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by SKU or Product Name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 16),
              const Text('Sort:', style: TextStyle(color: kTextSecondary)),
              const SizedBox(width: 8),
              _sortButton('Total', 'total'),
              const SizedBox(width: 6),
              _sortButton('SKU', 'sku'),
              const SizedBox(width: 6),
              _sortButton('Name', 'name'),
            ],
          ),
          const SizedBox(height: 16),

          // ── Stock Table ──
          Expanded(
            child: StreamBuilder<List<ReadyStock>>(
              stream: _service.getReadyStockStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snapshot.data ?? [];
                final stocks = _applyFilters(all);

                if (stocks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inventory,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          all.isEmpty
                              ? 'No ready stock yet. Add production entries to see stock here.'
                              : 'No results for your search.',
                          style: const TextStyle(color: kTextSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return Card(
                  child: SingleChildScrollView(
                    child: DataTable(
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
                      ],
                      rows: stocks.map((s) {
                        return DataRow(
                          cells: [
                            // Image
                            DataCell(
                              Container(
                                width: 44,
                                height: 44,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: Colors.grey.shade100,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: s.imageUrl.isNotEmpty
                                    ? Image.network(
                                        s.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                            ),
                                      )
                                    : const Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),
                            DataCell(
                              Text(
                                s.sku,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 180,
                                ),
                                child: Text(
                                  s.productName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(Text('${s.qtyM}')),
                            DataCell(Text('${s.qtyL}')),
                            DataCell(Text('${s.qtyXL}')),
                            DataCell(Text('${s.qtyXXL}')),
                            DataCell(
                              Text(
                                '${s.total}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: kSuccessColor,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortButton(String label, String value) {
    final isSelected = _sortBy == value;
    return OutlinedButton(
      onPressed: () => setState(() => _sortBy = value),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? kPrimaryColor : Colors.white,
        side: BorderSide(color: isSelected ? kPrimaryColor : Colors.grey),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : kTextSecondary,
          fontSize: 13,
        ),
      ),
    );
  }
}
