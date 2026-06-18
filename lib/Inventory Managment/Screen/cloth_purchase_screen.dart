// ============================================================
// screens/production/cloth_purchase_screen.dart
//
// UNIFIED PIPELINE HUB
// - Left: Add new cloth purchase form
// - Right: All purchases as cards
//   Each card shows meters used/remaining + direct
//   "Send to Print" inline action — no separate screen hop.
// ============================================================

import 'package:ecom_manager/Inventory%20Managment/Model/production.dart';
import 'package:ecom_manager/Inventory%20Managment/Service/production_service.dart';
import 'package:ecom_manager/Product%20Listing/models/product.dart';
import 'package:ecom_manager/Product%20Listing/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Accent colors consistent with pipeline dashboard
const _kPurchaseColor = Color(0xFF4B6BFB);
const _kPrintColor = Color(0xFFFF8C42);

class ClothPurchaseScreen extends StatefulWidget {
  const ClothPurchaseScreen({super.key});

  @override
  State<ClothPurchaseScreen> createState() => _ClothPurchaseScreenState();
}

class _ClothPurchaseScreenState extends State<ClothPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceCtrl = TextEditingController();
  final _partyCtrl = TextEditingController();
  final _metersCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  final _prodService = ProductionService();
  final _productService = ProductService();

  String? _expandedPurchaseId;

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    _partyCtrl.dispose();
    _metersCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final meters = double.parse(_metersCtrl.text.trim());
    final purchase = ClothPurchase(
      id: '',
      invoiceNo: _invoiceCtrl.text.trim().toUpperCase(),
      partyName: _partyCtrl.text.trim(),
      purchaseDate: _selectedDate,
      totalMeters: meters,
      remainingMeters: meters,
      notes: _notesCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    final error = await _prodService.addClothPurchase(purchase);
    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase saved ✓'),
          backgroundColor: Colors.green,
        ),
      );
      _formKey.currentState!.reset();
      _invoiceCtrl.clear();
      _partyCtrl.clear();
      _metersCtrl.clear();
      _notesCtrl.clear();
      setState(() => _selectedDate = DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Cloth Purchases',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: Row(
        children: [
          // ── LEFT: Add purchase form ─────────────────────────
          Container(
            width: 340,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _kPurchaseColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart,
                            size: 18,
                            color: _kPurchaseColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'New Purchase',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _field(
                      label: 'Invoice No.',
                      ctrl: _invoiceCtrl,
                      hint: 'INV-2024-001',
                      icon: Icons.receipt_outlined,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      label: 'Party / Supplier',
                      ctrl: _partyCtrl,
                      hint: 'Surat Cloth Mills',
                      icon: Icons.store_outlined,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      label: 'Total Meters',
                      ctrl: _metersCtrl,
                      hint: '250',
                      icon: Icons.straighten,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final n = double.tryParse(v);
                        if (n == null || n <= 0) return 'Valid number required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    // Date picker
                    _fieldLabel('Purchase Date'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: _kPurchaseColor,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _field(
                      label: 'Notes (optional)',
                      ctrl: _notesCtrl,
                      hint: 'Cloth type, colour…',
                      icon: Icons.notes,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _savePurchase,
                        style: FilledButton.styleFrom(
                          backgroundColor: _kPurchaseColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add, size: 18),
                        label: const Text(
                          'Save Purchase',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── RIGHT: Purchases list ───────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    children: [
                      const Text(
                        'All Purchases',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      StreamBuilder<List<ClothPurchase>>(
                        stream: _prodService.getPurchasesStream(),
                        builder: (_, snap) {
                          final count = snap.data?.length ?? 0;
                          return Text(
                            '$count purchases',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<ClothPurchase>>(
                    stream: _prodService.getPurchasesStream(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final list = snap.data ?? [];
                      if (list.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 48,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No purchases yet.\nLeft panel ma add karo.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final purchase = list[i];
                          final isExpanded = _expandedPurchaseId == purchase.id;
                          return _PurchaseCard(
                            purchase: purchase,
                            isExpanded: isExpanded,
                            onToggle: () => setState(() {
                              _expandedPurchaseId = isExpanded
                                  ? null
                                  : purchase.id;
                            }),
                            prodService: _prodService,
                            productService: _productService,
                            onPrintJobSaved: () {
                              setState(() => _expandedPurchaseId = null);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) => Text(
    label,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade700,
    ),
  );

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon, size: 16, color: Colors.grey.shade400)
                : null,
            isDense: true,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kPurchaseColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// PURCHASE CARD
// ════════════════════════════════════════════════════════════
class _PurchaseCard extends StatefulWidget {
  final ClothPurchase purchase;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onPrintJobSaved;
  final ProductionService prodService;
  final ProductService productService;

  const _PurchaseCard({
    required this.purchase,
    required this.isExpanded,
    required this.onToggle,
    required this.onPrintJobSaved,
    required this.prodService,
    required this.productService,
  });

  @override
  State<_PurchaseCard> createState() => _PurchaseCardState();
}

class _PurchaseCardState extends State<_PurchaseCard> {
  final _printFormKey = GlobalKey<FormState>();
  final _designCtrl = TextEditingController();
  final _metersCtrl = TextEditingController();
  final _printNotesCtrl = TextEditingController();
  Product? _selectedProduct;
  List<Product> _products = [];
  bool _loadingProducts = false;
  bool _savingPrint = false;

  @override
  void initState() {
    super.initState();
    if (widget.isExpanded) _loadProducts();
  }

  @override
  void didUpdateWidget(covariant _PurchaseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded && !oldWidget.isExpanded) _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (_products.isNotEmpty) return;
    setState(() => _loadingProducts = true);
    final list = await widget.productService.getProductsStream().first.timeout(
      const Duration(seconds: 10),
    );
    if (!mounted) return;
    setState(() {
      _products = list.where((p) => p.isActive).toList();
      _loadingProducts = false;
    });
  }

  @override
  void dispose() {
    _designCtrl.dispose();
    _metersCtrl.dispose();
    _printNotesCtrl.dispose();
    super.dispose();
  }

  String? get _expectedPiecesHint {
    final meters = double.tryParse(_metersCtrl.text);
    if (meters == null || meters <= 0) return null;
    final avg = _selectedProduct?.avgConsumption;
    if (avg == null || avg <= 0) return null;
    return '≈ ${(meters / avg).floor()} pieces expected';
  }

  Future<void> _savePrintJob() async {
    if (!_printFormKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product select karo')));
      return;
    }
    final meters = double.parse(_metersCtrl.text.trim());
    if (meters > widget.purchase.remainingMeters) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Remaining meters ઓછા છે: ${widget.purchase.remainingMeters.toStringAsFixed(1)}m',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _savingPrint = true);

    final job = PrintJob(
      id: '',
      purchaseId: widget.purchase.id,
      productId: _selectedProduct!.productId,
      productName: _selectedProduct!.productName,
      productSku: _selectedProduct!.sku,
      designName: _designCtrl.text.trim(),
      metersUsed: meters,
      status: JobStatus.pending,
      createdAt: DateTime.now(),
      notes: _printNotesCtrl.text.trim(),
      avgConsumption: _selectedProduct!.avgConsumption,
    );

    final error = await widget.prodService.addPrintJob(job);
    if (!mounted) return;
    setState(() => _savingPrint = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Print job created ✓'),
          backgroundColor: Colors.green,
        ),
      );
      _designCtrl.clear();
      _metersCtrl.clear();
      _printNotesCtrl.clear();
      setState(() => _selectedProduct = null);
      widget.onPrintJobSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchase = widget.purchase;
    final usedMeters = purchase.totalMeters - purchase.remainingMeters;
    final usedFraction = purchase.totalMeters > 0
        ? usedMeters / purchase.totalMeters
        : 0.0;
    final isFinished = purchase.remainingMeters <= 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: widget.isExpanded
              ? _kPurchaseColor.withOpacity(0.4)
              : const Color(0xFFF0F0F0),
          width: widget.isExpanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // ── Card Header ──────────────────────────────────────
          InkWell(
            onTap: isFinished ? null : widget.onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isFinished
                              ? Colors.green.withOpacity(0.1)
                              : _kPurchaseColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isFinished
                              ? Icons.check_circle_outline
                              : Icons.shopping_bag_outlined,
                          size: 18,
                          color: isFinished ? Colors.green : _kPurchaseColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              purchase.partyName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Invoice: ${purchase.invoiceNo}  •  ${DateFormat('dd MMM yy').format(purchase.purchaseDate)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isFinished)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'All Used',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _kPurchaseColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${purchase.remainingMeters.toStringAsFixed(1)}m left',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _kPurchaseColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                widget.isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.add_circle_outline,
                                size: 16,
                                color: _kPurchaseColor,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: usedFraction.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation(
                        isFinished ? Colors.green : _kPurchaseColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Used ${usedMeters.toStringAsFixed(1)}m  /  Total ${purchase.totalMeters.toStringAsFixed(1)}m',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (!isFinished && !widget.isExpanded)
                        Text(
                          'Tap to add print job →',
                          style: TextStyle(
                            fontSize: 11,
                            color: _kPurchaseColor.withOpacity(0.7),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Inline Print Job Form ────────────────────────────
          if (widget.isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Form(
                key: _printFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.print_outlined,
                          size: 16,
                          color: _kPrintColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Send to Digital Print',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kPrintColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Remaining meters info chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _kPurchaseColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _kPurchaseColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.straighten,
                            size: 14,
                            color: _kPurchaseColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.purchase.remainingMeters.toStringAsFixed(1)}m available for printing',
                            style: TextStyle(
                              fontSize: 12,
                              color: _kPurchaseColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Product dropdown
                    _loadingProducts
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<Product>(
                            value: _selectedProduct,
                            hint: const Text('Select product (SKU)'),
                            isExpanded: true,
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            validator: (v) =>
                                v == null ? 'Product select karo' : null,
                            items: _products
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text('${p.sku} — ${p.productName}'),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedProduct = v),
                          ),
                    const SizedBox(height: 12),

                    // Design name + Meters used side by side
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _inlineField(
                            label: 'Design Name',
                            ctrl: _designCtrl,
                            hint: 'Floral Print A',
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _inlineField(
                            label: 'Meters Used',
                            ctrl: _metersCtrl,
                            hint: '80',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final n = double.tryParse(v);
                              if (n == null || n <= 0) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    // Expected pieces hint
                    if (_expectedPiecesHint != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 13,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _expectedPiecesHint!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    _inlineField(
                      label: 'Notes (optional)',
                      ctrl: _printNotesCtrl,
                      hint: 'Batch info…',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: widget.onToggle,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _savingPrint ? null : _savePrintJob,
                            style: FilledButton.styleFrom(
                              backgroundColor: _kPrintColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: _savingPrint
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send, size: 16),
                            label: const Text('Create Print Job'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inlineField({
    required String label,
    required TextEditingController ctrl,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          validator: validator,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }
}
