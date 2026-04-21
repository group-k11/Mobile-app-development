import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'add_product_screen.dart';
import 'cart_screen.dart';

/// Barcode scanner screen.
/// Flow: Scan → Fetch from Firestore → Show "Product retrieved from database" → Add to Cart.
/// If not found → Navigate to AddProductScreen with barcode prefilled.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isProcessing = false;

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;
    setState(() => _isProcessing = true);
    _lookupProduct(barcode);
  }

  Future<void> _lookupProduct(String barcode) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (!mounted) return;

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        _showProductDialog(
          docId: doc.id,
          name: data['name'] ?? 'Unknown',
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          costPrice: (data['costPrice'] as num?)?.toDouble() ?? 0.0,
          barcode: barcode,
          quantity: (data['quantity'] as num?)?.toInt() ?? 0,
        );
      } else {
        _showNotFoundDialog(barcode);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  void _showProductDialog({
    required String docId,
    required String name,
    required double price,
    required double costPrice,
    required String barcode,
    required int quantity,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Product Found'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Research paper terminology: database retrieval confirmation ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: const [
                Icon(Icons.storage, color: Colors.blue, size: 16),
                SizedBox(width: 6),
                Text(
                  'Product retrieved from database',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            _infoRow('Name', name),
            const SizedBox(height: 8),
            _infoRow('Price', '₹${price.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _infoRow('Barcode', barcode),
            const SizedBox(height: 8),
            _infoRow('In Stock', '$quantity'),
            if (quantity == 0) ...[
              const SizedBox(height: 8),
              const Text('⚠ Out of Stock!',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: quantity > 0
                ? () {
                    CartScreen.cartItems.add({
                      'docId': docId,
                      'name': name,
                      'price': price,
                      'costPrice': costPrice,
                      'barcode': barcode,
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name added to cart!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Add to Cart'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Not Found'),
          ],
        ),
        content: Text(
          'No product found with barcode:\n"$barcode"\n\nWould you like to add this product?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddProductScreen(prefilledBarcode: barcode),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA6),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(flex: 3, child: MobileScanner(onDetect: _onBarcodeDetected)),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: const Color(0xFF1E3A5F),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isProcessing ? Icons.hourglass_top : Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isProcessing ? 'Querying database...' : 'Point camera at a barcode',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
