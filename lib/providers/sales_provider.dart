import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/sale_model.dart';
import '../services/firestore_service.dart';
import '../services/sync_service.dart';

class SalesProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final SyncService _syncService = SyncService();
  final Uuid _uuid = const Uuid();

  List<SaleModel> _sales = [];
  List<SaleModel> _todaySales = [];
  bool _isLoading = false;
  String? _error;

  List<SaleModel> get sales => _sales;
  List<SaleModel> get todaySales => _todaySales;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SyncService get syncService => _syncService;

  // ─── Computed Values ──────────────────────────────────
  double get todayTotal =>
      _todaySales.fold(0, (sum, sale) => sum + sale.totalAmount);

  int get todaySaleCount => _todaySales.length;

  int get pendingSyncCount => _syncService.pendingCount;

  // ─── Initialize Sync Service ─────────────────────────
  Future<void> initializeSync() async {
    await _syncService.initialize();
  }

  // ─── Load Sales ──────────────────────────────────────
  Future<void> loadSales() async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      _todaySales =
          await _firestoreService.getSalesByDateRange(startOfDay, endOfDay);
      _error = null;
    } catch (e) {
      _error = 'Failed to load sales';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Load All Sales (for history) ─────────────────────
  Future<void> loadAllSales() async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));
      _sales = await _firestoreService.getSalesByDateRange(start, now);
      _error = null;
    } catch (e) {
      _error = 'Failed to load sales history';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Listen to Sales Stream ──────────────────────────
  void listenToSales() {
    _firestoreService.getSalesStream().listen((sales) {
      _sales = sales;
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      _todaySales =
          sales.where((s) => s.timestamp.isAfter(startOfDay)).toList();
      notifyListeners();
    });
  }

  // ─── Create Sale ─────────────────────────────────────
  /// Returns the saved SaleModel (with generated ID) for receipt generation,
  /// or null on failure.
  Future<SaleModel?> createSale(SaleModel sale) async {
    final saleId = sale.saleId.isEmpty ? _uuid.v4() : sale.saleId;
    final newSale = SaleModel(
      saleId: saleId,
      staffId: sale.staffId,
      staffName: sale.staffName,
      items: sale.items,
      totalAmount: sale.totalAmount,
      paymentMethod: sale.paymentMethod,
      timestamp: sale.timestamp,
    );

    try {
      await _firestoreService.createSale(newSale);
      await loadSales();
      return newSale;
    } catch (e) {
      // Offline — queue for later sync
      await _syncService.queueSale(newSale);
      _error = 'Sale saved offline. Will sync when connected.';
      notifyListeners();
      return newSale; // Still return the sale for receipt generation
    }
  }

  // ─── Sync Offline Sales ──────────────────────────────
  Future<int> syncOfflineSales() async {
    final count = await _syncService.syncPendingSales();
    if (count > 0) {
      await loadSales();
      notifyListeners();
    }
    return count;
  }

  // ─── Sales Analytics Helpers ──────────────────────────
  Future<Map<String, double>> getWeeklySales() async {
    final now = DateTime.now();
    final Map<String, double> weeklyData = {};

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));

      final daySales =
          await _firestoreService.getSalesByDateRange(start, end);
      final dayTotal =
          daySales.fold<double>(0, (sum, sale) => sum + sale.totalAmount);

      final dayLabel = _getDayLabel(start.weekday);
      weeklyData[dayLabel] = dayTotal;
    }

    return weeklyData;
  }

  Future<Map<String, double>> getMonthlySales() async {
    final now = DateTime.now();
    final Map<String, double> monthlyData = {};

    for (int i = 29; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));

      final daySales =
          await _firestoreService.getSalesByDateRange(start, end);
      final dayTotal =
          daySales.fold<double>(0, (sum, sale) => sum + sale.totalAmount);

      final dayLabel = '${day.day}/${day.month}';
      monthlyData[dayLabel] = dayTotal;
    }

    return monthlyData;
  }

  Future<Map<String, double>> getDailySales() async {
    final now = DateTime.now();
    final Map<String, double> hourlyData = {};

    final startOfDay = DateTime(now.year, now.month, now.day);
    final sales = await _firestoreService.getSalesByDateRange(startOfDay, now);

    for (final sale in sales) {
      final hourLabel = '${sale.timestamp.hour}:00';
      hourlyData[hourLabel] =
          (hourlyData[hourLabel] ?? 0) + sale.totalAmount;
    }

    return hourlyData;
  }

  Future<Map<String, int>> getTopSellingProducts() async {
    final Map<String, int> productCounts = {};

    for (final sale in _sales) {
      for (final item in sale.items) {
        productCounts[item.productName] =
            (productCounts[item.productName] ?? 0) + item.quantity;
      }
    }

    // Sort and take top 5
    final sorted = productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted.take(5));
  }

  Future<Map<String, int>> getLeastSellingProducts() async {
    final Map<String, int> productCounts = {};

    for (final sale in _sales) {
      for (final item in sale.items) {
        productCounts[item.productName] =
            (productCounts[item.productName] ?? 0) + item.quantity;
      }
    }

    // Sort ascending and take bottom 5
    final sorted = productCounts.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Map.fromEntries(sorted.take(5));
  }

  String _getDayLabel(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
