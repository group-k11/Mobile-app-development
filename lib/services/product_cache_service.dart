import 'package:hive/hive.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';

/// Hive-based local product cache for O(1) barcode lookups.
/// Uses barcode as the key for instant retrieval.
class ProductCacheService {
  Box? _box;

  /// Initialize the Hive box. Call once on app startup.
  Future<void> initialize() async {
    _box = await Hive.openBox(kProductCacheBox);
  }

  Box get _cache {
    if (_box == null || !_box!.isOpen) {
      throw StateError('ProductCacheService not initialized. Call initialize() first.');
    }
    return _box!;
  }

  /// O(1) lookup by barcode from local Hive cache.
  ProductModel? getByBarcode(String barcode) {
    try {
      final data = _cache.get(barcode);
      if (data != null) {
        return ProductModel.fromHiveMap(Map<dynamic, dynamic>.from(data));
      }
    } catch (_) {}
    return null;
  }

  /// Cache a single product (keyed by barcode).
  Future<void> cacheProduct(ProductModel product) async {
    if (product.barcode.isEmpty) return;
    await _cache.put(product.barcode, product.toHiveMap());
  }

  /// Bulk cache products from Firestore stream.
  Future<void> cacheProducts(List<ProductModel> products) async {
    final entries = <String, Map<String, dynamic>>{};
    for (final p in products) {
      if (p.barcode.isNotEmpty) {
        entries[p.barcode] = p.toHiveMap();
      }
    }
    await _cache.putAll(entries);
  }

  /// Remove a product from cache.
  Future<void> remove(String barcode) async {
    await _cache.delete(barcode);
  }

  /// Clear entire cache.
  Future<void> clearCache() async {
    await _cache.clear();
  }

  /// Number of cached products.
  int get cachedCount => _cache.length;
}
