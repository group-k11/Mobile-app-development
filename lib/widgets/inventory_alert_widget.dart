import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class InventoryAlertWidget extends StatelessWidget {
  final List<ProductModel> lowStockProducts;
  final List<ProductModel> expiringSoonProducts;
  final List<ProductModel> deadStockProducts;

  const InventoryAlertWidget({
    super.key,
    required this.lowStockProducts,
    required this.expiringSoonProducts,
    required this.deadStockProducts,
  });

  @override
  Widget build(BuildContext context) {
    final hasAlerts = lowStockProducts.isNotEmpty ||
        expiringSoonProducts.isNotEmpty ||
        deadStockProducts.isNotEmpty;

    if (!hasAlerts) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha:0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'All inventory levels are healthy!',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Low Stock Alerts
        if (lowStockProducts.isNotEmpty)
          _buildAlertSection(
            icon: Icons.warning_amber_rounded,
            title: 'Low Stock (${lowStockProducts.length})',
            color: AppColors.error,
            items: lowStockProducts.map((p) =>
                'Low Stock: ${p.name} only ${p.quantity} left').toList(),
          ),

        // Expiry Alerts
        if (expiringSoonProducts.isNotEmpty)
          _buildAlertSection(
            icon: Icons.schedule,
            title: 'Expiring Soon (${expiringSoonProducts.length})',
            color: AppColors.warning,
            items: expiringSoonProducts.map((p) {
              final days = daysUntilExpiry(p.expiryDate);
              return '${p.name} expires in $days days';
            }).toList(),
          ),

        // Dead Stock Alerts
        if (deadStockProducts.isNotEmpty)
          _buildAlertSection(
            icon: Icons.remove_shopping_cart,
            title: 'Dead Stock (${deadStockProducts.length})',
            color: Colors.grey,
            items: deadStockProducts.map((p) =>
                '${p.name} — not sold in 30+ days').toList(),
          ),
      ],
    );
  }

  Widget _buildAlertSection({
    required IconData icon,
    required String title,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.2)),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        childrenPadding:
            const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        children: items.take(5).map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(Icons.circle, size: 6, color: color.withValues(alpha:0.6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      color: color.withValues(alpha:0.8),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
