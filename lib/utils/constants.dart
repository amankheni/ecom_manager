// ============================================================
// utils/constants.dart
// App-wide constants, colors, and theme configuration
// ============================================================

import 'package:flutter/material.dart';

// ── APP COLORS ───────────────────────────────────────────────
const Color kPrimaryColor = Color(0xFF1E3A5F); // Dark blue
const Color kAccentColor = Color(0xFF2E86AB); // Medium blue
const Color kSuccessColor = Color(0xFF27AE60); // Green
const Color kErrorColor = Color(0xFFE74C3C); // Red
const Color kWarningColor = Color(0xFFF39C12); // Orange
const Color kBgColor = Color(0xFFF5F6FA); // Light grey background
const Color kCardColor = Colors.white;
const Color kTextPrimary = Color(0xFF2C3E50);
const Color kTextSecondary = Color(0xFF7F8C8D);

// ── APP THEME ────────────────────────────────────────────────
ThemeData getAppTheme() {
  return ThemeData(
    primaryColor: kPrimaryColor,
    scaffoldBackgroundColor: kBgColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimaryColor,
      primary: kPrimaryColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: kCardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    useMaterial3: true,
  );
}

// ── HELPER: Show snackbar easily ─────────────────────────────
void showSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? kErrorColor : kSuccessColor,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ── HELPER: Show confirmation dialog ─────────────────────────
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Delete',
  Color confirmColor = kErrorColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
          child: Text(confirmText, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  return result ?? false;
}
