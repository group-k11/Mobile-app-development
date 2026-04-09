import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constants.dart';

class SalesBarChart extends StatelessWidget {
  final Map<String, double> data;
  final String title;

  const SalesBarChart({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState();
    }

    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    final entries = data.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading3),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '₹${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < entries.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              entries[index].key,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue > 0 ? maxValue / 4 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                barGroups: entries.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value,
                        color: AppColors.chartColors[
                            entry.key % AppColors.chartColors.length],
                        width: entries.length > 10 ? 8 : 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading3),
          const SizedBox(height: 40),
          const Center(
            child: Column(
              children: [
                Icon(Icons.bar_chart, size: 48, color: AppColors.divider),
                SizedBox(height: 8),
                Text('No sales data yet', style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class TopProductsChart extends StatelessWidget {
  final Map<String, int> data;

  const TopProductsChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.cardDecoration,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Selling Products', style: AppTextStyles.heading3),
            SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Icon(Icons.pie_chart, size: 48, color: AppColors.divider),
                  SizedBox(height: 8),
                  Text('No sales data yet', style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      );
    }

    final entries = data.entries.toList();
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Selling Products', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                // Pie chart
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: entries.asMap().entries.map((entry) {
                        final percentage = (entry.value.value / total) * 100;
                        return PieChartSectionData(
                          value: entry.value.value.toDouble(),
                          title: '${percentage.toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          color: AppColors.chartColors[
                              entry.key % AppColors.chartColors.length],
                          radius: 60,
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 25,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Legend
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entries.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.chartColors[
                                  entry.key % AppColors.chartColors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 100,
                            child: Text(
                              entry.value.key,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
