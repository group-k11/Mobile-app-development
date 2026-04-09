import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/product_card.dart';
import 'add_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Products',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withValues(alpha: 0.05),
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    productProvider.setSearchQuery(value);
                    setState(() {}); // Rebuild to show/hide clear icon
                  },
                  decoration: InputDecoration(
                    hintText: 'Search products, barcodes...',
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.primaryLight),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              productProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),

                // Category filter chips
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip(
                        'All',
                        productProvider.selectedCategory == null,
                        () => productProvider.setCategory(null),
                      ),
                      ...kProductCategories.map(
                        (category) => _buildFilterChip(
                          category,
                          productProvider.selectedCategory == category,
                          () => productProvider.setCategory(category),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Product count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${productProvider.products.length} products',
                  style: AppTextStyles.bodySecondary,
                ),
                if (productProvider.searchQuery.isNotEmpty ||
                    productProvider.selectedCategory != null)
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      productProvider.clearFilters();
                    },
                    child: const Text('Clear Filters'),
                  ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: productProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : productProvider.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              productProvider.searchQuery.isNotEmpty
                                  ? 'No products match your search'
                                  : 'No products added yet',
                              style: AppTextStyles.bodySecondary,
                            ),
                            if (authProvider.isOwner) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _navigateToAddProduct(context),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Product'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => productProvider.loadProducts(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: productProvider.products.length,
                          itemBuilder: (context, index) {
                            final product = productProvider.products[index];
                            return ProductCard(
                              product: product,
                              showActions: authProvider.isOwner,
                              onEdit: authProvider.isOwner
                                  ? () => _navigateToEditProduct(
                                      context, product)
                                  : null,
                              onDelete: authProvider.isOwner
                                  ? () => _confirmDelete(
                                      context, product.productId, product.name)
                                  : null,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: authProvider.isOwner
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToAddProduct(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryLight,
        backgroundColor: Colors.white,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  void _navigateToAddProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
  }

  void _navigateToEditProduct(BuildContext context, product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductScreen(product: product),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, String productId, String productName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$productName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<ProductProvider>(context, listen: false)
                  .deleteProduct(productId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
