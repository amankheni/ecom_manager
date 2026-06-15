// ============================================================
// screens/inventory_dashboard_screen.dart
// Beautiful inventory overview — live stats with color coding
// Responsive: wraps cards on mobile
// ============================================================

import 'package:ecom_manager/services/product_service.dart';
import 'package:ecom_manager/utils/constants.dart';
import 'package:flutter/material.dart';
import '../services/production_service.dart';

class InventoryDashboardScreen extends StatefulWidget {
  const InventoryDashboardScreen({super.key});

  @override
  State<InventoryDashboardScreen> createState() =>
      _InventoryDashboardScreenState();
}

class _InventoryDashboardScreenState extends State<InventoryDashboardScreen> {
  final _productionService = ProductionService();
  final _productService = ProductService();

  Map<String, dynamic> _stats = {};
  int _totalProducts = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _productionService.getInventoryStats(),
      _productService.getDashboardStats(),
    ]);
    if (mounted) {
      setState(() {
        _stats = results[0];
        _totalProducts = (results[1] as Map<String, int>)['total'] ?? 0;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                        'Inventory Dashboard',
                        style: TextStyle(
                          fontSize: isNarrow ? 20 : 26,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1a237e),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Live overview — Fabric → Printing → Production → Stock',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _loadStats,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1a237e),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const Center(
                  heightFactor: 3,
                  child: CircularProgressIndicator(),
                )
              else ...[
                // ── Fabric Flow Banner ──
                _FlowBanner(
                  purchased:
                      (_stats['rawFabric'] as double) +
                      (_stats['printedFabric'] as double),
                  printed: _stats['printedFabric'] as double,
                  available: _stats['rawFabric'] as double,
                  isNarrow: isNarrow,
                ),
                const SizedBox(height: 20),

                // ── Stat Cards ──
                if (isNarrow) _buildMobileCards() else _buildDesktopCards(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopCards() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: _cardData()
          .map(
            (d) => _StatCard(
              title: d['title'],
              value: d['value'],
              subtitle: d['subtitle'],
              icon: d['icon'],
              color: d['color'],
              bgColor: d['bgColor'],
            ),
          )
          .toList(),
    );
  }

  Widget _buildMobileCards() {
    final cards = _cardData();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: cards[0]['title'],
                value: cards[0]['value'],
                subtitle: cards[0]['subtitle'],
                icon: cards[0]['icon'],
                color: cards[0]['color'],
                bgColor: cards[0]['bgColor'],
                compact: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: cards[1]['title'],
                value: cards[1]['value'],
                subtitle: cards[1]['subtitle'],
                icon: cards[1]['icon'],
                color: cards[1]['color'],
                bgColor: cards[1]['bgColor'],
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: cards[2]['title'],
                value: cards[2]['value'],
                subtitle: cards[2]['subtitle'],
                icon: cards[2]['icon'],
                color: cards[2]['color'],
                bgColor: cards[2]['bgColor'],
                compact: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: cards[3]['title'],
                value: cards[3]['value'],
                subtitle: cards[3]['subtitle'],
                icon: cards[3]['icon'],
                color: cards[3]['color'],
                bgColor: cards[3]['bgColor'],
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatCard(
          title: cards[4]['title'],
          value: cards[4]['value'],
          subtitle: cards[4]['subtitle'],
          icon: cards[4]['icon'],
          color: cards[4]['color'],
          bgColor: cards[4]['bgColor'],
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _cardData() {
    final rawFabric = (_stats['rawFabric'] as double);
    return [
      {
        'title': 'Raw Fabric',
        'value': '${rawFabric.toStringAsFixed(1)} m',
        'subtitle': 'Available to print',
        'icon': Icons.texture_rounded,
        'color': const Color(0xFF1a237e),
        'bgColor': const Color(0xFFE8EAF6),
      },
      {
        'title': 'Total Printed',
        'value': '${(_stats['printedFabric'] as double).toStringAsFixed(1)} m',
        'subtitle': 'Fabric printed so far',
        'icon': Icons.print_rounded,
        'color': const Color(0xFF0277BD),
        'bgColor': const Color(0xFFE1F5FE),
      },
      {
        'title': 'Ready Pieces',
        'value': '${_stats['readyPieces']}',
        'subtitle': 'In stock right now',
        'icon': Icons.checkroom_rounded,
        'color': const Color(0xFF2E7D32),
        'bgColor': const Color(0xFFE8F5E9),
      },
      {
        'title': 'Total Products',
        'value': '$_totalProducts',
        'subtitle': 'In product catalog',
        'icon': Icons.inventory_2_rounded,
        'color': const Color(0xFFE65100),
        'bgColor': const Color(0xFFFBE9E7),
      },
      {
        'title': "Today's Production",
        'value': '${_stats['todayProduction']} pcs',
        'subtitle': 'Stitched today',
        'icon': Icons.today_rounded,
        'color': const Color(0xFF6A1B9A),
        'bgColor': const Color(0xFFF3E5F5),
      },
    ];
  }
}

// ── Fabric Flow Banner ──
class _FlowBanner extends StatelessWidget {
  final double purchased;
  final double printed;
  final double available;
  final bool isNarrow;

  const _FlowBanner({
    required this.purchased,
    required this.printed,
    required this.available,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isNarrow ? 14 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a237e), Color(0xFF283593)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FABRIC FLOW',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          if (isNarrow)
            Column(
              children: [
                _flowItem(
                  'Purchased',
                  '${purchased.toStringAsFixed(1)} m',
                  Icons.shopping_bag_outlined,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Icon(
                    Icons.arrow_downward,
                    color: Colors.white38,
                    size: 16,
                  ),
                ),
                _flowItem(
                  'Printed',
                  '${printed.toStringAsFixed(1)} m',
                  Icons.print_rounded,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Icon(
                    Icons.arrow_downward,
                    color: Colors.white38,
                    size: 16,
                  ),
                ),
                _flowItem(
                  'Available',
                  '${available.toStringAsFixed(1)} m',
                  Icons.inventory_2_outlined,
                  highlight: true,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _flowItem(
                    'Purchased',
                    '${purchased.toStringAsFixed(1)} m',
                    Icons.shopping_bag_outlined,
                  ),
                ),
                _arrow(),
                Expanded(
                  child: _flowItem(
                    'Printed',
                    '${printed.toStringAsFixed(1)} m',
                    Icons.print_rounded,
                  ),
                ),
                _arrow(),
                Expanded(
                  child: _flowItem(
                    'Available',
                    '${available.toStringAsFixed(1)} m',
                    Icons.inventory_2_outlined,
                    highlight: true,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: purchased > 0 ? (printed / purchased).clamp(0.0, 1.0) : 0,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF42A5F5),
              ),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${purchased > 0 ? ((printed / purchased) * 100).toStringAsFixed(0) : 0}% of purchased fabric has been printed',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _flowItem(
    String label,
    String value,
    IconData icon, {
    bool highlight = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: highlight ? const Color(0xFF80DEEA) : Colors.white60,
          size: 22,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: highlight ? const Color(0xFF80DEEA) : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _arrow() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Icon(Icons.arrow_forward, color: Colors.white24, size: 20),
  );
}

// ── Stat Card ──
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool compact;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? null : 200,
      padding: EdgeInsets.all(compact ? 14 : 20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: compact ? 20 : 24),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 22 : 28,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
