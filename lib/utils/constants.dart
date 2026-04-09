import 'package:flutter/material.dart';

// ─── App Info ──────────────────────────────────────────────
const String kAppName = 'ShelfSense';
const String kAppTagline = 'Smart Retail Inventory & POS';

// ─── Firestore Collections ─────────────────────────────────
const String kUsersCollection = 'users';
const String kProductsCollection = 'products';
const String kSalesCollection = 'sales';

// ─── Hive Box Names ────────────────────────────────────────
const String kProductCacheBox = 'product_cache';
const String kOfflineSalesBox = 'offline_sales';

// ─── Store Info ────────────────────────────────────────────
const String kDefaultStoreName = 'ShelfSense Store';

// ─── User Roles ────────────────────────────────────────────
const String kRoleOwner = 'owner';
const String kRoleStaff = 'staff';

// ─── Payment Methods ───────────────────────────────────────
const String kPaymentCash = 'Cash';
const String kPaymentUPI = 'UPI';
const String kPaymentCard = 'Card';

const List<String> kPaymentMethods = [kPaymentCash, kPaymentUPI, kPaymentCard];

// ─── Alert Thresholds ──────────────────────────────────────
const int kExpiryAlertDays = 7;
const int kDeadStockDays = 30;

// ─── Colors ────────────────────────────────────────────────
class AppColors {
  static const Color primary = Color(0xFF1E3A5F);
  static const Color primaryLight = Color(0xFF4A90D9);
  static const Color accent = Color(0xFF00BFA6);
  static const Color accentLight = Color(0xFF64FFDA);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color success = Color(0xFF66BB6A);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color cardShadow = Color(0x1A000000);

  // Chart colors
  static const List<Color> chartColors = [
    Color(0xFF4A90D9),
    Color(0xFF00BFA6),
    Color(0xFFFFA726),
    Color(0xFFE53935),
    Color(0xFF7E57C2),
    Color(0xFF42A5F5),
  ];
}

// ─── Text Styles ───────────────────────────────────────────
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

// ─── Decorations ───────────────────────────────────────────
class AppDecorations {
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(
        color: AppColors.cardShadow,
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  );

  static InputDecoration inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: AppColors.primaryLight) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surface,
    );
  }
}

// ─── Product Categories ────────────────────────────────────
const List<String> kProductCategories = [
  'Groceries',
  'Dairy',
  'Beverages',
  'Snacks',
  'Personal Care',
  'Household',
  'Stationery',
  'Electronics',
  'Clothing',
  'Other',
];
