import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Cart screen with checkout — records sale, updates stock, shows profit.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  /// Global cart list shared between ScanScreen and CartScreen.
  static final List<Map<String, dynamic>> cartItems = [];

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isCheckingOut = false;

  double get _totalPrice {
    double total = 0;
    for (final item in CartScreen.cartItems) {
      total += (item['price'] as double?) ?? 0;
    }
    return total;
  }

  double get _totalProfit {
    double profit = 0;
    for (final item in CartScreen.cartItems) {
      final sell = (item['price'] as double?) ?? 0;
      final cost = (item['costPrice'] as double?) ?? 0;
      profit += (sell - cost);
    }
    return profit;
  }

  void _removeItem(int index) {
    setState(() => CartScreen.cartItems.removeAt(index));
  }

  void _clearCart() {
    setState(() => CartScreen.cartItems.clear());
  }

  Future<void> _checkout() async {
    if (CartScreen.cartItems.isEmpty) return;
    setState(() => _isCheckingOut = true);

    try {
      final firestore = FirebaseFirestore.instance;

      // Record sale with profit info
      await firestore.collection('sales').add({
        'totalAmount': _totalPrice,
        'totalProfit': _totalProfit,
        'itemCount': CartScreen.cartItems.length,
        'items': CartScreen.cartItems
            .map((item) => {
                  'name': item['name'],
                  'price': item['price'],
                  'costPrice': item['costPrice'] ?? 0,
                  'barcode': item['barcode'],
                })
            .toList(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update each product stock and lastSoldDate
      for (final item in CartScreen.cartItems) {
        final docId = item['docId'] as String?;
        if (docId != null) {
          await firestore.collection('products').doc(docId).update({
            'quantity': FieldValue.increment(-1),
            'lastSoldDate': Timestamp.fromDate(DateTime.now()),
          });
        }
      }

      // Capture totals BEFORE clearing cart
      final savedTotal = _totalPrice;
      final savedProfit = _totalProfit;

      if (!mounted) return;
      setState(() => CartScreen.cartItems.clear());

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text('Sale Complete!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Total: ₹${savedTotal.toStringAsFixed(2)}'),
              Text('Profit: ₹${savedProfit.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Color(0xFF00BFA6), fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e')),
      );
    }

    if (mounted) setState(() => _isCheckingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        actions: [
          if (CartScreen.cartItems.isNotEmpty)
            IconButton(
              onPressed: _clearCart,
              icon: const Icon(Icons.delete_sweep),
            ),
        ],
      ),
      body: CartScreen.cartItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Your cart is empty',
                      style: TextStyle(fontSize: 20, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Scan products to add them here',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: CartScreen.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = CartScreen.cartItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF00BFA6),
                            child: Icon(Icons.shopping_bag, color: Colors.white),
                          ),
                          title: Text(item['name'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Barcode: ${item['barcode']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('₹${(item['price'] as double).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00BFA6))),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _removeItem(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Bottom checkout section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total (${CartScreen.cartItems.length} items):',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('₹${_totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF00BFA6))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Est. Profit:', style: TextStyle(color: Colors.grey)),
                          Text('₹${_totalProfit.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isCheckingOut ? null : _checkout,
                          icon: _isCheckingOut
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.payment),
                          label: Text(_isCheckingOut ? 'Processing...' : 'Checkout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BFA6),
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(fontSize: 18),
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
}
