import 'package:flutter/material.dart';

/// System Flow Screen — shows how ShelfSense works end to end.
/// Simple Text/Card widgets only — no animations, no complexity.
class SystemFlowScreen extends StatelessWidget {
  const SystemFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Each step: icon, title, description
    final steps = [
      {
        'icon': Icons.add_box,
        'title': '1. Add Product',
        'desc': 'Enter product name, selling price, cost price, barcode, quantity and expiry date. Data is stored in Firebase Firestore.',
        'color': const Color(0xFF1E3A5F),
      },
      {
        'icon': Icons.qr_code_scanner,
        'title': '2. Scan Barcode',
        'desc': 'Camera scans the barcode. The app queries Firestore by barcode and retrieves the product from the database.',
        'color': const Color(0xFF4A90D9),
      },
      {
        'icon': Icons.shopping_cart,
        'title': '3. Add to Cart',
        'desc': 'If product is found, user taps "Add to Cart". Multiple products can be scanned and added.',
        'color': const Color(0xFF00BFA6),
      },
      {
        'icon': Icons.payment,
        'title': '4. Checkout',
        'desc': 'Checkout records the sale in Firestore and calculates total revenue and profit for the transaction.',
        'color': Colors.green,
      },
      {
        'icon': Icons.inventory,
        'title': '5. Update Stock',
        'desc': 'Each product\'s quantity is decremented by 1. lastSoldDate is updated to now for dead stock detection.',
        'color': Colors.orange,
      },
      {
        'icon': Icons.dashboard,
        'title': '6. Dashboard Alerts',
        'desc': 'Dashboard reads all products in real-time and shows Threshold-based Stock Alerts, Inactivity-based Stock Detection, and Expiry warnings by product name.',
        'color': Colors.purple,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Flow'),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Card(
            color: const Color(0xFF1E3A5F),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  Icon(Icons.account_tree, color: Colors.white, size: 36),
                  SizedBox(height: 8),
                  Text(
                    'ShelfSense — Intelligent Retail System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'End-to-end workflow using Flutter + Firebase Firestore',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Step cards with connector line effect
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            final color = step['color'] as Color;
            return Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: color,
                          child: Icon(step['icon'] as IconData,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step['title'] as String,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: color),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                step['desc'] as String,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Arrow between steps (except last)
                if (i < steps.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Icon(Icons.arrow_downward, color: Colors.grey),
                  ),
              ],
            );
          }),

          const SizedBox(height: 16),

          // Tech stack note
          Card(
            color: Colors.grey.shade100,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Technology Stack',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 8),
                  Text('• Flutter (Dart) — Cross-platform mobile UI'),
                  Text('• Firebase Firestore — Cloud NoSQL database'),
                  Text('• mobile_scanner — Barcode detection via camera'),
                  Text('• setState — Lightweight state management'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
