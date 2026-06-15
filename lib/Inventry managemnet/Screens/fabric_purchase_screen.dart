// ============================================================
// screens/fabric_purchase_screen.dart
// Gray fabric purchase — clean form dialog + table + stock summary
// Responsive layout with mobile support
// ============================================================

import 'package:ecom_manager/Inventry%20managemnet/Data/fabric_purchase.dart';
import 'package:ecom_manager/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/production_service.dart';

class FabricPurchaseScreen extends StatefulWidget {
  const FabricPurchaseScreen({super.key});

  @override
  State<FabricPurchaseScreen> createState() => _FabricPurchaseScreenState();
}

class _FabricPurchaseScreenState extends State<FabricPurchaseScreen> {
  final _service = ProductionService();

  void _showAddDialog() {
    final formKey = GlobalKey<FormState>();
    final partyCtrl = TextEditingController();
    final fabricTypeCtrl = TextEditingController();
    final colorCtrl = TextEditingController();
    final meterCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    final invoiceCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 520,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1a237e), Color(0xFF283593)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_shopping_cart,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Add Fabric Purchase',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: saving ? null : () => Navigator.pop(ctx),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Form
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Purchase Date
                          _labelText('Purchase Date'),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null)
                                setDlg(() => selectedDate = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16,
                                    color: Color(0xFF1a237e),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                    ).format(selectedDate),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Change',
                                    style: TextStyle(
                                      color: const Color(0xFF1a237e),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Party Name
                          _labelText('Party Name *'),
                          const SizedBox(height: 6),
                          _field(
                            partyCtrl,
                            'e.g. Raju Textile',
                            validator: _required,
                          ),
                          const SizedBox(height: 14),

                          // Fabric Type + Color row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _labelText('Fabric Type *'),
                                    const SizedBox(height: 6),
                                    _field(
                                      fabricTypeCtrl,
                                      'e.g. Cotton',
                                      validator: _required,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _labelText('Color *'),
                                    const SizedBox(height: 6),
                                    _field(
                                      colorCtrl,
                                      'e.g. White',
                                      validator: _required,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Meter + Rate row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _labelText('Total Meter *'),
                                    const SizedBox(height: 6),
                                    _field(
                                      meterCtrl,
                                      '0.0',
                                      suffix: 'm',
                                      keyboardType: TextInputType.number,
                                      validator: _numberValidator,
                                      onChanged: (_) => setDlg(() {}),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _labelText('Rate / Meter *'),
                                    const SizedBox(height: 6),
                                    _field(
                                      rateCtrl,
                                      '0',
                                      prefix: '₹',
                                      keyboardType: TextInputType.number,
                                      validator: _numberValidator,
                                      onChanged: (_) => setDlg(() {}),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Live total preview
                          if (meterCtrl.text.isNotEmpty &&
                              rateCtrl.text.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8EAF6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calculate_outlined,
                                    size: 16,
                                    color: Color(0xFF1a237e),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Total Amount: ₹ ${((double.tryParse(meterCtrl.text) ?? 0) * (double.tryParse(rateCtrl.text) ?? 0)).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Color(0xFF1a237e),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Invoice (optional)
                          _labelText('Invoice Number (Optional)'),
                          const SizedBox(height: 6),
                          _field(invoiceCtrl, 'e.g. INV-2024-001'),
                          const SizedBox(height: 14),

                          // Remarks (optional)
                          _labelText('Remarks (Optional)'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: remarksCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Any notes...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: saving ? null : () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setDlg(() => saving = true);

                                final meter = double.parse(meterCtrl.text);
                                final rate = double.parse(rateCtrl.text);

                                final purchase = FabricPurchase(
                                  purchaseId: '',
                                  purchaseDate: selectedDate,
                                  partyName: partyCtrl.text.trim(),
                                  fabricType: fabricTypeCtrl.text.trim(),
                                  color: colorCtrl.text.trim(),
                                  meter: meter,
                                  rate: rate,
                                  totalAmount: meter * rate,
                                  remarks: remarksCtrl.text.trim(),
                                  invoiceNumber: invoiceCtrl.text.trim(),
                                  createdAt: DateTime.now(),
                                );

                                final error = await _service.addFabricPurchase(
                                  purchase,
                                );
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  if (error == null) {
                                    showSnackBar(
                                      context,
                                      '✓ Purchase saved successfully',
                                    );
                                  } else {
                                    showSnackBar(context, error, isError: true);
                                  }
                                }
                              },
                        icon: saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(saving ? 'Saving...' : 'Save Purchase'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1a237e),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _labelText(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.grey,
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    String? prefix,
    String? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix != null ? '$prefix ' : null,
        suffixText: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }

  String? _required(String? v) => v!.trim().isEmpty ? 'Required' : null;
  String? _numberValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v);
    if (n == null || n <= 0) return 'Enter valid number';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: isNarrow
          ? FloatingActionButton.extended(
              onPressed: _showAddDialog,
              backgroundColor: const Color(0xFF1a237e),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Purchase',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
      body: Padding(
        padding: EdgeInsets.all(isNarrow ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gray Fabric Purchase',
                      style: TextStyle(
                        fontSize: isNarrow ? 20 : 26,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1a237e),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Text(
                      'Track all raw fabric purchases',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                if (!isNarrow)
                  ElevatedButton.icon(
                    onPressed: _showAddDialog,
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text(
                      'Add Purchase',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1a237e),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Raw Stock Summary ──
            FutureBuilder<double>(
              future: _service.getAvailableRawMeter(),
              builder: (context, snap) => _RawStockBanner(
                availableMeter: snap.data ?? 0,
                isLoading: !snap.hasData,
              ),
            ),
            const SizedBox(height: 20),

            // ── Table / List ──
            Expanded(
              child: StreamBuilder<List<FabricPurchase>>(
                stream: _service.getFabricPurchasesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final purchases = snapshot.data ?? [];
                  if (purchases.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No purchases yet.\nTap "Add Purchase" to get started.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  return isNarrow
                      ? _buildMobileList(purchases)
                      : _buildDesktopTable(purchases);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList(List<FabricPurchase> purchases) {
    final fmt = DateFormat('dd MMM yyyy');
    return ListView.separated(
      itemCount: purchases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final p = purchases[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    p.partyName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '₹${p.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a237e),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _chip(
                    Icons.calendar_today_outlined,
                    fmt.format(p.purchaseDate),
                  ),
                  const SizedBox(width: 8),
                  _chip(
                    Icons.texture_rounded,
                    '${p.meter} m @ ₹${p.rate.toStringAsFixed(0)}',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _chip(Icons.palette_outlined, '${p.fabricType} · ${p.color}'),
                  if (p.invoiceNumber.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _chip(Icons.receipt_outlined, p.invoiceNumber),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildDesktopTable(List<FabricPurchase> purchases) {
    final fmt = DateFormat('dd MMM yyyy');
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F7FB)),
            dataRowMinHeight: 52,
            dataRowMaxHeight: 60,
            columns: const [
              DataColumn(
                label: Text(
                  'Date',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              DataColumn(
                label: Text(
                  'Party',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              DataColumn(
                label: Text(
                  'Fabric / Color',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              DataColumn(
                label: Text(
                  'Meter',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              DataColumn(
                label: Text(
                  'Rate',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              DataColumn(
                label: Text(
                  'Amount',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              DataColumn(
                label: Text(
                  'Invoice',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
            rows: purchases.map((p) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      fmt.format(p.purchaseDate),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  DataCell(
                    Text(
                      p.partyName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  DataCell(Text('${p.fabricType} · ${p.color}')),
                  DataCell(
                    Text(
                      '${p.meter.toStringAsFixed(1)} m',
                      style: const TextStyle(color: Color(0xFF0277BD)),
                    ),
                  ),
                  DataCell(Text('₹${p.rate.toStringAsFixed(0)}')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAF6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '₹${p.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a237e),
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      p.invoiceNumber.isNotEmpty ? p.invoiceNumber : '—',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _RawStockBanner extends StatelessWidget {
  final double availableMeter;
  final bool isLoading;

  const _RawStockBanner({
    required this.availableMeter,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAF6), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.texture_rounded,
              color: Color(0xFF1a237e),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Raw Fabric',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                isLoading
                    ? const SizedBox(
                        width: 80,
                        height: 20,
                        child: LinearProgressIndicator(),
                      )
                    : Text(
                        '${availableMeter.toStringAsFixed(1)} meters',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a237e),
                          letterSpacing: -0.5,
                        ),
                      ),
                const Text(
                  'Purchased − Printed = Available for use',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          if (availableMeter < 50 && !isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Low Stock',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
