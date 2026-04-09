import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/sales_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/inventory_alert_widget.dart';
import '../widgets/sales_chart_widget.dart';
import '../widgets/sync_indicator_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, double> _weeklySales = {};
  Map<String, int> _topProducts = {};
  bool _isLoadingCharts = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);

    await productProvider.loadProducts();
    await salesProvider.loadSales();
    await salesProvider.loadAllSales();

    // Try to sync pending offline sales
    await salesProvider.syncOfflineSales();

    setState(() {
      _isLoadingCharts = true;
    });

    try {
      _weeklySales = await salesProvider.getWeeklySales();
      _topProducts = await salesProvider.getTopSellingProducts();
    } catch (e) {
      // Silently handle chart data errors
    }

    if (mounted) {
      setState(() {
        _isLoadingCharts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final salesProvider = Provider.of<SalesProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.only(left: 20, bottom: 16),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${getGreeting()} 👋',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      authProvider.currentUser?.name ?? 'Store Owner',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                // Sync indicator
                if (salesProvider.pendingSyncCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: SyncIndicatorWidget(
                      pendingCount: salesProvider.pendingSyncCount,
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final count = await salesProvider.syncOfflineSales();
                        messenger.showSnackBar(
                            SnackBar(
                              content: Text(count > 0
                                  ? '$count sales synced!'
                                  : 'No pending sales to sync'),
                              backgroundColor: count > 0
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          );
                      },
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadData,
                ),
              ],
            ),

            // Stats Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Products',
                            '${productProvider.totalProducts}',
                            Icons.inventory_2_outlined,
                            AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Today\'s Sales',
                            formatCurrencyCompact(salesProvider.todayTotal),
                            Icons.point_of_sale,
                            AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Low Stock',
                            '${productProvider.lowStockProducts.length}',
                            Icons.warning_amber_rounded,
                            productProvider.lowStockProducts.isEmpty
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Out of Stock',
                            '${productProvider.outOfStockProducts.length}',
                            Icons.remove_shopping_cart_outlined,
                            productProvider.outOfStockProducts.isEmpty
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Alerts Section
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Inventory Alerts', style: AppTextStyles.heading3),
                  ),
                  InventoryAlertWidget(
                    lowStockProducts: productProvider.lowStockProducts,
                    expiringSoonProducts: productProvider.expiringSoonProducts,
                    deadStockProducts: productProvider.deadStockProducts,
                  ),
                ],
              ),
            ),

            // Weekly Sales Chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isLoadingCharts
                    ? const Center(child: CircularProgressIndicator())
                    : SalesBarChart(
                        data: _weeklySales,
                        title: 'Weekly Sales',
                      ),
              ),
            ),

            // Top Products Chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _isLoadingCharts
                    ? const SizedBox()
                    : TopProductsChart(data: _topProducts),
              ),
            ),

            // Bottom spacer for bottom nav
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
