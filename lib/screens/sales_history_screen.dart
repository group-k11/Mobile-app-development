import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SalesProvider>(context, listen: false).loadAllSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    final salesProvider = Provider.of<SalesProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Sales History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: salesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : salesProvider.sales.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('No sales yet', style: AppTextStyles.heading3),
                      const SizedBox(height: 8),
                      const Text(
                        'Sales will appear here after transactions',
                        style: AppTextStyles.bodySecondary,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => salesProvider.loadAllSales(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: salesProvider.sales.length,
                    itemBuilder: (context, index) {
                      final sale = salesProvider.sales[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: AppDecorations.cardDecoration,
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          childrenPadding: const EdgeInsets.fromLTRB(
                              16, 0, 16, 16),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.receipt_outlined,
                                color: AppColors.accent),
                          ),
                          title: Text(
                            formatCurrency(sale.totalAmount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatDateTime(sale.timestamp),
                                style: AppTextStyles.caption,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      sale.paymentMethod,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.primaryLight,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${sale.totalItems} items',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          children: [
                            const Divider(),
                            ...sale.items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.productName,
                                        style: AppTextStyles.body,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '×${item.quantity}',
                                      style: AppTextStyles.bodySecondary,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      formatCurrency(item.total),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
