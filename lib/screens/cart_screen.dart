import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/pdf_service.dart';

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
      final qty = (item['quantity'] as int?) ?? 1;
      total += ((item['price'] as double?) ?? 0) * qty;
    }
    return total;
  }

  double get _totalProfit {
    double profit = 0;
    for (final item in CartScreen.cartItems) {
      final qty = (item['quantity'] as int?) ?? 1;
      final sell = (item['price'] as double?) ?? 0;
      final cost = (item['costPrice'] as double?) ?? 0;
      profit += (sell - cost) * qty;
    }
    return profit;
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final item = CartScreen.cartItems[index];
      final currentQty = (item['quantity'] as int?) ?? 1;
      final newQty = currentQty + delta;
      if (newQty <= 0) {
        CartScreen.cartItems.removeAt(index);
      } else {
        item['quantity'] = newQty;
      }
    });
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
                  'quantity': item['quantity'] ?? 1,
                })
            .toList(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update each product stock and lastSoldDate
      for (final item in CartScreen.cartItems) {
        final docId = item['docId'] as String?;
        final qty = (item['quantity'] as int?) ?? 1;
        if (docId != null) {
          await firestore.collection('products').doc(docId).update({
            'quantity': FieldValue.increment(-qty),
            'lastSoldDate': Timestamp.fromDate(DateTime.now()),
          });
        }
      }

      // Capture totals AND cart snapshot BEFORE clearing — PDF uses this data
      final savedTotal = _totalPrice;
      final savedProfit = _totalProfit;
      final savedItems = List<Map<String, dynamic>>.from(CartScreen.cartItems);

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
            TextButton.icon(
              onPressed: () => PdfService.generatePdfBill(savedItems, savedTotal)
                  .then((pdf) => PdfService.previewOrSharePdf(pdf)),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('PDF'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
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
                          subtitle: Text('₹${((item['price'] as double) * (item['quantity'] ?? 1)).toStringAsFixed(2)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                                onPressed: () => _updateQuantity(index, -1),
                              ),
                              Text('${item['quantity'] ?? 1}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00BFA6)),
                                onPressed: () => _updateQuantity(index, 1),
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
                      Text('Total (${CartScreen.cartItems.fold<int>(0, (acc, i) => acc + ((i['quantity'] as int?) ?? 1))} items):',
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
