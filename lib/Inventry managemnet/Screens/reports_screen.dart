// ============================================================
// screens/reports_screen.dart
// Simple inventory report: Raw Fabric, Printed, Ready Stock
// No charts — just clean tables, easy for business owners
// ============================================================

import 'package:ecom_manager/Inventry%20managemnet/Data/ready_stock.dart';
import 'package:ecom_manager/utils/constants.dart';
import 'package:flutter/material.dart';

import '../services/production_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _service = ProductionService();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;

  double _totalPurchased = 0;
  double _totalPrinted = 0;
  double _availableRaw = 0;
  int _totalReadyPieces = 0;
  List<ReadyStock> _readyStocks = [];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final purchased = await _service.getTotalPurchasedMeter();
    final printed = await _service.getTotalPrintedMeter();
    final List<ReadyStock> stocks = await _service.getReadyStockStream().first;

    if (mounted) {
      setState(() {
        _totalPurchased = purchased;
        _totalPrinted = printed;
        _availableRaw = purchased - printed;
        _readyStocks = stocks;
     _totalReadyPieces = stocks.fold<int>(
          0,
          (sum, s) => sum + (s?.total ?? 0),
        );

        _isLoading = false;
      });
    }
  }

  List<ReadyStock> get _filteredStocks {
    if (_searchQuery.isEmpty) return _readyStocks;
    final q = _searchQuery.toLowerCase();
    return _readyStocks
        .where(
          (s) =>
              s.sku.toLowerCase().contains(q) ||
              s.productName.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reports',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              IconButton(
                onPressed: _loadReport,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            // ── Summary Section ──
            const Text(
              'Fabric Summary',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryTable(),
            const SizedBox(height: 28),

            // ── Product-wise Ready Stock ──
            const Text(
              'Product-Wise Ready Stock',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Search
            TextField(
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
            const SizedBox(height: 12),

            Expanded(child: _buildReadyStockTable()),
          ],
        ],
      ),
    );
  }

  // Top summary table (3 fabric rows + total ready pieces)
  Widget _buildSummaryTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Table(
          columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade200),
          ),
          children: [
            _summaryRow(
              'Total Gray Fabric Purchased',
              '${_totalPurchased.toStringAsFixed(1)} m',
              kPrimaryColor,
            ),
            _summaryRow(
              'Total Fabric Printed',
              '${_totalPrinted.toStringAsFixed(1)} m',
              kAccentColor,
            ),
            _summaryRow(
              'Available Raw Fabric',
              '${_availableRaw.toStringAsFixed(1)} m',
              _availableRaw < 0 ? kErrorColor : kSuccessColor,
            ),
            _summaryRow(
              'Total Ready Pieces',
              '$_totalReadyPieces pcs',
              kSuccessColor,
            ),
          ],
        ),
      ),
    );
  }

  TableRow _summaryRow(String label, String value, Color valueColor) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(
            label,
            style: const TextStyle(color: kTextPrimary, fontSize: 14),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  // Product-wise ready stock table
  Widget _buildReadyStockTable() {
    final stocks = _filteredStocks;
    if (stocks.isEmpty) {
      return const Center(
        child: Text(
          'No ready stock data.',
          style: TextStyle(color: kTextSecondary),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(kBgColor),
          columns: const [
            DataColumn(
              label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text(
                'Product Name',
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
          ],
          rows: stocks.map((s) {
            return DataRow(
              cells: [
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
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Text(s.productName, overflow: TextOverflow.ellipsis),
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
  }
}
