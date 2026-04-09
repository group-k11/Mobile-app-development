import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: AppDecorations.cardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name + Category
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTextStyles.heading3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _buildCategoryChip(),
                      ],
                    ),
                  ),
                  if (showActions) ...[
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.primaryLight),
                        onPressed: onEdit,
                        tooltip: 'Edit',
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error),
                        onPressed: onDelete,
                        tooltip: 'Delete',
                      ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Price and Stock Row
              Row(
                children: [
                  _buildInfoChip(
                    Icons.sell_outlined,
                    formatCurrency(product.sellingPrice),
                    AppColors.accent,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.inventory_2_outlined,
                    'Stock: ${product.quantity}',
                    product.isLowStock ? AppColors.error : AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  if (product.barcode.isNotEmpty)
                    _buildInfoChip(
                      Icons.qr_code,
                      product.barcode.length > 10
                          ? '${product.barcode.substring(0, 10)}…'
                          : product.barcode,
                      AppColors.textSecondary,
                    ),
                ],
              ),

              // Alert badges
              if (product.isLowStock ||
                  product.isExpiringSoon ||
                  product.isExpired ||
                  product.isDeadStock) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (product.isExpired)
                      _buildAlertBadge('EXPIRED', AppColors.error),
                    if (product.isExpiringSoon && !product.isExpired)
                      _buildAlertBadge(
                        'Expires in ${daysUntilExpiry(product.expiryDate)}d',
                        AppColors.warning,
                      ),
                    if (product.isLowStock)
                      _buildAlertBadge('Low Stock', AppColors.error),
                    if (product.isDeadStock)
                      _buildAlertBadge('Dead Stock', Colors.grey),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        product.category,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.primaryLight,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAlertBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
