import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════
  //  PRODUCTS
  // ═══════════════════════════════════════════════════════

  // Stream all products
  Stream<List<ProductModel>> getProductsStream() {
    return _firestore
        .collection(kProductsCollection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data()))
            .toList());
  }

  // Get all products (one-time)
  Future<List<ProductModel>> getAllProducts() async {
    final snapshot = await _firestore
        .collection(kProductsCollection)
        .orderBy('name')
        .get();
    return snapshot.docs.map((doc) => ProductModel.fromMap(doc.data())).toList();
  }

  // Get product by barcode
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    final snapshot = await _firestore
        .collection(kProductsCollection)
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return ProductModel.fromMap(snapshot.docs.first.data());
    }
    return null;
  }

  // Get product by ID
  Future<ProductModel?> getProductById(String productId) async {
    final doc =
        await _firestore.collection(kProductsCollection).doc(productId).get();
    if (doc.exists && doc.data() != null) {
      return ProductModel.fromMap(doc.data()!);
    }
    return null;
  }

  /// Add product with barcode uniqueness check.
  /// Returns 'added' if new, 'duplicate' if barcode already exists.
  Future<String> addProductWithBarcodeCheck(ProductModel product) async {
    // Check if barcode already exists
    if (product.barcode.isNotEmpty) {
      final existing = await getProductByBarcode(product.barcode);
      if (existing != null) {
        return 'duplicate';
      }
    }
    await addProduct(product);
    return 'added';
  }

  // Add product
  Future<void> addProduct(ProductModel product) async {
    await _firestore
        .collection(kProductsCollection)
        .doc(product.productId)
        .set(product.toMap());
  }

  // Update product
  Future<void> updateProduct(ProductModel product) async {
    await _firestore
        .collection(kProductsCollection)
        .doc(product.productId)
        .update(product.toMap());
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    await _firestore.collection(kProductsCollection).doc(productId).delete();
  }

  // Update product quantity
  Future<void> updateProductQuantity(String productId, int newQuantity) async {
    await _firestore
        .collection(kProductsCollection)
        .doc(productId)
        .update({'quantity': newQuantity});
  }

  /// Update stock by delta (positive to add, negative to subtract).
  Future<void> updateStockDelta(String productId, int delta) async {
    await _firestore
        .collection(kProductsCollection)
        .doc(productId)
        .update({'quantity': FieldValue.increment(delta)});
  }

  // Update last sold timestamp
  Future<void> updateLastSold(String productId) async {
    await _firestore
        .collection(kProductsCollection)
        .doc(productId)
        .update({'last_sold_at': Timestamp.fromDate(DateTime.now())});
  }

  // Search products
  Future<List<ProductModel>> searchProducts(String query) async {
    final snapshot = await _firestore
        .collection(kProductsCollection)
        .orderBy('name')
        .get();

    final lowerQuery = query.toLowerCase();
    return snapshot.docs
        .map((doc) => ProductModel.fromMap(doc.data()))
        .where((product) =>
            product.name.toLowerCase().contains(lowerQuery) ||
            product.barcode.contains(lowerQuery) ||
            product.category.toLowerCase().contains(lowerQuery) ||
            product.brand.toLowerCase().contains(lowerQuery))
        .toList();
  }

  // Get low stock products
  Future<List<ProductModel>> getLowStockProducts() async {
    final products = await getAllProducts();
    return products.where((p) => p.isLowStock).toList();
  }

  // Get out of stock products
  Future<List<ProductModel>> getOutOfStockProducts() async {
    final products = await getAllProducts();
    return products.where((p) => p.isOutOfStock).toList();
  }

  // Get expiring soon products
  Future<List<ProductModel>> getExpiringSoonProducts() async {
    final products = await getAllProducts();
    return products.where((p) => p.isExpiringSoon).toList();
  }

  // Get dead stock products
  Future<List<ProductModel>> getDeadStockProducts() async {
    final products = await getAllProducts();
    return products.where((p) => p.isDeadStock).toList();
  }

  // ═══════════════════════════════════════════════════════
  //  SALES
  // ═══════════════════════════════════════════════════════

  // Create sale and reduce inventory
  Future<void> createSale(SaleModel sale) async {
    final batch = _firestore.batch();

    // Add sale document
    final saleRef = _firestore.collection(kSalesCollection).doc(sale.saleId);
    batch.set(saleRef, sale.toMap());

    // Reduce inventory for each item
    for (final item in sale.items) {
      final productRef =
          _firestore.collection(kProductsCollection).doc(item.productId);
      batch.update(productRef, {
        'quantity': FieldValue.increment(-item.quantity),
        'last_sold_at': Timestamp.fromDate(DateTime.now()),
      });
    }

    await batch.commit();
  }

  // Get sales stream
  Stream<List<SaleModel>> getSalesStream() {
    return _firestore
        .collection(kSalesCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SaleModel.fromMap(doc.data())).toList());
  }

  // Get sales for a date range
  Future<List<SaleModel>> getSalesByDateRange(
      DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection(kSalesCollection)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) => SaleModel.fromMap(doc.data())).toList();
  }

  // Get today's sales
  Future<List<SaleModel>> getTodaysSales() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getSalesByDateRange(startOfDay, endOfDay);
  }

  // Get this week's sales
  Future<List<SaleModel>> getWeekSales() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return getSalesByDateRange(start, now);
  }

  // ═══════════════════════════════════════════════════════
  //  USERS
  // ═══════════════════════════════════════════════════════

  // Get user
  Future<UserModel?> getUser(String userId) async {
    final doc =
        await _firestore.collection(kUsersCollection).doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Create user document
  Future<void> createUser(UserModel user) async {
    await _firestore
        .collection(kUsersCollection)
        .doc(user.userId)
        .set(user.toMap());
  }

  // Delete user document
  Future<void> deleteUser(String userId) async {
    await _firestore.collection(kUsersCollection).doc(userId).delete();
  }

  // Get all staff users
  Future<List<UserModel>> getAllStaff() async {
    final snapshot = await _firestore
        .collection(kUsersCollection)
        .where('role', isEqualTo: kRoleStaff)
        .get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  // Stream staff users for real-time updates
  Stream<List<UserModel>> getStaffStream() {
    return _firestore
        .collection(kUsersCollection)
        .where('role', isEqualTo: kRoleStaff)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }
}
