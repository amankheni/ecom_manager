// ============================================================
// screens/production/inventory_screen.dart
// Ready stock view — per product, per size.
// Low stock alert highlighting when qty < minStockAlert.
// ============================================================

import 'package:ecom_manager/Inventory%20Managment/Model/production.dart';
import 'package:ecom_manager/Inventory%20Managment/Service/production_service.dart';
import 'package:flutter/material.dart';

const _kStockColor = Color(0xFF2ECC71);
const _kLowColor = Color(0xFFE74C3C);

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _service = ProductionService();
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Ready Stock',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: StreamBuilder<List<InventoryItem>>(
        stream: _service.getInventoryStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allItems = snap.data ?? [];

          if (allItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _kStockColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      size: 36,
                      color: _kStockColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No stock yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Stitch job complete karo → stock auto-add thashe.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final lowStockItems = allItems.where((i) => i.isLowStock).toList();

          // Filter by search
          final items = _search.isEmpty
              ? allItems
              : allItems.where((i) {
                  final q = _search.toLowerCase();
                  return i.productName.toLowerCase().contains(q) ||
                      i.productSku.toLowerCase().contains(q);
                }).toList();

          final totalPieces = allItems.fold<int>(0, (a, b) => a + b.totalQty);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Low stock banner ────────────────────────────
              if (lowStockItems.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  color: _kLowColor.withOpacity(0.08),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: _kLowColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${lowStockItems.length} product(s) below minimum: '
                          '${lowStockItems.map((i) => i.productSku).join(', ')}',
                          style: TextStyle(
                            color: _kLowColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Stats + Search ──────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _statBadge(
                          '${allItems.length}',
                          'Products',
                          _kStockColor,
                        ),
                        const SizedBox(width: 12),
                        _statBadge(
                          '$totalPieces',
                          'Total Pieces',
                          Colors.grey.shade700,
                        ),
                        if (lowStockItems.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          _statBadge(
                            '${lowStockItems.length}',
                            'Low Stock',
                            _kLowColor,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Search bar
                    TextField(
                      onChanged: (v) => setState(() => _search = v),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search product or SKU…',
                        prefixIcon: Icon(
                          Icons.search,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Inventory list ──────────────────────────────
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          'No results for "$_search"',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) =>
                            _InventoryCard(item: items[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statBadge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// INVENTORY CARD
// ════════════════════════════════════════════════════════════
class _InventoryCard extends StatelessWidget {
  final InventoryItem item;

  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isLow = item.isLowStock;

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
          color: isLow ? _kLowColor.withOpacity(0.4) : const Color(0xFFF0F0F0),
          width: isLow ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLow
                        ? _kLowColor.withOpacity(0.1)
                        : _kStockColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isLow ? Icons.warning_amber : Icons.inventory_2_outlined,
                    size: 18,
                    color: isLow ? _kLowColor : _kStockColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
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
                      '${item.totalQty}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: isLow ? _kLowColor : _kStockColor,
                      ),
                    ),
                    Text(
                      'pcs total',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (item.minStockAlert != null)
                      Text(
                        'min: ${item.minStockAlert}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Stock progress bar (totalQty vs minStock)
            if (item.minStockAlert != null && item.minStockAlert! > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (item.totalQty / item.minStockAlert!).clamp(0.0, 1.5),
                  minHeight: 5,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation(
                    isLow ? _kLowColor : _kStockColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // ── Size breakdown ─────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.qtBySize.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _kStockColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kStockColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kStockColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${e.value}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'pcs',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            if (isLow) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _kLowColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kLowColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber, size: 14, color: _kLowColor),
                    const SizedBox(width: 6),
                    Text(
                      'Low stock — ${item.minStockAlert! - item.totalQty} more pieces needed to reach minimum',
                      style: TextStyle(
                        fontSize: 11,
                        color: _kLowColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
