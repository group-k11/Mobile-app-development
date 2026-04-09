import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sale_model.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/sales_provider.dart';
import '../services/receipt_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _selectedPaymentMethod = kPaymentCash;
  bool _isProcessing = false;

  Future<void> _confirmSale() async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (productProvider.isCartEmpty) return;

    setState(() => _isProcessing = true);

    // Build sale items
    final saleItems = productProvider.cart.map((cartItem) {
      return SaleItem(
        productId: cartItem.product.productId,
        productName: cartItem.product.name,
        quantity: cartItem.quantity,
        price: cartItem.product.sellingPrice,
      );
    }).toList();

    final sale = SaleModel(
      saleId: '',
      staffId: authProvider.currentUser?.userId ?? '',
      staffName: authProvider.currentUser?.name ?? '',
      items: saleItems,
      totalAmount: productProvider.cartTotal,
      paymentMethod: _selectedPaymentMethod,
      timestamp: DateTime.now(),
    );

    final completedSale = await salesProvider.createSale(sale);

    if (completedSale != null) {
      productProvider.clearCart();
      await productProvider.loadProducts(); // Refresh stock counts

      if (mounted) {
        _showSuccessDialog(completedSale, salesProvider.error != null);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              salesProvider.error ?? 'Failed to process sale. Please try again.'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(SaleModel sale, bool isOffline) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppColors.success, size: 56),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sale Complete!',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 8),
            Text(
              isOffline
                  ? 'Saved offline. Will sync when connected.'
                  : 'Transaction recorded successfully.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              formatCurrency(sale.totalAmount),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        actions: [
          // Generate Receipt
          TextButton.icon(
            onPressed: () async {
              await _generateAndShareReceipt(sale);
            },
            icon: const Icon(Icons.receipt_long, size: 18),
            label: const Text('Receipt'),
          ),
          // Share Receipt
          TextButton.icon(
            onPressed: () async {
              await _shareReceipt(sale);
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share'),
          ),
          // Done
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndShareReceipt(SaleModel sale) async {
    try {
      final pdfBytes = await ReceiptService.generateReceipt(
        sale: sale,
        storeName: kDefaultStoreName,
      );
      await ReceiptService.printReceipt(pdfBytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate receipt'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _shareReceipt(SaleModel sale) async {
    try {
      final pdfBytes = await ReceiptService.generateReceipt(
        sale: sale,
        storeName: kDefaultStoreName,
      );
      await ReceiptService.shareReceipt(pdfBytes, saleId: sale.saleId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share receipt'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final salesProvider = Provider.of<SalesProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Cart & Billing',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!productProvider.isCartEmpty)
            TextButton(
              onPressed: () => productProvider.clearCart(),
              child: const Text('Clear',
                  style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
      body: productProvider.isCartEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Your cart is empty',
                      style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan products to add them to cart',
                    style: AppTextStyles.bodySecondary,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Offline sync indicator
                if (salesProvider.pendingSyncCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    color: AppColors.warning.withValues(alpha: 0.15),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off,
                            color: AppColors.warning, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '${salesProvider.pendingSyncCount} sales pending sync',
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Cart Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: productProvider.cart.length,
                    itemBuilder: (context, index) {
                      final cartItem = productProvider.cart[index];
                      return _buildCartItemCard(
                          cartItem, index, productProvider);
                    },
                  ),
                ),

                // Bottom Billing Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Items:', style: AppTextStyles.body),
                          Text('${productProvider.cartItemCount}',
                              style: AppTextStyles.heading3),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount:',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            formatCurrency(productProvider.cartTotal),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Payment Method
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Payment Method:',
                            style: AppTextStyles.body),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: kPaymentMethods.map((method) {
                          final isSelected =
                              method == _selectedPaymentMethod;
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text(
                                  method,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedPaymentMethod = method;
                                  });
                                },
                                selectedColor: AppColors.primaryLight,
                                backgroundColor: AppColors.background,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Confirm Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              _isProcessing ? null : _confirmSale,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 3,
                          ),
                          child: _isProcessing
                              ? const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)
                              : Text(
                                  'Confirm Sale — ${formatCurrency(productProvider.cartTotal)}',
                                  style: AppTextStyles.button,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCartItemCard(
      CartItem cartItem, int index, ProductProvider productProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardDecoration,
      child: Row(
        children: [
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.product.name,
                  style: AppTextStyles.heading3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(cartItem.product.sellingPrice),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: () {
                    if (cartItem.quantity > 1) {
                      productProvider.updateCartItemQuantity(
                          index, cartItem.quantity - 1);
                    } else {
                      productProvider.removeFromCart(index);
                    }
                  },
                ),
                Text(
                  '${cartItem.quantity}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () {
                    productProvider.updateCartItemQuantity(
                        index, cartItem.quantity + 1);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Item total
          Column(
            children: [
              Text(
                formatCurrency(cartItem.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => productProvider.removeFromCart(index),
                child: const Icon(Icons.delete_outline,
                    color: AppColors.error, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
