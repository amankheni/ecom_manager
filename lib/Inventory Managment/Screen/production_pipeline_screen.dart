// ============================================================
// screens/production/production_pipeline_screen.dart
//
// UNIFIED PIPELINE DASHBOARD
// Shows all cloth purchases as pipeline cards.
// Each card has 4 connected stages:
//   [Purchase] → [Print] → [Stitch] → [Ready Stock]
// Tap any stage box to see details or take action.
// ============================================================

import 'dart:async';

import 'package:ecom_manager/Inventory%20Managment/Model/production.dart';
import 'package:ecom_manager/Inventory%20Managment/Screen/cloth_purchase_screen.dart';
import 'package:ecom_manager/Inventory%20Managment/Screen/inventory_screen.dart';
import 'package:ecom_manager/Inventory%20Managment/Screen/print_job_screen.dart';
import 'package:ecom_manager/Inventory%20Managment/Screen/stitch_job_screen.dart';
import 'package:ecom_manager/Inventory%20Managment/Service/production_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductionPipelineScreen extends StatefulWidget {
  const ProductionPipelineScreen({super.key});

  @override
  State<ProductionPipelineScreen> createState() =>
      _ProductionPipelineScreenState();
}

class _ProductionPipelineScreenState extends State<ProductionPipelineScreen> {
  final _service = ProductionService();

  late StreamSubscription _purchaseSub;
  late StreamSubscription _printSub;
  late StreamSubscription _stitchSub;
  late StreamSubscription _inventorySub;

  List<ClothPurchase> _purchases = [];
  List<PrintJob> _printJobs = [];
  List<StitchJob> _stitchJobs = [];
  List<InventoryItem> _inventory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _purchaseSub = _service.getPurchasesStream().listen((d) {
      if (mounted)
        setState(() {
          _purchases = d;
          _loading = false;
        });
    });
    _printSub = _service.getPrintJobsStream().listen((d) {
      if (mounted) setState(() => _printJobs = d);
    });
    _stitchSub = _service.getStitchJobsStream().listen((d) {
      if (mounted) setState(() => _stitchJobs = d);
    });
    _inventorySub = _service.getInventoryStream().listen((d) {
      if (mounted) setState(() => _inventory = d);
    });
  }

  @override
  void dispose() {
    _purchaseSub.cancel();
    _printSub.cancel();
    _stitchSub.cancel();
    _inventorySub.cancel();
    super.dispose();
  }

  // ── Stats for top summary row ───────────────────────────
  int get _activePrintJobs =>
      _printJobs.where((j) => j.status != JobStatus.completed).length;

  int get _activeStitchJobs =>
      _stitchJobs.where((j) => j.status != JobStatus.completed).length;

  int get _totalReadyStock => _inventory.fold(0, (a, b) => a + b.totalQty);

  int get _lowStockCount => _inventory.where((i) => i.isLowStock).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Production Pipeline',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              '${_purchases.length} purchases tracked',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          _AppBarAction(
            icon: Icons.shopping_bag_outlined,
            label: 'Purchases',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClothPurchaseScreen()),
            ),
          ),
          _AppBarAction(
            icon: Icons.print_outlined,
            label: 'Print Jobs',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrintJobScreen()),
            ),
          ),
          _AppBarAction(
            icon: Icons.content_cut,
            label: 'Stitch Jobs',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StitchJobScreen()),
            ),
          ),
          _AppBarAction(
            icon: Icons.inventory_2_outlined,
            label: 'Ready Stock',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InventoryScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Stats summary bar ───────────────────────
                _SummaryBar(
                  activePrint: _activePrintJobs,
                  activeStitch: _activeStitchJobs,
                  readyStock: _totalReadyStock,
                  lowStock: _lowStockCount,
                  onTapPrint: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrintJobScreen()),
                  ),
                  onTapStitch: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StitchJobScreen()),
                  ),
                  onTapStock: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InventoryScreen()),
                  ),
                ),

                // ── Pipeline cards ──────────────────────────
                Expanded(
                  child: _purchases.isEmpty
                      ? _EmptyState(
                          onAddPurchase: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ClothPurchaseScreen(),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: _purchases.length,
                          itemBuilder: (ctx, i) {
                            final purchase = _purchases[i];
                            final prints = _printJobs
                                .where((j) => j.purchaseId == purchase.id)
                                .toList();
                            return _PipelineCard(
                              purchase: purchase,
                              printJobs: prints,
                              stitchJobs: _stitchJobs,
                              inventory: _inventory,
                              service: _service,
                              onOpenPurchases: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ClothPurchaseScreen(),
                                ),
                              ),
                              onOpenPrint: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PrintJobScreen(),
                                ),
                              ),
                              onOpenStitch: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StitchJobScreen(),
                                ),
                              ),
                              onOpenStock: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const InventoryScreen(),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ClothPurchaseScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Purchase'),
        backgroundColor: primary,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// TOP STATS BAR
// ════════════════════════════════════════════════════════════
class _SummaryBar extends StatelessWidget {
  final int activePrint;
  final int activeStitch;
  final int readyStock;
  final int lowStock;
  final VoidCallback onTapPrint;
  final VoidCallback onTapStitch;
  final VoidCallback onTapStock;

  const _SummaryBar({
    required this.activePrint,
    required this.activeStitch,
    required this.readyStock,
    required this.lowStock,
    required this.onTapPrint,
    required this.onTapStitch,
    required this.onTapStock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: [
          _StatTile(
            label: 'Print Jobs',
            value: '$activePrint active',
            icon: Icons.print_outlined,
            color: const Color(0xFF4B6BFB),
            onTap: onTapPrint,
          ),
          const SizedBox(width: 10),
          _StatTile(
            label: 'Stitch Jobs',
            value: '$activeStitch active',
            icon: Icons.content_cut,
            color: const Color(0xFFFF8C42),
            onTap: onTapStitch,
          ),
          const SizedBox(width: 10),
          _StatTile(
            label: 'Ready Stock',
            value: '$readyStock pcs',
            icon: Icons.inventory_2_outlined,
            color: lowStock > 0 ? Colors.red.shade600 : const Color(0xFF2ECC71),
            badge: lowStock > 0 ? '$lowStock low' : null,
            onTap: onTapStock,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// PIPELINE CARD — one card per cloth purchase
// Shows 4 connected stage boxes
// ════════════════════════════════════════════════════════════
class _PipelineCard extends StatelessWidget {
  final ClothPurchase purchase;
  final List<PrintJob> printJobs;
  final List<StitchJob> stitchJobs;
  final List<InventoryItem> inventory;
  final ProductionService service;
  final VoidCallback onOpenPurchases;
  final VoidCallback onOpenPrint;
  final VoidCallback onOpenStitch;
  final VoidCallback onOpenStock;

  const _PipelineCard({
    required this.purchase,
    required this.printJobs,
    required this.stitchJobs,
    required this.inventory,
    required this.service,
    required this.onOpenPurchases,
    required this.onOpenPrint,
    required this.onOpenStitch,
    required this.onOpenStock,
  });

  // Stitch jobs that belong to this purchase's print jobs
  List<StitchJob> get _relatedStitch {
    final printIds = printJobs.map((j) => j.id).toSet();
    return stitchJobs.where((s) => printIds.contains(s.printJobId)).toList();
  }

  // Inventory items for products in this pipeline
  List<InventoryItem> get _relatedInventory {
    final productIds = printJobs.map((j) => j.productId).toSet();
    return inventory.where((i) => productIds.contains(i.productId)).toList();
  }

  // Print job stage summary
  String get _printSummary {
    if (printJobs.isEmpty) return 'No print jobs';
    final done = printJobs.where((j) => j.status == JobStatus.completed).length;
    return '${printJobs.length} jobs  •  $done done';
  }

  // Stitch job stage summary
  String get _stitchSummary {
    final related = _relatedStitch;
    if (related.isEmpty) return 'No stitch jobs';
    final done = related.where((j) => j.status == JobStatus.completed).length;
    return '${related.length} jobs  •  $done done';
  }

  // Ready stock summary
  String get _stockSummary {
    final related = _relatedInventory;
    if (related.isEmpty) return 'No stock yet';
    final total = related.fold(0, (a, b) => a + b.totalQty);
    return '$total pieces ready';
  }

  // Overall pipeline progress 0..4
  int get _stageProgress {
    if (printJobs.isEmpty) return 0;
    final allPrintDone = printJobs.every(
      (j) => j.status == JobStatus.completed,
    );
    if (!allPrintDone) return 1;
    final related = _relatedStitch;
    if (related.isEmpty) return 1;
    final allStitchDone = related.every((j) => j.status == JobStatus.completed);
    if (!allStitchDone) return 2;
    if (_relatedInventory.isEmpty) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final usedMeters = purchase.totalMeters - purchase.remainingMeters;
    final usedFraction = purchase.totalMeters > 0
        ? usedMeters / purchase.totalMeters
        : 0.0;
    final isFinished = purchase.remainingMeters <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card Header ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4B6BFB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 18,
                        color: Color(0xFF4B6BFB),
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
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Invoice ${purchase.invoiceNo}  •  ${DateFormat('dd MMM yyyy').format(purchase.purchaseDate)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isFinished)
                      _Badge(label: 'Fully Used', color: Colors.green)
                    else
                      _Badge(
                        label:
                            '${purchase.remainingMeters.toStringAsFixed(1)}m left',
                        color: const Color(0xFF4B6BFB),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Meters progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: usedFraction.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(
                      isFinished ? Colors.green : const Color(0xFF4B6BFB),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Used ${usedMeters.toStringAsFixed(1)}m of ${purchase.totalMeters.toStringAsFixed(1)}m total',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

          // ── 4 Stage Boxes ────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Stage 1: Purchase
                Expanded(
                  child: _StageBox(
                    stageNumber: 1,
                    icon: Icons.shopping_bag_outlined,
                    title: 'Purchase',
                    subtitle:
                        '${purchase.totalMeters.toStringAsFixed(0)}m cloth',
                    detail: purchase.partyName,
                    color: const Color(0xFF4B6BFB),
                    isActive: true,
                    isDone: true,
                    onTap: () => _showPurchaseDetail(context),
                  ),
                ),
                _PipelineArrow(active: _stageProgress >= 1),
                // Stage 2: Print
                Expanded(
                  child: _StageBox(
                    stageNumber: 2,
                    icon: Icons.print_outlined,
                    title: 'Print',
                    subtitle: _printSummary,
                    detail: printJobs.isEmpty
                        ? 'Tap to add'
                        : '${printJobs.fold(0.0, (a, b) => a + b.metersUsed).toStringAsFixed(1)}m printed',
                    color: const Color(0xFFFF8C42),
                    isActive: _stageProgress >= 0,
                    isDone:
                        printJobs.isNotEmpty &&
                        printJobs.every((j) => j.status == JobStatus.completed),
                    onTap: () => printJobs.isEmpty
                        ? onOpenPurchases()
                        : _showPrintDetail(context),
                  ),
                ),
                _PipelineArrow(active: _stageProgress >= 2),
                // Stage 3: Stitch
                Expanded(
                  child: _StageBox(
                    stageNumber: 3,
                    icon: Icons.content_cut,
                    title: 'Stitch',
                    subtitle: _stitchSummary,
                    detail: _relatedStitch.isEmpty
                        ? 'Pending print'
                        : '${_relatedStitch.fold(0, (a, b) => a + b.totalPieces)} pcs',
                    color: const Color(0xFF9B59B6),
                    isActive: _stageProgress >= 1,
                    isDone:
                        _relatedStitch.isNotEmpty &&
                        _relatedStitch.every(
                          (j) => j.status == JobStatus.completed,
                        ),
                    onTap: () => _relatedStitch.isEmpty
                        ? onOpenPrint()
                        : _showStitchDetail(context),
                  ),
                ),
                _PipelineArrow(active: _stageProgress >= 3),
                // Stage 4: Ready Stock
                Expanded(
                  child: _StageBox(
                    stageNumber: 4,
                    icon: Icons.inventory_2_outlined,
                    title: 'Stock',
                    subtitle: _stockSummary,
                    detail: _relatedInventory.isEmpty
                        ? 'Pending stitch'
                        : _relatedInventory.map((i) => i.productSku).join(', '),
                    color: const Color(0xFF2ECC71),
                    isActive: _stageProgress >= 3,
                    isDone: _relatedInventory.isNotEmpty,
                    onTap: () => _relatedInventory.isEmpty
                        ? onOpenStitch()
                        : _showStockDetail(context),
                  ),
                ),
              ],
            ),
          ),

          // ── Notes ────────────────────────────────────────
          if (purchase.notes != null && purchase.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                '📝 ${purchase.notes}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Detail bottom sheets ─────────────────────────────────

  void _showPurchaseDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PurchaseDetailSheet(purchase: purchase),
    );
  }

  void _showPrintDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PrintDetailSheet(jobs: printJobs),
    );
  }

  void _showStitchDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StitchDetailSheet(jobs: _relatedStitch),
    );
  }

  void _showStockDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StockDetailSheet(items: _relatedInventory),
    );
  }
}

// ════════════════════════════════════════════════════════════
// STAGE BOX WIDGET
// ════════════════════════════════════════════════════════════
class _StageBox extends StatelessWidget {
  final int stageNumber;
  final IconData icon;
  final String title;
  final String subtitle;
  final String detail;
  final Color color;
  final bool isActive;
  final bool isDone;
  final VoidCallback onTap;

  const _StageBox({
    required this.stageNumber,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.color,
    required this.isActive,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isActive ? color : Colors.grey.shade300;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive
              ? effectiveColor.withOpacity(0.07)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDone
                ? effectiveColor
                : isActive
                ? effectiveColor.withOpacity(0.4)
                : Colors.grey.shade200,
            width: isDone ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDone ? Icons.check_circle : icon,
                  size: 14,
                  color: isDone ? effectiveColor : effectiveColor,
                ),
                const Spacer(),
                Text(
                  '$stageNumber',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: effectiveColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.grey.shade800 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: isActive ? effectiveColor : Colors.grey.shade400,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// PIPELINE ARROW CONNECTOR
// ════════════════════════════════════════════════════════════
class _PipelineArrow extends StatelessWidget {
  final bool active;
  const _PipelineArrow({required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 10,
        color: active
            ? const Color(0xFF4B6BFB).withOpacity(0.5)
            : Colors.grey.shade200,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// APP BAR ACTION BUTTON
// ════════════════════════════════════════════════════════════
class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AppBarAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// BADGE WIDGET
// ════════════════════════════════════════════════════════════
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// EMPTY STATE
// ════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final VoidCallback onAddPurchase;
  const _EmptyState({required this.onAddPurchase});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF4B6BFB).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 36,
              color: Color(0xFF4B6BFB),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No purchases yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'First cloth purchase add karo to pipeline start thase.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAddPurchase,
            icon: const Icon(Icons.add),
            label: const Text('Add First Purchase'),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// DETAIL BOTTOM SHEETS
// ════════════════════════════════════════════════════════════

class _PurchaseDetailSheet extends StatelessWidget {
  final ClothPurchase purchase;
  const _PurchaseDetailSheet({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final used = purchase.totalMeters - purchase.remainingMeters;
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  color: Color(0xFF4B6BFB),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Purchase Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow(label: 'Party / Supplier', value: purchase.partyName),
            _DetailRow(label: 'Invoice No.', value: purchase.invoiceNo),
            _DetailRow(
              label: 'Purchase Date',
              value: DateFormat('dd MMM yyyy').format(purchase.purchaseDate),
            ),
            _DetailRow(
              label: 'Total Meters',
              value: '${purchase.totalMeters.toStringAsFixed(2)}m',
            ),
            _DetailRow(
              label: 'Meters Used',
              value: '${used.toStringAsFixed(2)}m',
            ),
            _DetailRow(
              label: 'Remaining',
              value: '${purchase.remainingMeters.toStringAsFixed(2)}m',
              valueColor: purchase.remainingMeters <= 0
                  ? Colors.grey
                  : const Color(0xFF4B6BFB),
            ),
            if (purchase.notes != null && purchase.notes!.isNotEmpty)
              _DetailRow(label: 'Notes', value: purchase.notes!),
            const SizedBox(height: 16),
            // Usage bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: purchase.totalMeters > 0
                    ? (used / purchase.totalMeters).clamp(0.0, 1.0)
                    : 0,
                minHeight: 10,
                backgroundColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${((used / purchase.totalMeters) * 100).toStringAsFixed(1)}% cloth used',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrintDetailSheet extends StatelessWidget {
  final List<PrintJob> jobs;
  const _PrintDetailSheet({required this.jobs});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.print_outlined, color: Color(0xFFFF8C42)),
                const SizedBox(width: 8),
                Text(
                  'Print Jobs (${jobs.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...jobs.map((job) => _PrintJobDetailCard(job: job)),
          ],
        ),
      ),
    );
  }
}

class _PrintJobDetailCard extends StatelessWidget {
  final PrintJob job;
  const _PrintJobDetailCard({required this.job});

  Color get _statusColor {
    switch (job.status) {
      case JobStatus.pending:
        return Colors.orange;
      case JobStatus.inProgress:
        return Colors.blue;
      case JobStatus.completed:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      job.productSku,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
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
          const SizedBox(height: 10),
          _DetailRow(label: 'Design', value: job.designName),
          _DetailRow(
            label: 'Meters Used',
            value: '${job.metersUsed.toStringAsFixed(2)}m',
          ),
          if (job.expectedPieces != null)
            _DetailRow(
              label: 'Expected Pieces',
              value: '~${job.expectedPieces} pcs',
            ),
          if (job.startedAt != null)
            _DetailRow(
              label: 'Started',
              value: DateFormat('dd MMM  hh:mm a').format(job.startedAt!),
            ),
          if (job.completedAt != null)
            _DetailRow(
              label: 'Completed',
              value: DateFormat('dd MMM  hh:mm a').format(job.completedAt!),
            ),
          if (job.notes != null && job.notes!.isNotEmpty)
            _DetailRow(label: 'Notes', value: job.notes!),
        ],
      ),
    );
  }
}

class _StitchDetailSheet extends StatelessWidget {
  final List<StitchJob> jobs;
  const _StitchDetailSheet({required this.jobs});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.content_cut, color: Color(0xFF9B59B6)),
                const SizedBox(width: 8),
                Text(
                  'Stitch Jobs (${jobs.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...jobs.map((job) => _StitchJobDetailCard(job: job)),
          ],
        ),
      ),
    );
  }
}

class _StitchJobDetailCard extends StatelessWidget {
  final StitchJob job;
  const _StitchJobDetailCard({required this.job});

  Color get _statusColor {
    switch (job.status) {
      case JobStatus.pending:
        return Colors.orange;
      case JobStatus.inProgress:
        return Colors.blue;
      case JobStatus.completed:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${job.totalPieces} total pieces',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
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
          // Size breakdown
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: job.piecesBySize.entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B59B6).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF9B59B6).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      e.key,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9B59B6),
                      ),
                    ),
                    Text(
                      '${e.value}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (job.completedAt != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 13,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Stock updated on ${DateFormat('dd MMM hh:mm a').format(job.completedAt!)}',
                  style: TextStyle(fontSize: 11, color: Colors.green.shade600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StockDetailSheet extends StatelessWidget {
  final List<InventoryItem> items;
  const _StockDetailSheet({required this.items});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF2ECC71),
                ),
                const SizedBox(width: 8),
                Text(
                  'Ready Stock (${items.length} products)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((item) => _StockDetailCard(item: item)),
          ],
        ),
      ),
    );
  }
}

class _StockDetailCard extends StatelessWidget {
  final InventoryItem item;
  const _StockDetailCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isLow = item.isLowStock;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLow ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLow ? Colors.red.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      item.productSku,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.totalQty} pcs',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isLow
                          ? Colors.red.shade700
                          : const Color(0xFF2ECC71),
                    ),
                  ),
                  if (item.minStockAlert != null)
                    Text(
                      'min: ${item.minStockAlert}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: item.qtBySize.entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF2ECC71).withOpacity(0.25),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      e.key,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2ECC71),
                      ),
                    ),
                    Text(
                      '${e.value}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (isLow) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.warning_amber, size: 13, color: Colors.red.shade600),
                const SizedBox(width: 4),
                Text(
                  'Low stock alert',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Last updated: ${DateFormat('dd MMM yyyy').format(item.lastUpdated)}',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// SHARED UTILITY WIDGETS
// ════════════════════════════════════════════════════════════

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
