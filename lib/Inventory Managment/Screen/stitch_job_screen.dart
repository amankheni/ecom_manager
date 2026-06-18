// ============================================================
// screens/production/stitch_job_screen.dart
//
// Stitch Jobs pipeline view.
// - Shows all stitch jobs grouped by status
// - Status: Pending → In Progress → Completed
// - On "Done → Add to Stock": directly pushes to inventory
//   with confirmation dialog showing size-wise breakdown
// ============================================================

import 'package:ecom_manager/Inventory%20Managment/Model/production.dart';
import 'package:ecom_manager/Inventory%20Managment/Service/production_service.dart';
import 'package:ecom_manager/Product%20Listing/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _kStitchColor = Color(0xFF9B59B6);
const _kStockColor = Color(0xFF2ECC71);

class StitchJobScreen extends StatefulWidget {
  const StitchJobScreen({super.key});

  @override
  State<StitchJobScreen> createState() => _StitchJobScreenState();
}

class _StitchJobScreenState extends State<StitchJobScreen> {
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
          'Stitch Jobs',
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
      body: StreamBuilder<List<StitchJob>>(
        stream: _prodService.getStitchJobsStream(),
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
                    Icons.content_cut,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _filterStatus == null
                        ? 'No stitch jobs yet.\nPrint job complete karo → stitch job banashe.'
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

          final sections = <_Section>[];
          if (_filterStatus == null) {
            if (inProgress.isNotEmpty)
              sections.add(_Section('🔵 In Progress', inProgress));
            if (pending.isNotEmpty)
              sections.add(_Section('🟡 Pending', pending));
            if (completed.isNotEmpty)
              sections.add(_Section('✅ Completed', completed));
          } else {
            sections.add(_Section(_filterStatus!.label, jobs));
          }

          final flatItems = <dynamic>[];
          for (final s in sections) {
            flatItems.add(s.title);
            flatItems.addAll(s.jobs);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: flatItems.length,
            itemBuilder: (ctx, i) {
              final item = flatItems[i];
              if (item is String) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 10),
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                );
              }
              final job = item as StitchJob;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StitchJobCard(
                  job: job,
                  prodService: _prodService,
                  productService: _productService,
                ),
              );
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
      selectedColor: _kStitchColor.withOpacity(0.15),
      onSelected: (_) => setState(() => _filterStatus = status),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      visualDensity: VisualDensity.compact,
      side: isSelected
          ? const BorderSide(color: _kStitchColor, width: 1.5)
          : BorderSide(color: Colors.grey.shade300),
    );
  }
}

class _Section {
  final String title;
  final List<StitchJob> jobs;
  _Section(this.title, this.jobs);
}

// ════════════════════════════════════════════════════════════
// STITCH JOB CARD
// ════════════════════════════════════════════════════════════
class _StitchJobCard extends StatefulWidget {
  final StitchJob job;
  final ProductionService prodService;
  final ProductService productService;

  const _StitchJobCard({
    required this.job,
    required this.prodService,
    required this.productService,
  });

  @override
  State<_StitchJobCard> createState() => _StitchJobCardState();
}

class _StitchJobCardState extends State<_StitchJobCard> {
  bool _updating = false;

  Color get _statusColor {
    switch (widget.job.status) {
      case JobStatus.pending:
        return Colors.orange;
      case JobStatus.inProgress:
        return _kStitchColor;
      case JobStatus.completed:
        return _kStockColor;
    }
  }

  Future<void> _startJob() async {
    setState(() => _updating = true);
    await widget.prodService.updateStitchJobStatus(
      widget.job.id,
      JobStatus.inProgress,
    );
    if (mounted) setState(() => _updating = false);
  }

  Future<void> _confirmAndComplete() async {
    final job = widget.job;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.inventory_2_outlined, size: 20, color: _kStockColor),
            SizedBox(width: 8),
            Text(
              'Add to Stock?',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${job.productSku} — ${job.productName}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 12),
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
                    color: _kStockColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kStockColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _kStockColor,
                        ),
                      ),
                      Text(
                        '${e.value}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'pcs',
                        style: TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Total: ${job.totalPieces} pieces → Inventory ma add thashe',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.add_box_outlined, size: 16),
            label: const Text('Add to Stock'),
            style: FilledButton.styleFrom(
              backgroundColor: _kStockColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _updating = true);

    // 1. Mark stitch job complete
    final statusError = await widget.prodService.updateStitchJobStatus(
      widget.job.id,
      JobStatus.completed,
    );
    if (statusError != null) {
      if (!mounted) return;
      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(statusError), backgroundColor: Colors.red),
      );
      return;
    }

    // 2. Push to inventory
    final product = await widget.productService.getProduct(
      widget.job.productId,
    );
    final invError = await widget.prodService.addToInventory(
      productId: widget.job.productId,
      productName: widget.job.productName,
      productSku: widget.job.productSku,
      piecesBySize: widget.job.piecesBySize,
      minStockAlert: product?.minStockAlert,
    );

    if (!mounted) return;
    setState(() => _updating = false);

    if (invError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(invError), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Stock updated ✓  +${widget.job.totalPieces} pieces'),
            ],
          ),
          backgroundColor: _kStockColor,
        ),
      );
    }
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
              ? _kStockColor.withOpacity(0.3)
              : _statusColor.withOpacity(0.2),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
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
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle_outline
                        : job.status == JobStatus.inProgress
                        ? Icons.content_cut
                        : Icons.hourglass_empty,
                    size: 20,
                    color: _statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
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

            const SizedBox(height: 14),

            // ── Size chips ─────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ...job.piecesBySize.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? _kStockColor.withOpacity(0.1)
                          : _kStitchColor.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCompleted
                            ? _kStockColor.withOpacity(0.3)
                            : _kStitchColor.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          e.key,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isCompleted ? _kStockColor : _kStitchColor,
                          ),
                        ),
                        Text(
                          '${e.value}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isCompleted
                                ? _kStockColor.withOpacity(0.8)
                                : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                // Total badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      Text(
                        '${job.totalPieces}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
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

            // ── Date info ──────────────────────────────────────
            const SizedBox(height: 8),
            Text(
              'Created ${DateFormat('dd MMM yyyy').format(job.createdAt)}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),

            // ── Actions ────────────────────────────────────────
            if (!isCompleted) ...[
              const SizedBox(height: 14),
              if (_updating)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (job.status == JobStatus.pending)
                OutlinedButton.icon(
                  onPressed: _startJob,
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Start Stitching'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kStitchColor,
                    side: const BorderSide(color: _kStitchColor),
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
                  onPressed: _confirmAndComplete,
                  icon: const Icon(Icons.add_box_outlined, size: 16),
                  label: const Text('Done → Add to Stock'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kStockColor,
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
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 14,
                    color: _kStockColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Stock updated',
                    style: TextStyle(
                      fontSize: 12,
                      color: _kStockColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (job.completedAt != null) ...[
                    Text(
                      '  •  ${DateFormat('dd MMM  hh:mm a').format(job.completedAt!)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: _kStockColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
