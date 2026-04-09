import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import '../services/product_cache_service.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.sellingPrice * quantity;
}

class ProductProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final ProductCacheService _cacheService = ProductCacheService();
  final Uuid _uuid = const Uuid();

  List<ProductModel> _products = [];
  final List<CartItem> _cart = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedCategory;

  List<ProductModel> get products => _filteredProducts;
  List<ProductModel> get allProducts => _products;
  List<CartItem> get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  ProductCacheService get cacheService => _cacheService;

  // ─── Initialize Cache ─────────────────────────────────
  Future<void> initializeCache() async {
    await _cacheService.initialize();
  }

  // ─── Filtered Products ────────────────────────────────
  List<ProductModel> get _filteredProducts {
    var result = List<ProductModel>.from(_products);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where((p) =>
              p.name.toLowerCase().contains(query) ||
              p.barcode.contains(query) ||
              p.category.toLowerCase().contains(query) ||
              p.brand.toLowerCase().contains(query))
          .toList();
    }

    if (_selectedCategory != null) {
      result = result.where((p) => p.category == _selectedCategory).toList();
    }

    return result;
  }

  // ─── Alert Lists ─────────────────────────────────────
  List<ProductModel> get lowStockProducts =>
      _products.where((p) => p.isLowStock).toList();

  List<ProductModel> get outOfStockProducts =>
      _products.where((p) => p.isOutOfStock).toList();

  List<ProductModel> get expiringSoonProducts =>
      _products.where((p) => p.isExpiringSoon).toList();

  List<ProductModel> get deadStockProducts =>
      _products.where((p) => p.isDeadStock).toList();

  int get totalProducts => _products.length;

  // ─── Cart Helpers ─────────────────────────────────────
  double get cartTotal =>
      _cart.fold(0, (sum, item) => sum + item.total);

  int get cartItemCount =>
      _cart.fold(0, (sum, item) => sum + item.quantity);

  bool get isCartEmpty => _cart.isEmpty;

  // ─── Load Products ───────────────────────────────────
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await _firestoreService.getAllProducts();
      _error = null;
      // Cache all products for offline barcode lookups
      await _cacheService.cacheProducts(_products);
    } catch (e) {
      _error = 'Failed to load products';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Listen to Products Stream ───────────────────────
  void listenToProducts() {
    _firestoreService.getProductsStream().listen((products) {
      _products = products;
      // Update cache whenever Firestore updates
      _cacheService.cacheProducts(products);
      notifyListeners();
    });
  }

  // ─── Add Product ─────────────────────────────────────
  Future<String> addProduct(ProductModel product) async {
    try {
      final newProduct = product.copyWith(
        productId: product.productId.isEmpty ? _uuid.v4() : product.productId,
      );

      // Check barcode uniqueness
      final result =
          await _firestoreService.addProductWithBarcodeCheck(newProduct);

      if (result == 'added') {
        // Cache the new product
        await _cacheService.cacheProduct(newProduct);
        await loadProducts();
      }
      return result;
    } catch (e) {
      _error = 'Failed to add product';
      notifyListeners();
      return 'error';
    }
  }

  // ─── Update Product ──────────────────────────────────
  Future<bool> updateProduct(ProductModel product) async {
    try {
      await _firestoreService.updateProduct(product);
      // Update cache
      await _cacheService.cacheProduct(product);
      await loadProducts();
      return true;
    } catch (e) {
      _error = 'Failed to update product';
      notifyListeners();
      return false;
    }
  }

  // ─── Update Stock ────────────────────────────────────
  Future<bool> updateStock(String productId, int quantityDelta) async {
    try {
      await _firestoreService.updateStockDelta(productId, quantityDelta);
      await loadProducts();
      return true;
    } catch (e) {
      _error = 'Failed to update stock';
      notifyListeners();
      return false;
    }
  }

  // ─── Delete Product ──────────────────────────────────
  Future<bool> deleteProduct(String productId) async {
    try {
      // Find product to remove from cache
      final product = _products.where((p) => p.productId == productId).toList();
      if (product.isNotEmpty && product.first.barcode.isNotEmpty) {
        await _cacheService.remove(product.first.barcode);
      }
      await _firestoreService.deleteProduct(productId);
      await loadProducts();
      return true;
    } catch (e) {
      _error = 'Failed to delete product';
      notifyListeners();
      return false;
    }
  }

  // ─── Search / Filter ─────────────────────────────────
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    notifyListeners();
  }

  // ─── Find by Barcode (3-tier lookup) ─────────────────
  /// 1. In-memory list (fastest)
  /// 2. Hive cache (O(1) local)
  /// 3. Firestore query (network)
  Future<ProductModel?> findByBarcode(String barcode) async {
    // 1. Check in-memory list
    final local = _products.where((p) => p.barcode == barcode).toList();
    if (local.isNotEmpty) return local.first;

    // 2. Check Hive cache
    final cached = _cacheService.getByBarcode(barcode);
    if (cached != null) return cached;

    // 3. Check Firestore
    final remote = await _firestoreService.getProductByBarcode(barcode);
    if (remote != null) {
      // Cache for future lookups
      await _cacheService.cacheProduct(remote);
    }
    return remote;
  }

  // ─── Cart Operations ─────────────────────────────────
  /// Add product to cart. Returns false if stock would be exceeded.
  bool addToCart(ProductModel product) {
    final existingIndex =
        _cart.indexWhere((item) => item.product.productId == product.productId);

    final currentInCart =
        existingIndex != -1 ? _cart[existingIndex].quantity : 0;

    // Check stock availability
    if (currentInCart >= product.quantity) {
      return false; // Not enough stock
    }

    if (existingIndex != -1) {
      _cart[existingIndex].quantity++;
    } else {
      _cart.add(CartItem(product: product));
    }
    notifyListeners();
    return true;
  }

  void updateCartItemQuantity(int index, int quantity) {
    if (index >= 0 && index < _cart.length) {
      if (quantity <= 0) {
        _cart.removeAt(index);
      } else {
        // Cap at available stock
        final available = _cart[index].product.quantity;
        _cart[index].quantity = quantity > available ? available : quantity;
      }
      notifyListeners();
    }
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < _cart.length) {
      _cart.removeAt(index);
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }
}
