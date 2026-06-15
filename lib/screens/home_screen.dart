// ============================================================
// screens/home_screen.dart
// Main app shell after login - contains sidebar + page content
// Now includes Production & Inventory module pages
// ============================================================

import 'package:ecom_manager/Inventry%20managemnet/Screens/fabric_purchase_screen.dart';
import 'package:ecom_manager/Inventry%20managemnet/Screens/inventory_dashboard_screen.dart';
import 'package:ecom_manager/Inventry%20managemnet/Screens/printing_screen.dart';
import 'package:ecom_manager/Inventry%20managemnet/Screens/production_screen.dart';
import 'package:ecom_manager/Inventry%20managemnet/Screens/ready_stock_screen.dart';
import 'package:ecom_manager/Inventry%20managemnet/Screens/reports_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
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
  final List<Widget> _pages = [
    const DashboardScreen(), // 0 - Product Dashboard
    const ProductsScreen(), // 1 - Product Master
    const InventoryDashboardScreen(), // 2 - Inventory Dashboard
    const FabricPurchaseScreen(), // 3 - Gray Fabric Purchase
    const PrintingScreen(), // 4 - Digital Printing
    const ProductionScreen(), // 5 - Production (Stitching)
    const ReadyStockScreen(), // 6 - Ready Stock
    const ReportsScreen(), // 7 - Reports
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
