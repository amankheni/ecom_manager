// ============================================================
// screens/dashboard_screen.dart
// Shows total, active, and inactive product counts
// ============================================================

import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../utils/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _productService = ProductService();

  Map<String, int> _stats = {'total': 0, 'active': 0, 'inactive': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // Fetch stats from Firestore
  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await _productService.getDashboardStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              // Refresh button
              IconButton(
                onPressed: _loadStats,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Overview of your product catalog',
            style: TextStyle(color: kTextSecondary),
          ),
          const SizedBox(height: 32),

          // ── Stats Cards ──
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _buildStatCard(
                  title: 'Total Products',
                  count: _stats['total']!,
                  icon: Icons.inventory_2_outlined,
                  color: kPrimaryColor,
                ),
                _buildStatCard(
                  title: 'Active Products',
                  count: _stats['active']!,
                  icon: Icons.check_circle_outline,
                  color: kSuccessColor,
                ),
                _buildStatCard(
                  title: 'Inactive Products',
                  count: _stats['inactive']!,
                  icon: Icons.cancel_outlined,
                  color: kWarningColor,
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Helper to build a single stat card
  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon with colored background
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),

          // Count number
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),

          // Label
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: kTextSecondary),
          ),
        ],
      ),
    );
  }
}
