import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/sales_chart_widget.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, double> _dailySales = {};
  Map<String, double> _weeklySales = {};
  Map<String, double> _monthlySales = {};
  Map<String, int> _topProducts = {};
  Map<String, int> _leastProducts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    await salesProvider.loadAllSales();

    try {
      _dailySales = await salesProvider.getDailySales();
      _weeklySales = await salesProvider.getWeeklySales();
      _monthlySales = await salesProvider.getMonthlySales();
      _topProducts = await salesProvider.getTopSellingProducts();
      _leastProducts = await salesProvider.getLeastSellingProducts();
    } catch (e) {
      // Handle errors
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesProvider = Provider.of<SalesProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Week'),
            Tab(text: 'Month'),
            Tab(text: 'Products'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Daily Tab
                _buildDailyTab(salesProvider),

                // Weekly Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SalesBarChart(
                        data: _weeklySales,
                        title: 'This Week\'s Sales',
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryCard(
                        'Weekly Total',
                        _weeklySales.values.fold(0.0, (a, b) => a + b),
                        icon: Icons.calendar_view_week,
                      ),
                    ],
                  ),
                ),

                // Monthly Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SalesBarChart(
                        data: _monthlySales,
                        title: 'Last 30 Days Sales',
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryCard(
                        'Monthly Total',
                        _monthlySales.values.fold(0.0, (a, b) => a + b),
                        icon: Icons.calendar_month,
                      ),
                    ],
                  ),
                ),

                // Products Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TopProductsChart(data: _topProducts),
                      const SizedBox(height: 16),
                      _buildTopProductsList(),
                      const SizedBox(height: 16),
                      _buildLeastProductsList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDailyTab(SalesProvider salesProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Today's summary cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Today\'s Revenue',
                  formatCurrency(salesProvider.todayTotal),
                  Icons.attach_money,
                  AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Sales Count',
                  '${salesProvider.todaySaleCount}',
                  Icons.receipt_long,
                  AppColors.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hourly breakdown
          if (_dailySales.isNotEmpty) ...[
            SalesBarChart(
              data: _dailySales,
              title: 'Today\'s Sales by Hour',
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(32),
              decoration: AppDecorations.cardDecoration,
              child: Column(
                children: [
                  Icon(Icons.hourglass_empty,
                      size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  const Text(
                    'No sales recorded today',
                    style: AppTextStyles.bodySecondary,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Pending sync info
          if (salesProvider.pendingSyncCount > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${salesProvider.pendingSyncCount} sales pending offline sync',
                      style: const TextStyle(
                          color: AppColors.warning, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double total, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.cardDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodySecondary),
              const SizedBox(height: 4),
              Text(
                formatCurrency(total),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon ?? Icons.trending_up,
                color: AppColors.accent, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsList() {
    if (_topProducts.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.success, size: 20),
              SizedBox(width: 8),
              Text('Top Selling Products', style: AppTextStyles.heading3),
            ],
          ),
          const SizedBox(height: 12),
          ..._topProducts.entries.toList().asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final product = entry.value;
            return _buildProductRankRow(rank, product.key, product.value,
                isTop: true);
          }),
        ],
      ),
    );
  }

  Widget _buildLeastProductsList() {
    if (_leastProducts.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_down, color: AppColors.warning, size: 20),
              SizedBox(width: 8),
              Text('Least Selling Products', style: AppTextStyles.heading3),
            ],
          ),
          const SizedBox(height: 12),
          ..._leastProducts.entries.toList().asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final product = entry.value;
            return _buildProductRankRow(rank, product.key, product.value,
                isTop: false);
          }),
        ],
      ),
    );
  }

  Widget _buildProductRankRow(int rank, String name, int count,
      {bool isTop = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? (isTop
                          ? AppColors.chartColors[rank - 1]
                          : AppColors.warning)
                      .withValues(alpha: 0.2)
                  : AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: rank <= 3
                    ? (isTop
                        ? AppColors.chartColors[rank - 1]
                        : AppColors.warning)
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name,
                style: AppTextStyles.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Text(
            '$count sold',
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}
