// ============================================================
// widgets/sidebar.dart
// Modern left sidebar — clean sections, icons, mobile-aware
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/auth_provider.dart';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTap;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final isNarrow = MediaQuery.of(context).size.width < 768;

    // On mobile: icon-only compact sidebar (64px), on desktop: full (240px)
    if (isNarrow) {
      return _CompactSidebar(
        selectedIndex: selectedIndex,
        onItemTap: onItemTap,
        onLogout: () => _handleLogout(context, authProvider),
      );
    }

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a237e), Color(0xFF283593)],
        ),
      ),
      child: Column(
        children: [
          // ── Logo ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'E-Commerce',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        'Admin Panel',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── User Info ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    (user?.name ?? 'A')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Admin',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.role ?? 'Administrator',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Menu ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('PRODUCTS'),
                  _menuItem(Icons.dashboard_rounded, 'Dashboard', 0),
                  _menuItem(Icons.inventory_2_rounded, 'Product Master', 1),

                  const SizedBox(height: 8),
                  _divider(),

                  _sectionHeader('PRODUCTION'),
                  _menuItem(Icons.bar_chart_rounded, 'Inventory Dashboard', 2),
                  _menuItem(Icons.shopping_bag_outlined, 'Fabric Purchase', 3),
                  _menuItem(Icons.print_rounded, 'Digital Printing', 4),
                  _menuItem(
                    Icons.precision_manufacturing_outlined,
                    'Production',
                    5,
                  ),
                  _menuItem(Icons.checkroom_rounded, 'Ready Stock', 6),
                  _menuItem(Icons.summarize_rounded, 'Reports', 7),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Logout ──
          Container(
            margin: const EdgeInsets.all(12),
            child: InkWell(
              onTap: () => _handleLogout(context, authProvider),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.white60, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _divider() =>
      const Divider(color: Colors.white12, indent: 8, endIndent: 8, height: 1);

  Widget _menuItem(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onItemTap(index),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: Colors.white.withOpacity(0.15))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, dynamic authProvider) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      confirmColor: kPrimaryColor,
    );
    if (confirm) authProvider.logout();
  }
}

// ── Compact sidebar for mobile/narrow screens ──
class _CompactSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTap;
  final VoidCallback onLogout;

  const _CompactSidebar({
    required this.selectedIndex,
    required this.onItemTap,
    required this.onLogout,
  });

  static const _items = [
    (Icons.dashboard_rounded, 'Dashboard', 0),
    (Icons.inventory_2_rounded, 'Products', 1),
    (Icons.bar_chart_rounded, 'Inventory', 2),
    (Icons.shopping_bag_outlined, 'Fabric', 3),
    (Icons.print_rounded, 'Printing', 4),
    (Icons.precision_manufacturing_outlined, 'Production', 5),
    (Icons.checkroom_rounded, 'Stock', 6),
    (Icons.summarize_rounded, 'Reports', 7),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a237e), Color(0xFF283593)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Icon(Icons.store_rounded, color: Colors.white, size: 26),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _items.map((item) {
                  final isSelected = selectedIndex == item.$3;
                  return Tooltip(
                    message: item.$2,
                    preferBelow: false,
                    child: GestureDetector(
                      onTap: () => onItemTap(item.$3),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item.$1,
                          size: 20,
                          color: isSelected ? Colors.white : Colors.white54,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Tooltip(
            message: 'Logout',
            child: IconButton(
              onPressed: onLogout,
              icon: const Icon(
                Icons.logout_rounded,
                color: Colors.white54,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
