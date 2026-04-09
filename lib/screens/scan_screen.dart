import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../services/barcode_lookup_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/barcode_scanner_widget.dart';
import '../widgets/scan_status_widget.dart';
import 'add_product_screen.dart';
import 'cart_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isProcessing = false;
  String? _lastScannedBarcode;
  ScanStatus _scanStatus = ScanStatus.idle;
  String? _foundProductName;
  String? _foundProductPrice;

  Future<void> _onBarcodeScanned(String barcode) async {
    if (_isProcessing || barcode == _lastScannedBarcode) return;

    setState(() {
      _isProcessing = true;
      _lastScannedBarcode = barcode;
      _scanStatus = ScanStatus.searching;
    });

    // Haptic feedback on scan
    HapticFeedback.mediumImpact();

    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final product = await productProvider.findByBarcode(barcode);

    if (!mounted) return;

    if (product != null) {
      // Product found — show status and auto-add to cart
      final added = productProvider.addToCart(product);

      HapticFeedback.lightImpact();

      setState(() {
        _scanStatus = ScanStatus.found;
        _foundProductName = product.name;
        _foundProductPrice = formatCurrency(product.sellingPrice);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(added
              ? '${product.name} added to cart'
              : '${product.name} — not enough stock'),
          backgroundColor: added ? AppColors.success : AppColors.warning,
          duration: const Duration(seconds: 2),
          action: added
              ? SnackBarAction(
                  label: 'View Cart',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                )
              : null,
        ),
      );

      // Reset after delay to allow re-scanning
      await Future.delayed(const Duration(seconds: 2));
    } else {
      // Product NOT found — try API lookup
      setState(() => _scanStatus = ScanStatus.fetching);

      final barcodeInfo = await BarcodeLookupService.lookup(barcode);

      if (!mounted) return;

      if (barcodeInfo.hasData) {
        // API found data — go to add screen with pre-filled data
        setState(() => _scanStatus = ScanStatus.notFound);

        HapticFeedback.heavyImpact();

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          _navigateToAddProduct(barcodeInfo);
        }
      } else {
        // Nothing found anywhere — prompt manual entry
        setState(() => _scanStatus = ScanStatus.notFound);

        HapticFeedback.heavyImpact();

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          _navigateToAddProduct(BarcodeProductInfo(barcode: barcode));
        }
      }
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _lastScannedBarcode = null;
        _scanStatus = ScanStatus.idle;
        _foundProductName = null;
        _foundProductPrice = null;
      });
    }
  }

  void _navigateToAddProduct(BarcodeProductInfo info) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductScreen(
          product: null,
          initialBarcode: info.barcode,
          initialName: info.name,
          initialCategory: info.category,
          initialPrice: info.price,
          initialSupplier: info.supplier ?? info.brand,
          initialBrand: info.brand,
          initialDescription: info.description,
          initialImageUrl: info.imageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Barcode Scanner
          BarcodeScannerWidget(
            onBarcodeScanned: _onBarcodeScanned,
          ),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Manual entry button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton.icon(
                    onPressed: _showManualEntryDialog,
                    icon: const Icon(Icons.keyboard, color: Colors.white,
                        size: 18),
                    label: const Text('Manual Entry',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
                const Spacer(),
                // Cart badge
                if (!productProvider.isCartEmpty)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CartScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_cart,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '${productProvider.cartItemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Scan Status Overlay
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: ScanStatusWidget(
              status: _scanStatus,
              productName: _foundProductName,
              productPrice: _foundProductPrice,
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Barcode'),
        content: TextField(
          controller: controller,
          decoration: AppDecorations.inputDecoration(
            'Barcode Number',
            icon: Icons.qr_code,
          ),
          keyboardType: TextInputType.text,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final barcode = controller.text.trim();
              if (barcode.isNotEmpty) {
                Navigator.pop(ctx);
                _onBarcodeScanned(barcode);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
