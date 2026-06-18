// ============================================================
// screens/production/print_job_screen.dart
//
// Displays all print jobs as pipeline cards.
// - Status: Pending → In Progress → Completed
// - "Mark Done" on a completed print job auto-opens
//   the stitch job bottom sheet (size-wise pieces entry)
//   directly from here — no separate screen navigation needed.
// ============================================================

import 'package:ecom_manager/Inventory%20Managment/Model/production.dart';
import 'package:ecom_manager/Inventory%20Managment/Service/production_service.dart';
import 'package:ecom_manager/Product%20Listing/models/product.dart';
import 'package:ecom_manager/Product%20Listing/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

const _kPrintColor = Color(0xFFFF8C42);
const _kStitchColor = Color(0xFF9B59B6);

class PrintJobScreen extends StatefulWidget {
  const PrintJobScreen({super.key});

  @override
  State<PrintJobScreen> createState() => _PrintJobScreenState();
}

class _PrintJobScreenState extends State<PrintJobScreen> {
  final _prodService = ProductionService();
  final _productService = ProductService();

  JobStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Print Jobs',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                _filterChip('All', null),
                const SizedBox(width: 8),
                _filterChip('Pending', JobStatus.pending),
                const SizedBox(width: 8),
                _filterChip('In Progress', JobStatus.inProgress),
                const SizedBox(width: 8),
                _filterChip('Completed', JobStatus.completed),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<PrintJob>>(
        stream: _prodService.getPrintJobsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          var jobs = snap.data ?? [];
          if (_filterStatus != null) {
            jobs = jobs.where((j) => j.status == _filterStatus).toList();
          }
          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.print_disabled_outlined,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _filterStatus == null
                        ? 'No print jobs yet.\nPurchase screen ma cloth add karo.'
                        : 'No ${_filterStatus!.label} jobs',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          // Group by status
          final pending = jobs
              .where((j) => j.status == JobStatus.pending)
              .toList();
          final inProgress = jobs
              .where((j) => j.status == JobStatus.inProgress)
              .toList();
          final completed = jobs
              .where((j) => j.status == JobStatus.completed)
              .toList();

          final sections = <_JobSection>[];
          if (_filterStatus == null) {
            if (inProgress.isNotEmpty)
              sections.add(_JobSection('🔵 In Progress', inProgress));
            if (pending.isNotEmpty)
              sections.add(_JobSection('🟡 Pending', pending));
            if (completed.isNotEmpty)
              sections.add(_JobSection('✅ Completed', completed));
          } else {
            sections.add(_JobSection(_filterStatus!.label, jobs));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sections.fold<int>(
              0,
              (sum, s) => sum + 1 + s.jobs.length,
            ),
            itemBuilder: (ctx, flatIndex) {
              int cursor = 0;
              for (final section in sections) {
                if (flatIndex == cursor) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 10),
                    child: Text(
                      section.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  );
                }
                cursor++;
                for (final job in section.jobs) {
                  if (flatIndex == cursor) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PrintJobCard(
                        job: job,
                        prodService: _prodService,
                        productService: _productService,
                        onStatusUpdated: () => setState(() {}),
                      ),
                    );
                  }
                  cursor++;
                }
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, JobStatus? status) {
    final isSelected = _filterStatus == status;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      selectedColor: _kPrintColor.withOpacity(0.15),
      onSelected: (_) => setState(() => _filterStatus = status),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      visualDensity: VisualDensity.compact,
      side: isSelected
          ? const BorderSide(color: _kPrintColor, width: 1.5)
          : BorderSide(color: Colors.grey.shade300),
    );
  }
}

class _JobSection {
  final String title;
  final List<PrintJob> jobs;
  _JobSection(this.title, this.jobs);
}

// ════════════════════════════════════════════════════════════
// PRINT JOB CARD
// ════════════════════════════════════════════════════════════
class _PrintJobCard extends StatefulWidget {
  final PrintJob job;
  final ProductionService prodService;
  final ProductService productService;
  final VoidCallback onStatusUpdated;

  const _PrintJobCard({
    required this.job,
    required this.prodService,
    required this.productService,
    required this.onStatusUpdated,
  });

  @override
  State<_PrintJobCard> createState() => _PrintJobCardState();
}

class _PrintJobCardState extends State<_PrintJobCard> {
  bool _updating = false;

  Color get _statusColor {
    switch (widget.job.status) {
      case JobStatus.pending:
        return Colors.orange;
      case JobStatus.inProgress:
        return _kPrintColor;
      case JobStatus.completed:
        return Colors.green;
    }
  }

  IconData get _statusIcon {
    switch (widget.job.status) {
      case JobStatus.pending:
        return Icons.hourglass_empty;
      case JobStatus.inProgress:
        return Icons.print;
      case JobStatus.completed:
        return Icons.check_circle_outline;
    }
  }

  Future<void> _startJob() async {
    setState(() => _updating = true);
    await widget.prodService.updatePrintJobStatus(
      widget.job.id,
      JobStatus.inProgress,
    );
    if (mounted) setState(() => _updating = false);
  }

  Future<void> _markDone() async {
    setState(() => _updating = true);
    final error = await widget.prodService.updatePrintJobStatus(
      widget.job.id,
      JobStatus.completed,
    );
    if (!mounted) return;
    setState(() => _updating = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }
    _openStitchSheet();
  }

  void _openStitchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StitchEntrySheet(
        printJob: widget.job,
        prodService: widget.prodService,
        productService: widget.productService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final isCompleted = job.status == JobStatus.completed;

    return Container(
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
          color: isCompleted
              ? Colors.green.withOpacity(0.3)
              : _statusColor.withOpacity(0.2),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_statusIcon, size: 20, color: _statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.designName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${job.productSku}  •  ${job.productName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    job.status.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: _statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Info chips ────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip(
                  Icons.straighten,
                  '${job.metersUsed.toStringAsFixed(1)}m cloth',
                ),
                if (job.expectedPieces != null)
                  _chip(
                    Icons.inventory_2_outlined,
                    '≈ ${job.expectedPieces} pcs expected',
                  ),
                if (job.startedAt != null)
                  _chip(
                    Icons.play_circle_outline,
                    'Started ${DateFormat('dd MMM').format(job.startedAt!)}',
                  ),
                if (job.completedAt != null)
                  _chip(
                    Icons.check_circle_outline,
                    'Done ${DateFormat('dd MMM').format(job.completedAt!)}',
                  ),
              ],
            ),

            if (job.notes != null && job.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '📝 ${job.notes}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // ── Action buttons ────────────────────────────────
            if (job.status != JobStatus.completed) ...[
              const SizedBox(height: 14),
              if (_updating)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (job.status == JobStatus.pending)
                OutlinedButton.icon(
                  onPressed: _startJob,
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Start Printing'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrintColor,
                    side: const BorderSide(color: _kPrintColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else if (job.status == JobStatus.inProgress)
                FilledButton.icon(
                  onPressed: _markDone,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Printing Done → Create Stitch Job'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],

            if (isCompleted) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _openStitchSheet,
                icon: Icon(
                  Icons.content_cut,
                  size: 14,
                  color: Colors.green.shade700,
                ),
                label: Text(
                  'Create Stitch Job',
                  style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// STITCH ENTRY BOTTOM SHEET
// ════════════════════════════════════════════════════════════
class _StitchEntrySheet extends StatefulWidget {
  final PrintJob printJob;
  final ProductionService prodService;
  final ProductService productService;

  const _StitchEntrySheet({
    required this.printJob,
    required this.prodService,
    required this.productService,
  });

  @override
  State<_StitchEntrySheet> createState() => _StitchEntrySheetState();
}

class _StitchEntrySheetState extends State<_StitchEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final Map<String, TextEditingController> _sizeCtrls = {};

  Product? _product;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final p = await widget.productService.getProduct(widget.printJob.productId);
    if (!mounted) return;
    setState(() {
      _product = p;
      _loading = false;
    });
    if (p != null) {
      for (final size in p.sizes) {
        final suggested = _suggestedPieces(size, p);
        _sizeCtrls[size] = TextEditingController(
          text: suggested > 0 ? suggested.toString() : '',
        );
      }
      setState(() {});
    }
  }

  int _suggestedPieces(String size, Product p) {
    final meters = widget.printJob.metersUsed;
    final sc = p.sizeConsumption;
    if (sc != null && sc.containsKey(size) && sc[size]! > 0) {
      return (meters / sc[size]!).floor();
    }
    final avg = p.avgConsumption;
    if (avg != null && avg > 0 && p.sizes.isNotEmpty) {
      return (meters / p.sizes.length / avg).floor();
    }
    return 0;
  }

  int get _totalPieces => _sizeCtrls.values
      .map((c) => int.tryParse(c.text.trim()) ?? 0)
      .fold(0, (a, b) => a + b);

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final c in _sizeCtrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_product == null) return;

    final pieces = <String, int>{};
    for (final e in _sizeCtrls.entries) {
      final v = int.tryParse(e.value.text.trim()) ?? 0;
      if (v > 0) pieces[e.key] = v;
    }
    if (pieces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ek pan size ma quantity nakhav')),
      );
      return;
    }

    setState(() => _saving = true);

    final job = StitchJob(
      id: '',
      printJobId: widget.printJob.id,
      productId: _product!.productId,
      productName: _product!.productName,
      productSku: _product!.sku,
      piecesBySize: pieces,
      status: JobStatus.pending,
      createdAt: DateTime.now(),
      notes: _notesCtrl.text.trim(),
    );

    final error = await widget.prodService.addStitchJob(job);
    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stitch job created ✓'),
          backgroundColor: Colors.green,
        ),
      );
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.printJob;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollCtrl) => SingleChildScrollView(
        controller: scrollCtrl,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: _loading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _kStitchColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.content_cut,
                            size: 18,
                            color: _kStitchColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'New Stitch Job',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${job.productSku} — ${job.designName}  •  ${job.metersUsed.toStringAsFixed(1)}m',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    if (_product == null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Product info load nai thai. Baad ma try karo.',
                        ),
                      )
                    else ...[
                      // Product info banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.checkroom,
                              size: 16,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_product!.productName}  •  Sizes: ${_product!.sizes.join(', ')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Numbers auto-suggest chhe. Edit kari shakay cho.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Size grid
                      Text(
                        'Pieces by Size',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _sizeCtrls.entries.map((entry) {
                          return SizedBox(
                            width: 90,
                            child: Column(
                              children: [
                                Container(
                                  width: 90,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _kStitchColor.withOpacity(0.1),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    entry.key,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _kStitchColor,
                                    ),
                                  ),
                                ),
                                TextFormField(
                                  controller: entry.value,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  onChanged: (_) => setState(() {}),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(8),
                                      ),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(8),
                                      ),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      // Total pieces
                      const SizedBox(height: 14),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _totalPieces > 0
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _totalPieces > 0
                                ? Colors.green.shade200
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 16,
                              color: _totalPieces > 0
                                  ? Colors.green.shade700
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Total: $_totalPieces pieces',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _totalPieces > 0
                                    ? Colors.green.shade700
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Notes (optional)',
                          hintText: 'Tailor name, batch info…',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: (_saving || _product == null) ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: _kStitchColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.content_cut, size: 18),
                        label: const Text(
                          'Create Stitch Job',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
