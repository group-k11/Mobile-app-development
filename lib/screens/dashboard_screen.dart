import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Dashboard — Sales Analytics Module with named product alerts.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('ShelfSense Dashboard'),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sales Analytics Module ──
            const Text(
              'Sales Analytics Module',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sales')
                  .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
                  .where('timestamp', isLessThan: Timestamp.fromDate(todayEnd))
                  .snapshots(),
              builder: (context, snapshot) {
                double revenue = 0, profit = 0;
                int items = 0, txns = 0;

                if (snapshot.hasData) {
                  txns = snapshot.data!.docs.length;
                  for (final doc in snapshot.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    revenue += (d['totalAmount'] as num?)?.toDouble() ?? 0;
                    profit += (d['totalProfit'] as num?)?.toDouble() ?? 0;
                    items += (d['itemCount'] as num?)?.toInt() ?? 0;
                  }
                }

                return Column(children: [
                  Row(children: [
                    Expanded(child: _card(Icons.currency_rupee, 'Revenue',
                        '₹${revenue.toStringAsFixed(0)}', const Color(0xFF00BFA6))),
                    const SizedBox(width: 10),
                    Expanded(child: _card(Icons.trending_up, 'Profit',
                        '₹${profit.toStringAsFixed(0)}', Colors.green)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _card(Icons.shopping_bag, 'Items Sold',
                        '$items', const Color(0xFF4A90D9))),
                    const SizedBox(width: 10),
                    Expanded(child: _card(Icons.receipt, 'Transactions',
                        '$txns', Colors.purple)),
                  ]),
                ]);
              },
            ),

            const SizedBox(height: 24),

            // ── Smart Product Alerts with product names ──
            const Text(
              'Intelligent Stock Alerts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Real-time alerts for each product',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Build a flat list of alert entries: {name, alertType, color}
                final alerts = <Map<String, dynamic>>[];

                for (final doc in snapshot.data!.docs) {
                  final d = doc.data() as Map<String, dynamic>;
                  final name = d['name'] ?? 'Unknown';
                  final qty = (d['quantity'] as num?)?.toInt() ?? 0;
                  final lastSold = (d['lastSoldDate'] as Timestamp?)?.toDate();
                  final expiry = (d['expiryDate'] as Timestamp?)?.toDate();

                  if (qty == 0) {
                    alerts.add({'name': name, 'label': 'Out of Stock', 'color': Colors.red, 'icon': Icons.error});
                  } else if (qty < 5) {
                    alerts.add({'name': name, 'label': 'Threshold-based Stock Alert', 'color': Colors.orange, 'icon': Icons.warning});
                  }
                  if (qty < 3 && qty > 0) {
                    alerts.add({'name': name, 'label': 'Reorder Recommended', 'color': const Color(0xFF4A90D9), 'icon': Icons.replay});
                  }
                  if (lastSold != null && DateTime.now().difference(lastSold).inDays >= 30) {
                    alerts.add({'name': name, 'label': 'Inactivity-based Stock Detection', 'color': Colors.grey, 'icon': Icons.inventory});
                  }
                  if (expiry != null) {
                    if (expiry.isBefore(DateTime.now())) {
                      alerts.add({'name': name, 'label': 'Expired', 'color': Colors.red.shade900, 'icon': Icons.event_busy});
                    } else if (expiry.difference(DateTime.now()).inDays <= 7) {
                      alerts.add({'name': name, 'label': 'Expiring Soon', 'color': Colors.deepOrange, 'icon': Icons.schedule});
                    }
                  }
                }

                if (alerts.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: const [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 12),
                        Text('All products are in good condition!',
                            style: TextStyle(color: Colors.green)),
                      ]),
                    ),
                  );
                }

                // Display each alert with product name
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    final color = alert['color'] as Color;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        leading: Icon(alert['icon'] as IconData, color: color),
                        title: Text(
                          alert['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          alert['label'] as String,
                          style: TextStyle(color: color, fontSize: 12),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(IconData icon, String label, String value, Color color) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ]),
      ),
    );
  }
}
