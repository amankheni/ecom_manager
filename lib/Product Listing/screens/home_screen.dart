// ============================================================
// screens/home_screen.dart
// Main app shell — sidebar + page content
// Production & Inventory module added
// ============================================================

import 'package:ecom_manager/Inventory%20Managment/Screen/cloth_purchase_screen.dart';
import 'package:ecom_manager/Inventory%20Managment/Screen/inventory_screen.dart';
import 'package:ecom_manager/Inventory%20Managment/Screen/print_job_screen.dart';
import 'package:ecom_manager/Inventory%20Managment/Screen/production_pipeline_screen.dart';
import 'package:ecom_manager/Inventory%20Managment/Screen/stitch_job_screen.dart';
import 'package:ecom_manager/widgets/sidebar.dart';
import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'products_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Pages mapped to sidebar menu index
  // Keep this in sync with AppSidebar menu items
  final List<Widget> _pages = [
    const DashboardScreen(), // 0 - Product Dashboard
    const ProductsScreen(), // 1 - Product Master
    const ClothPurchaseScreen(), // 2 - Cloth Purchase
    const PrintJobScreen(), // 3 - Digital Print
    const StitchJobScreen(), // 4 - Stitching
    const InventoryScreen(), // 5 - Ready Stock
    const ProductionPipelineScreen(), // 6 production_pipeline
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ── Left Sidebar ──
          AppSidebar(
            selectedIndex: _selectedIndex,
            onItemTap: (index) => setState(() => _selectedIndex = index),
          ),

          // ── Main Content Area ──
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}

// ── SIDEBAR MENU ITEMS ────────────────────────────────────────
// Add these items to your AppSidebar widget's menu list.
// Indices must match _pages list above.
//
// Index 0: Dashboard      (icon: Icons.dashboard_outlined)
// Index 1: Products       (icon: Icons.inventory_outlined)
// ─── Production section header ───
// Index 2: Cloth Purchase (icon: Icons.receipt_long_outlined)
// Index 3: Digital Print  (icon: Icons.print_outlined)
// Index 4: Stitching      (icon: Icons.content_cut_outlined)
// Index 5: Ready Stock    (icon: Icons.warehouse_outlined)
