import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Displays all products from Firestore with smart status tags.
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  List<Widget> _getStatusTags(Map<String, dynamic> data) {
    final qty = (data['quantity'] as num?)?.toInt() ?? 0;
    final lastSold = (data['lastSoldDate'] as Timestamp?)?.toDate();
    final expiryTs = (data['expiryDate'] as Timestamp?)?.toDate();
    final tags = <Widget>[];
    if (qty == 0) {
      tags.add(_tag('Out of Stock', Colors.red));
    } else if (qty < 5) {
      tags.add(_tag('Threshold-based Stock Alert', Colors.orange));
    }
    if (qty < 3) tags.add(_tag('Reorder Recommended', const Color(0xFF4A90D9)));
    if (lastSold != null && DateTime.now().difference(lastSold).inDays >= 30) {
      tags.add(_tag('Inactivity-based Detection', Colors.grey));
    }
    if (expiryTs != null) {
      final now = DateTime.now();
      if (expiryTs.isBefore(now)) {
        tags.add(_tag('Expired', Colors.red.shade900));
      } else if (expiryTs.difference(now).inDays <= 7) {
        tags.add(_tag('Expiring Soon', Colors.deepOrange));
      }
    }
    return tags;
  }

  Widget _tag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Products'),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No products added yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unknown';
              final price = (data['price'] as num?)?.toDouble() ?? 0.0;
              final costPrice = (data['costPrice'] as num?)?.toDouble() ?? 0.0;
              final barcode = data['barcode'] ?? 'N/A';
              final quantity = (data['quantity'] as num?)?.toInt() ?? 0;
              final expiryTs = (data['expiryDate'] as Timestamp?)?.toDate();
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFF1E3A5F),
                          child: Icon(Icons.shopping_bag, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('Barcode: $barcode', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹${price.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00BFA6))),
                            Text('Qty: $quantity', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      ]),
                      if (costPrice > 0 || expiryTs != null) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          const SizedBox(width: 52),
                          if (costPrice > 0)
                            Text('Cost: ₹${costPrice.toStringAsFixed(2)}  •  Profit: ₹${(price - costPrice).toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const Spacer(),
                          if (expiryTs != null)
                            Text('Exp: ${expiryTs.day}/${expiryTs.month}/${expiryTs.year}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ]),
                      ],
                      if (_getStatusTags(data).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(children: _getStatusTags(data)),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
