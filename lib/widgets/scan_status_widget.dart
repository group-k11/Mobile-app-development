import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Animated overlay showing scan progress status.
enum ScanStatus {
  idle,
  searching,
  found,
  fetching,
  notFound,
}

class ScanStatusWidget extends StatelessWidget {
  final ScanStatus status;
  final String? productName;
  final String? productPrice;
  final VoidCallback? onAddToCart;
  final VoidCallback? onAddManually;

  const ScanStatusWidget({
    super.key,
    required this.status,
    this.productName,
    this.productPrice,
    this.onAddToCart,
    this.onAddManually,
  });

  @override
  Widget build(BuildContext context) {
    if (status == ScanStatus.idle) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildContent(),
    );
  }

  Color get _backgroundColor {
    switch (status) {
      case ScanStatus.found:
        return const Color(0xFF1B5E20);
      case ScanStatus.notFound:
        return const Color(0xFFE65100);
      case ScanStatus.fetching:
        return const Color(0xFF0D47A1);
      case ScanStatus.searching:
        return const Color(0xFF37474F);
      default:
        return Colors.transparent;
    }
  }

  Widget _buildContent() {
    switch (status) {
      case ScanStatus.searching:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Searching local inventory...',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        );

      case ScanStatus.fetching:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Fetching product data...',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        );

      case ScanStatus.found:
        return Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    productName ?? 'Product Found',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (productPrice != null)
                    Text(
                      productPrice!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            if (onAddToCart != null)
              ElevatedButton.icon(
                onPressed: onAddToCart,
                icon: const Icon(Icons.add_shopping_cart, size: 16),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.success,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        );

      case ScanStatus.notFound:
        return Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Product not found — Add manually',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            if (onAddManually != null)
              ElevatedButton(
                onPressed: onAddManually,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.warning,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
                child: const Text('Add'),
              ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
